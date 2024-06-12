#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_tmp.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/wrench.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/move-to-adjust.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/pr2-cooking-actions.l") ;; TODO update
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/cooking-exec-pddl-utils.l")

;; ros init
(ros::roseus "pr2_cut_food" :anonymous t)
(ros::load-ros-manifest "jsk_recognition_msgs")
(setq *tfl* (instance ros::transform-listener :init))

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
    (ros::set-dynamic-reconfigure-param "/deva_node" "classes" :string "white cup;")
    )
   ((string= object-name "onion")
    (ros::set-dynamic-reconfigure-param "/deva_node" "classes" :string "brown onion;")
    )
   )
  (format t "change deva class to ~A detection ~%" object-name)
  t)


(defun calc-offset (rec-coords grasp-coords)
  (setq offset-coords (send (send rec-coords :copy-worldcoords) :transformation (send grasp-coords :copy-worldcoords)))
  offset-coords)

(defun calc-average-two-coords (first-coords second-coords)
  (let (ans-coords)
    (setq ans-coords (make-coords :pos (scale 0.5 (v+ (send first-coords :worldpos) (send second-coords :worldpos)))
                                  :rot (send first-coords :worldrot)))
    ans-coords))

(defun grasp-rec-object (&key (object-name "knife") (change-deva t) (multi-rec nil) (grasp-gain 0.01) (arm :rarm))
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
    ;; (setq object-offset (make-coords :pos #f(-98.527 0.551 -14.482) :rpy #f(-0.033 0.036 -0.057)))
    (setq object-offset (make-coords :pos #f(-98.527 0.551 30) :rpy #f(-0.033 0.036 -0.057)))
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
