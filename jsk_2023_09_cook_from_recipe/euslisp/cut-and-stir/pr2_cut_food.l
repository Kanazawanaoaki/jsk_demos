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
                (setq found-obj t)
                (setq *width* width)
                (setq *length* length)
                (setq *height* height)
                (setq *obj-coord* obj-coord)
                ))
          (print (list 'found? found-obj obj-pos)))
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
   )
  (format t "change deva class to ~A detection ~%" object-name)
  t)


(defun calc-offset (rec-coords grasp-coords)
  (setq offset-coords (send (send rec-coords :copy-worldcoords) :transformation (send grasp-coords :copy-worldcoords)))
  offset-coords)

(defun grasp-rec-object (&key (object-name "knife"))
  (cond
   ((string= object-name "knife")
    (setq object-offset (make-coords :pos #f(-105.089 -11.948 -2.399) :rpy #f(-0.09 0.071 0.061)))
    (setq wait-rav #f(-37.5677 40.413 -17.207 -105.732 -150.297 -58.7309 178.964))
    (setq pre-set-val #f(-100 0 100))
    )
   ((string= object-name "peeler")
    ;; (setq object-offset (make-coords :pos #f(-53.198 -7.425 -12.732) :rpy #f(-0.109 0.026 -0.005)))
    (setq object-offset (make-coords :pos #f(-53.198 -4.425 -15.732) :rpy #f(-0.109 0.026 -0.005)))
    (setq wait-rav #f(-37.5677 40.413 -17.207 -105.732 -150.297 -58.7309 178.964))
    (setq pre-set-val #f(-100 0 100))
    )
   )

  ;; set object rec
  (change-deva-param :object-name object-name) ;; このへんTODO flagとか カレーの時のを参考に考える
  (unix:sleep 3)

  ;; object rec
  (setq msg nil)
  (setq msg (one-shot-subscribe "/detic_segmentor/output/boxes" jsk_recognition_msgs::BoundingBoxArray :timeout 5000))

  ;; grasp
  (when msg
    (object-pose-cb msg)
    (send *obj-coord* :draw-on :flush t)
    (setq *grasp-coords* (send (send *obj-coord* :copy-worldcoords) :transform object-offset))
    (format t "grasp object in ~A ~%" *grasp-coords*)

    (send *pr2* :rarm :angle-vector wait-rav)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)

    (send *ri* :stop-grasp :rarm :wait t)

    (setq set-coords (send *grasp-coords* :copy-worldcoords))
    ;; (send set-coords :translate pre-set-val :world)
    (send set-coords :translate pre-set-val :local)
    (send *pr2* :rarm :inverse-kinematics
          (send set-coords :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)

    ;; (send set-coords :translate (scale -1 pre-set-val) :world)
    (send set-coords :translate (scale -1 pre-set-val) :local)
    (send *pr2* :rarm :inverse-kinematics
          (send set-coords :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
    (send *ri* :wait-interpolation)

    ;; (do-until-key
    ;;  (print "wait for key pressed")
    ;;  (unix:usleep 100000)
    ;;  )
    (send *ri* :start-grasp :rarm :wait t)

    (send set-coords :translate pre-set-val :local)
    (send *pr2* :rarm :inverse-kinematics
          (send set-coords :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)

    (send *pr2* :rarm :angle-vector wait-rav)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)
    )

  ;; rec fail
  )

(defun cut-wait-pose ()
  (setq cut-wait-rav #f(-37.5677 40.413 -17.207 -105.732 -150.297 -58.7309 178.964))
  (setq cut-wait-lav #f(41.0448 2.03593 63.3981 -67.6587 27.9651 -69.6477 -117.945))
  (send *pr2* :head :neck-y :joint-angle 0.0)
  (send *pr2* :head :neck-p :joint-angle 50.0)
  (send *pr2* :torso_lift_joint :joint-angle 300)
  (send *pr2* :rarm :angle-vector cut-wait-rav)
  (send *pr2* :larm :angle-vector cut-wait-lav)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )
