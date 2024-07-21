#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_tmp.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/wrench.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/move-to-adjust.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/pr2-cooking-actions.l") ;; TODO update
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/cooking-exec-pddl-utils.l")

;; util object
(unless (boundp '*arrow*)
  (progn
    (load "models/arrow-object.l")
    (setq *arrow* (arrow))
    ))

;; ros init
(ros::roseus "pr2_cut_food" :anonymous t)
(ros::load-ros-manifest "jsk_recognition_msgs")
(setq *tfl* (instance ros::transform-listener :init))
(setq *tfb* (instance ros::transform-broadcaster :init)))

;; define cb
(defun object-pose-cb (msg)
  (setq *msg* msg)
  (setq *bbox* (car (send msg :boxes)))
  (setq frame-id (send (send msg :header) :frame_id))
  ;; (print 1)
  (when msg
    (when (send *msg* :boxes)
      (let ((cam-coords nil))
        (setq tm2 (send *tfl* :get-latest-common-time "base_footprint" frame-id))
        (setq *dim* (send *bbox* :dimensions))
        (setq width (* (send *dim* :x) 1000))
        (setq length (* (send *dim* :y) 1000))
        (setq height (* (send *dim* :z) 1000))
        (setq *pose* (send *bbox* :pose))
        (setq cam->obj-coords (ros::tf-pose->coords *pose*))
        (when (send *tfl* :wait-for-transform  "base_footprint" frame-id tm2 10)
          (setq cam-coords (send (send *pr2* :copy-worldcoords) :transform
                                 (send *tfl* :lookup-transform "base_footprint" frame-id tm2))))
        (when cam-coords
          (setq obj-coord (send cam-coords :transform cam->obj-coords))
          ;; (setq tmp (- (+ (elt (send obj-coord :pos) 2) (/ height 2)) (+ (elt (send *cutting-board* :worldpos) 2) 10)))
          ;; (send obj-coord :translate (float-vector 0 0 (- (/ height 2) (/ tmp 2))) :world)
          ;; (setq height tmp)

          (setq obj-pos (scale 0.001 (send obj-coord :worldpos)))
          (if (> width 0)
              (progn
                (setq *found-obj* t)
                (setq *width* width)
                (setq *length* length)
                (setq *height* height)
                (setq *obj-coord* obj-coord)
                ))
          (print (list 'found? *found-obj* obj-pos))
          (print (list 'obj-dims *width* *length* *height*))
          )
        obj-pos))))

;; global variables

;; defun util fuction
(defun calc-object-rel-coords (base-coords target-coords)
  (setq rel-coords (send (send (send base-coords :copy-worldcoords) :inverse-transformation) :transform (send target-coords :copy-worldcoords)))
  rel-coords)

(defun calc-coords-from-rel (base-coords rel-coords)
  (setq target-coords (send (send base-coords :copy-worldcoords) :transform (send rel-coords :copy-worldcoords)))
  target-coords)

(defun calc-diff-in-world (base-coords rel-coords)
  (setq ans-vec (v- (send base-coords :transform-vector (send rel-coords :worldpos)) (send base-coords :worldpos)))
  ans-vec)

(defun dissoc-object (object-instance)
  (if (not (eql (send object-instance :parent) nil))
      (send (send object-instance :parent) :dissoc object-instance))
  )

(defun calc-arm-diff (ideal-coords rec-coords)
  (setq current-target-coords (make-coords :pos (send rec-coords :worldpos) :rot (send ideal-coords :worldrot)))
  (setq ans (calc-object-rel-coords ideal-coords current-target-coords))
  ans)

(defun calib-check-rec (&key (arm :larm))
  (setq calib-check-topic "/yellow_calib_hsi_segmentation_decomposer/boxes")
  (ros::unsubscribe calib-check-topic)
  (setq ideal-ee-coords (send (send *pr2* arm :end-coords) :copy-worldcoords))
  (setq *calib-rec-flag* nil)
  (until *calib-rec-flag*
         (setq msg (one-shot-subscribe calib-check-topic jsk_recognition_msgs::BoundingBoxArray :timeout 5000))
         (setq *found-obj* nil)

         (when msg
           (object-pose-cb msg)
           (when *found-obj*
             ;; check obj-dim
             (setq current-dim (* *width* *height* *length*))
             (setq dim-thre (* 40 15 20))
             (format t "bbox size : ~A, thre is ~A ~%" current-dim dim-thre)
             (if (< current-dim dim-thre)
                 (progn
                   (setq *calib-rec-flag* t)
                   (setq current-arm-diff (calc-arm-diff ideal-ee-coords *obj-coord*))
                   (format t "current arm diff : ~A ~%" current-arm-diff) ;; armのend-effectorと認識したテープの座標の差分をend-effector座標系で
                   (setq ideal-tape-coords (send ideal-ee-coords :copy-worldcoords))
                   (if (equal arm :larm)
                       (send ideal-tape-coords :translate #f(-82 52 0))
                     (send ideal-tape-coords :translate #f(-82 -52 0))
                     )
                   (setq current-tape-diff (calc-arm-diff ideal-tape-coords *obj-coord*))
                   (format t "current diff with tape : ~A ~%" current-tape-diff) ;;本来のテープの場所と認識結果の差分をend-effector座標系で
                   (setq world-tape-diff-vec (calc-diff-in-world ideal-ee-coords current-tape-diff))
                   (format t "current diff with tape in world : ~A ~%" world-tape-diff-vec) ;;本来のテープの場所と認識結果の差分のベクトルを世界座標系で
                   )
               (progn
                 (format t "bbox size is too big!! ~%")
                 )
               )
             )
           )
         )
  (list current-arm-diff current-tape-diff world-tape-diff-vec))

(defun calib-check-pose-1 (&key (arm :larm)) ;; TODO
  (send *ri* :start-grasp arm :wait t)
  (send *pr2* :head-neck-p :joint-angle 60)
  (send *pr2* :head-neck-y :joint-angle 0)
  (if (equal arm :larm)
      (send *pr2* :larm :angle-vector #f(-13.9647 61.3593 -5.56342 -115.768 -168.821 -54.3911 266.145)) ;; reset-manip-pose -> IK (make-coords :pos #f(600 100 1000)  :rpy #f(0.0 0.0 1.571))
    (send *pr2* :rarm :angle-vector #f(12.2691 61.4493 2.75452 -115.799 167.905 -54.7026 -264.289)) ;; reset-manip-pose -> ik (make-coords :pos #f(600 -100 1000)  :rpy #f(0.0 0.0 -1.571))
    )
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun calib-check-pose-2 (&key (arm :larm)) ;; TODO
  (send *ri* :start-grasp arm :wait t)
  (send *pr2* :head-neck-p :joint-angle 60)
  (send *pr2* :head-neck-y :joint-angle 0)
  (if (equal arm :larm)
      (send *pr2* :larm :angle-vector #f(36.0882 9.29496 92.2287 -74.1248 4.67322 -51.5913 5.9309)) ;; reset-manip-pose -> IK (make-coords :pos #f(600 100 1000)  :rpy #f(-1.571 0.0 1.571))
    (send *pr2* :rarm :angle-vector #f(-35.8771 6.16606 -97.1665 -74.1662 2.82492 -51.5477 -10.9524)) ;; reset-manip-pose -> ik (make-coords :pos #f(600 -100 1000)  :rpy #f(1.571 0.0 -1.571))
    )
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun calib-check-pose-3 (&key (arm :larm))
  (send *ri* :start-grasp arm :wait t)
  (send *pr2* :head-neck-p :joint-angle 60)
  (send *pr2* :head-neck-y :joint-angle 0)
  (if (equal arm :larm)
      (send *pr2* :larm :angle-vector #f(51.4332 21.4607 106.115 -107.264 11.6515 -30.2623 15.9049));; reset-manip-pose -> ik (make-coords :pos #f(400 100 900)  :rpy #f(-1.571 0.0 1.571))
    (send *pr2* :rarm :angle-vector #f(-50.5118 18.0403 -109.39 -107.477 -1.66349 -29.7571 -24.8012));; reset-manip-pose -> ik (make-coords :pos #f(400 -100 900)  :rpy #f(1.571 0.0 -1.571))
    )
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun calib-check-pose-4 (&key (arm :larm))
  (send *ri* :start-grasp arm :wait t)
  (send *pr2* :head-neck-p :joint-angle 60)
  (send *pr2* :head-neck-y :joint-angle 0)
  (if (equal arm :larm)
      (send *pr2* :larm :angle-vector #f(44.2811 9.76779 95.1416 -95.6883 5.01758 -37.9739 6.63239)) ;; reset-manip-pose -> IK (make-coords :pos #f(500 100 1000)  :rpy #f(-1.571 0.0 1.571))
    (send *pr2* :rarm :angle-vector #f(-43.91 6.15597 -99.287 -95.7724 3.9935 -37.9496 -14.0189));; reset-manip-pose -> ik (make-coords :pos #f(500 -100 1000)  :rpy #f(1.571 0.0 -1.571))
    )
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


(defun calib-check-pose-5 (&key (arm :larm))
  (send *ri* :start-grasp arm :wait t)
  (send *pr2* :head-neck-p :joint-angle 30)
  (send *pr2* :head-neck-y :joint-angle 0)
  (if (equal arm :larm)
      (send *pr2* :larm :angle-vector #f(25.7549 -12.8187 48.118 -68.8454 38.724 -57.8261 35.7247)) ;; reset-manip-pose -> IK (make-coords :pos #f(550 50 1400)  :rpy #f(-1.571 0.0 0.0))
    (send *pr2* :rarm :angle-vector #f(-26.625 -14.0644 -50.6911 -68.6713 -35.2579 -56.6078 -37.6776));; reset-manip-pose -> ik (make-coords :pos #f(550 -50 1400)  :rpy #f(1.571 0.0 3.142))
    )
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


;; defun action codes
(defun change-hsi-param (&key (object-name "knife"))
  (cond
   ((string= object-name "knife")
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "h_limit_max" :int 127)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "h_limit_min" :int 58)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "s_limit_max" :int 15)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "s_limit_min" :int 0)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "i_limit_max" :int 52)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "i_limit_min" :int 16)
    )
   ((string= object-name "board")
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "h_limit_max" :int -93)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "h_limit_min" :int -128)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "s_limit_max" :int 28)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "s_limit_min" :int 0)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "i_limit_max" :int 255)
    (ros::set-dynamic-reconfigure-param "/hsi_filter" "i_limit_min" :int 209)
    )
   )
  (format t "change hsi param to ~A detection ~%" object-name)
  t)

(defun change-deva-param (&key (object-name "knife"))
  (cond
   ((string= object-name "knife")
    (ros::set-dynamic-reconfigure-param "/deva_node" "classes" :string "knife;")
    )
   ((string= object-name "board")
    (ros::set-dynamic-reconfigure-param "/deva_node" "classes" :string "white cutting board;")
    )
   ((string= object-name "peeler")
    (ros::set-dynamic-reconfigure-param "/deva_node" "classes" :string "orange peeler;")
    )
   ((string= object-name "white cup")
    ;; (ros::set-dynamic-reconfigure-param "/deva_node" "classes" :string "white cup;")
    (ros::set-dynamic-reconfigure-param "/deva_node" "classes" :string "white and black cup;")
    )
   ((string= object-name "onion")
    (ros::set-dynamic-reconfigure-param "/deva_node" "classes" :string "brown onion;")
    )
   )
  (format t "change deva class to ~A detection ~%" object-name)
  t)

(defun publish-cds-tf (cds)
  (send *tfb* :send-transform
        cds "/base_footprint" "/target_cds_frame")
  )

(defun calc-offset (rec-coords grasp-coords)
  (setq offset-coords (send (send rec-coords :copy-worldcoords) :transformation (send grasp-coords :copy-worldcoords)))
  offset-coords)

(defun calc-average-two-coords (first-coords second-coords)
  (let (ans-coords)
    (setq ans-coords (make-coords :pos (scale 0.5 (v+ (send first-coords :worldpos) (send second-coords :worldpos)))
                                  :rot (send first-coords :worldrot)))
    ans-coords))

(defun grasp-rec-object (&key (object-name "knife") (change-deva t) (multi-rec nil) (grasp-gain 0.01) (arm :rarm) (is-grasp t))
  (cond
   ((and (string= object-name "knife") (equal arm :rarm))
    (setq object-offset (make-coords :pos #f(-105.089 -11.948 -2.399) :rpy #f(-0.09 0.071 0.061))) ;; for only deva
    ;; (setq object-offset (make-coords :pos #f(-3.846 -15.18 -28.556) :rpy #f(-0.171 0.071 0.061))) ;; for with tabletop

    (setq wait-av #f(-37.5677 40.413 -17.207 -105.732 -150.297 -58.7309 178.964))
    (setq pre-set-val #f(-100 0 100))
    (setq fix-rot nil)
    )
   ((and (string= object-name "peeler") (equal arm :rarm))
    ;; (setq object-offset (make-coords :pos #f(-53.198 -7.425 -12.732) :rpy #f(-0.109 0.026 -0.005)))
    ;; (setq object-offset (make-coords :pos #f(-53.198 -7.425 -10.732) :rpy #f(-0.109 0.026 -0.005)))
    (setq object-offset (make-coords :pos #f(-43.198 -7.425 -10.732) :rpy #f(-0.109 0.026 -0.005)))
    (setq wait-av #f(-37.5677 40.413 -17.207 -105.732 -150.297 -58.7309 178.964))
    (setq pre-set-val #f(-100 0 100))
    (setq fix-rot nil)
    )
   ((and (string= object-name "white cup") (equal arm :rarm))
    (setq object-offset (make-coords :pos #f(-98.527 0.551 -14.482) :rpy #f(-0.033 0.036 -0.057)))
    (setq wait-av #f(-37.5677 40.413 -17.207 -105.732 -150.297 -58.7309 178.964))
    (setq pre-set-val #f(-100 0 100))
    (setq fix-rot nil)
    )
   ((and (string= object-name "white cup") (equal arm :larm))
    (setq object-offset (make-coords :pos #f(-98.527 0.551 -14.482) :rpy #f(-0.033 0.036 -0.057))) ;; save as rarm
    ;; (setq object-offset (make-coords :pos #f(-98.527 0.551 30) :rpy #f(-0.033 0.036 -0.057))) ;; fix for henna calib
    (setq object-offset (make-coords :pos #f(-79.009 2.446 -34.482) :rpy #f(-0.033 0.036 -0.057))) ;; fix for matomo calib
    (setq wait-av #f(18.6793 40.7013 -15.7633 -105.901 -210.673 -70.7818 203.18))
    (setq pre-set-val #f(-100 0 100))
    (setq fix-rot nil)
    )
   ((and (string= object-name "onion") (equal arm :larm))
    ;; (setq object-offset (make-coords :pos #f(-29.83 -6.456 -5.102) :rpy #f(-1.593 0.604 0.126)))
    ;; (setq object-offset (make-coords :pos #f(-15.83 -6.456 -15.102) :rpy #f(-1.593 0.604 0.126)))
    ;; (setq object-offset (make-coords :pos #f(-15.83 -6.456 -20.102) :rpy #f(-1.593 0.604 0.126))) ;; for only deva
    ;; (setq object-offset (make-coords :pos #f(-36.997 16.939 -13.16) :rpy #f(-0.061 0.617 -0.012))) ;; for with tabletop
    (setq object-offset (make-coords :pos #f(15.007 37.822 -13.16) :rpy #f(-1.58 0.617 -0.012))) ;; for with tabletop
    (setq wait-av #f(41.0448 2.03593 63.3981 -67.6587 27.9651 -69.6477 -117.945))
    (setq pre-set-val #f(-100 0 100))
    (setq fix-rot t)
    )
   (t
    (format t "this setting is not implemented yet! ~%")
    (return-from grasp-rec-object)
    )
   )

  ;; set object rec
  (if change-deva
      (progn
        (change-deva-param :object-name object-name)
        (unix:sleep 3)
        ))

  ;; object rec
  (setq msg nil)
  (setq *found-obj* nil)
  (setq rec-cnt 0)
  (setq rec-av-coords nil)
  (ros::unsubscribe "/deva_segmentor/output/boxes")
  (until *found-obj*
         (setq msg (one-shot-subscribe "/deva_segmentor/output/boxes" jsk_recognition_msgs::BoundingBoxArray :timeout 5000))

         ;; grasp
         (when msg
           (object-pose-cb msg)
           (when fix-rot
             (send *obj-coord* :newcoords (make-coords :pos (send (send *obj-coord* :copy-worldcoords) :worldpos)))
             )
           (send *obj-coord* :draw-on :flush t)
           (setq *grasp-coords* (send (send *obj-coord* :copy-worldcoords) :transform object-offset))
           (format t "grasp object in ~A ~%" *grasp-coords*)
           (when multi-rec
             (setq rec-cnt (+ rec-cnt 1))
             (setq *found-obj* nil)
             (if (null rec-av-coords)
                 (setq rec-av-coords (send *grasp-coords* :copy-worldcoords))
               (setq rec-av-coords (calc-average-two-coords rec-av-coords (send *grasp-coords* :copy-worldcoords)))
               )
             (when (>= rec-cnt 5)
               (setq *found-obj* t)
               (setq *grasp-coords* rec-av-coords)
               )
             )
           ))

  (publish-cds-tf *grasp-coords*)

  (when (null is-grasp)
    (format t "now is-grasp is nil, so return ~%")
    (return-from grasp-rec-object)
    )

  (send *pr2* arm :angle-vector wait-av)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp arm :wait t)

  (setq set-coords (send *grasp-coords* :copy-worldcoords))
  ;; (send set-coords :translate pre-set-val :world)
  (send set-coords :translate pre-set-val :local)
  (send *pr2* arm :inverse-kinematics
        (send set-coords :copy-worldcoords)
        :rotation-axis t
        :debug-view nil)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; (send set-coords :translate (scale -1 pre-set-val) :world)
  (send set-coords :translate (scale -1 pre-set-val) :local)
  (send *pr2* arm :inverse-kinematics
        (send set-coords :copy-worldcoords)
        :rotation-axis t
        :debug-view nil)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; (do-until-key
  ;;  (print "wait for key pressed")
  ;;  (unix:usleep 100000)
  ;;  )
  (send *ri* :start-grasp arm :gain grasp-gain :wait t)

  (send set-coords :translate pre-set-val :local)
  (send *pr2* arm :inverse-kinematics
        (send set-coords :copy-worldcoords)
        :rotation-axis t
        :debug-view nil)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *pr2* arm :angle-vector wait-av)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; rec fail
  )

(defun cut-wait-pose (&key (rarm t) (larm t))
  (setq cut-wait-rav #f(-37.5677 40.413 -17.207 -105.732 -150.297 -58.7309 178.964))
  (setq cut-wait-lav #f(41.0448 2.03593 63.3981 -67.6587 27.9651 -69.6477 -117.945))
  (send *pr2* :head :neck-y :joint-angle 0.0)
  (send *pr2* :head :neck-p :joint-angle 50.0)
  (send *pr2* :torso_lift_joint :joint-angle 300)
  (if rarm
      (send *pr2* :rarm :angle-vector cut-wait-rav))
  (if larm
      (send *pr2* :larm :angle-vector cut-wait-lav))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )


(defun test-make-model (&key (grasp-gain 0.01) (open-gripper t) (pose-init t) (service-call t) (step-deg 10) (arm :rarm))
  (when pose-init
    (if (equal arm :rarm)
        (cut-wait-pose :larm nil)
      (cut-wait-pose :rarm nil)
      )
    )

  (when open-gripper
    (send *ri* :stop-grasp arm :wait t)
    (speak-with-log "物体を持たせて，OKといってください")
    (ok-wait)
    )
  (send *ri* :start-grasp arm :gain grasp-gain :wait t)

  ;; do look around
  (if (equal arm :rarm)
      (progn
        (send *pr2* :rarm :angle-vector #f(-26.5948 24.2969 -39.6524 -63.3455 -55.3765 -69.4311 114.491))
        )
    (progn
      (send *pr2* :larm :angle-vector #f(32.0955 9.78618 68.5708 -93.7623 35.3695 -41.8402 -120.709))
      )
    )
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (if service-call
      (progn
        (unix:sleep 2)
          (print "save point cloud")
        (setq req (instance std_srvs::EmptyRequest :init))
        (setq res (ros::service-call "/service_save_pointcloud_to_pcd/save_pcd" req))
        )
    (progn
      (do-until-key
       (print "wait for key")
       (unix:usleep 100000)
       )
      ))

  (setq n-times (/ 360 step-deg))
  (setq target-coords (make-coords))
  (format t "step-deg: ~A, n-times: ~A ~%" step-deg n-times)
  (dotimes (i n-times)
    (format t "now ~A / ~A step ~%" (+ i 1) n-times)
    (send target-coords :newcoords (send (send *pr2* arm :end-coords) :copy-worldcoords))
    (send target-coords :rotate (deg2rad step-deg) :x)

    (send *pr2* arm :inverse-kinematics target-coords)
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation)

    (if service-call
        (progn
          (unix:sleep 2)
          (print "save point cloud")
          (setq req (instance std_srvs::EmptyRequest :init))
          (setq res (ros::service-call "/service_save_pointcloud_to_pcd/save_pcd" req))
          )
      (progn
        (do-until-key
         (print "wait for key")
         (unix:usleep 100000)
         )
        ))
    )

  (if (equal arm :rarm)
      (cut-wait-pose :larm nil)
    (cut-wait-pose :rarm nil)
    )
  )

(defun test-make-model-old (&key (grasp-gain 0.01) (open-gripper t));; this is old version
  (cut-wait-pose :larm nil)

  (if open-gripper
      (send *ri* :stop-grasp :rarm :wait t))
  (speak-with-log "物体を持たせて，OKといってください")
  (ok-wait)
  (send *ri* :start-grasp :rarm :gain grasp-gain :wait t)

  ;; do look around
  (send *pr2* :rarm :angle-vector #f(-26.5948 24.2969 -39.6524 -63.3455 -55.3765 -69.4311 114.491))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; TODO
  (do-until-key
   (print "wait for key")
   (unix:usleep 100000)
   )

  (send *pr2* :rarm :angle-vector #f(-25.5497 23.4245 -40.4242 -60.3925 -62.4925 -74.5565 201.178))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  ;; TODO
  (do-until-key
   (print "wait for key")
   (unix:usleep 100000)
   )

  (send *pr2* :rarm :angle-vector #f(-31.3545 25.7365 -47.3793 -66.6136 -46.5834 -83.6106 271.348))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  ;; TODO
  (do-until-key
   (print "wait for key")
   (unix:usleep 100000)
   )

  (send *pr2* :rarm :angle-vector #f(-32.9315 28.4556 -49.0974 -73.9793 -42.9177 -77.8097 6.70128))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  ;; TODO
  (do-until-key
   (print "wait for key")
   (unix:usleep 100000)
   )

  (cut-wait-pose :larm nil)
  )


(defun sink-lever-test ()
  (send *pr2* :rarm :angle-vector #f(-41.4059 32.4107 -50.5582 -112.849 -176.587 -63.8396 38.962))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :angle-vector #f(-24.8704 3.91558 -78.0752 -40.0538 -31.1184 -40.1947 20.8712))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *ri* :move-gripper :rarm 0.03 :effort (* 2000 0.03) :wait t)

  ;; set
  ;; off
  (setq now-coords (make-coords :pos #f(877.466 -25.883 1012.658) :rpy #f(0.794 0.215 -1.428)))
  (setq target-coords (set-offset-cds now-coords *sink-offset-cds*))
  (send *pr2* :rarm :inverse-kinematics
        (send target-coords :copy-worldcoords)
        :rotation-axis t
        :debug-view nil)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :rarm :wait t)

  ;; on
  ;; (setq now-coords (make-coords :pos #f(893.597 -17.28 1043.267) :rpy #f(0.539 0.466 -1.373)))
  (setq now-coords (make-coords :pos #f(895.364 -32.896 1044.233) :rpy #f(0.556 0.444 -1.265)))
  (setq target-coords (set-offset-cds now-coords *sink-offset-cds*))
  (send *pr2* :rarm :inverse-kinematics
        (send target-coords :copy-worldcoords)
        :rotation-axis t
        :debug-view nil)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (unix:sleep 1)

  ;; off
  (setq now-coords (make-coords :pos #f(884.415 -30.443 1012.658) :rpy #f(0.81 0.215 -1.428)))
  (setq target-coords (set-offset-cds now-coords *sink-offset-cds*))
  (send *pr2* :rarm :inverse-kinematics
        (send target-coords :copy-worldcoords)
        :rotation-axis t
        :debug-view nil)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *ri* :move-gripper :rarm 0.03 :effort (* 2000 0.03) :wait t)

  (send *pr2* :rarm :angle-vector #f(-24.8704 3.91558 -78.0752 -40.0538 -31.1184 -40.1947 20.8712))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :angle-vector #f(-41.4059 32.4107 -50.5582 -112.849 -176.587 -63.8396 38.962))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  )
