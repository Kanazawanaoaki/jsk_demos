(defun init ()
  (if (not (boundp '*room*))
      (progn
        (load "../../model/my-room73b2-scene.l")
        (setq *room* (room73b2))
        ))
    
  (if (not (boundp '*kitchen*))
      (progn 
        (load "models/room73b2-kitchen-object.l")
        (setq *kitchen* (room73b2-kitchen))
        (send *kitchen* :transform (make-coords :pos (float-vector 305.0 2175.0 20.0) :rot #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))))
        ))

  (if (not (boundp '*pr2*))
      (progn
        (load "package://pr2eus/pr2-interface.l")
        (pr2-init)
        ))

  ;; set まな板
  (load "../../model/cutting-board.l")
  (setq *cutting-board* (cutting-board))
  (send *cutting-board* :transform (make-coords :pos (float-vector 500.0 2000.0 840.0) :rot #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))))

  ;; set objects
  (load "../../model/peeler.l")
  (load "../../model/potato-peeler.l")
  (load "../../model/knife-new-attention.l")
  (load "models/arrow-object.l")
  (setq *arrow* (arrow))

  ;; set spots
  (setq *cook-spot* (send *room73b2* :spot "cook-spot"))
  (setq *sink-spot* (make-coords :pos #f(1055 2600 0) :rpy #f(3.14 0 0))) 
  (setq *kitchen-spot* (send *room73b2* :spot "kitchen-spot"))
  (setq *stove-spot* (make-coords :pos #f(1400 1600 0) :rpy #f(3.14 0 0)))


  ;; キッチンの場所まで移動 (初期値)
  (defun move-to-kitchen-irt ()
    (send *pr2* :move-to *kitchen-spot* :world)
    )
  (move-to-kitchen-irt)

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  ;; def global values
  (setq s-time 3)
  
  (setq adj 0)

  ;; set potato
  (load "../../model/potato-new-type.l")

  (setq width 90)
  (setq length 60)
  (setq height 60)
  )

(defun set-pose ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (on-stove) ~%")
  )

(init)

(defun set-pose-2 ()
  (send *pr2* :reset-pose)
  (send *pr2* :head_tilt_joint :joint-angle 40)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  )

(defun set-pose-3 ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *pr2* :larm :angle-vector #f(117.007 48.3805 113.439 -103.326 38.7107 -5.72958 14.4628))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  )


(set-pose-3)


;; point-pose-extractor
(require :detection-interface "package://jsk_perception/euslisp/detection_interface.l")
(defparameter *detection-topic* "/ObjectDetection")


;; add for sense
(setq *x-thre* -15)

(ros::roseus "stove_rec_test" :anonymous t)
(setq *topic-name* "/left_endeffector/wrench")
(ros::load-ros-manifest "geometry_msgs")
(setq *cb-flag* nil)
(defun wrench-x-cb (msg)
  (when msg
    (let ((x nil))
      (setq x (send msg :wrench :force :x))
      (if (< x *x-thre*)
          (progn 
            (setq *cb-flag* t)
            (format t "OK!! x: ~A ~%" x)
            )
        (format t "x: ~A ~%" x))
      )))


(setq local-cds (make-coords :pos (float-vector 527.349 424.972 760.996) :rpy (float-vector 3.129 0.857 -0.026)))
(setq *s-panel* (make-cube 150 230 10))
(send *s-panel* :move-to *pr2* :world)
(send *s-panel* :transform (send local-cds :copy-worldcoords))
(send *s-panel* :newcoords (make-coords :pos (send (send *s-panel* :copy-worldcoords) :worldpos)))
(send *s-panel* :rotate (deg2rad 90) :y)
(send *s-panel* :translate #f(75 115 0))

(objects (list *pr2* *cutting-board* *s-panel*))

(defun recognition ()
  (set-pose-3)
  (setq s-pos (float-vector 0 0 0))
  (dotimes (i 10)
    (setq local-cds (check-detection :type "microwave" :speak-name "denshirenji" :timeout 10 :speak nil))
    (send *s-panel* :move-to *pr2* :world)
    (send *s-panel* :transform (send local-cds :copy-worldcoords))
    (setq s-pos (v+ s-pos (send *s-panel* :pos)))
    )
  ;; (send *s-panel* :newcoords (make-coords :pos (send (send *s-panel* :copy-worldcoords) :worldpos)))
  (send *s-panel* :newcoords (make-coords :pos (scale 0.1 s-pos)))
  (send *s-panel* :rotate (deg2rad 90) :y)
  (send *s-panel* :translate #f(75 115 0))
  )


(defun push-stove-button ()
  (send *ri* :start-grasp :larm :wait t)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 15)
    (send *pr2* :larm :move-end-pos #f(-10 0 0) :world)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    )
  (send *ri* :angle-vector-sequence avs tms)
  
  (ros::unsubscribe "/left_endeffector/wrench")
  (setq *topic-name* "/left_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/left_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-x-cb)
  
  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
            (ros::spin-once)
            (if *cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      (warn "cancel!!! ~%")
      )
    )
  
  (ros::unsubscribe "/left_endeffector/wrench")

  )

(defun on-stove ()
  (send *ri* :start-grasp :larm :wait t)

  ;; スイッチの位置
  (setq s-pos (send (send *s-panel* :copy-worldcoords) :worldpos))
  (send *arrow* :newcoords (make-coords :pos (float-vector (elt s-pos 0) (+ (elt s-pos 1) 47) 750) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :translate #f(130 0 0) :world)

  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (push-stove-button)

  (setq s-pos (send (send *s-panel* :copy-worldcoords) :worldpos))
  (send *arrow* :newcoords (make-coords :pos (float-vector (elt s-pos 0) (+ (elt s-pos 1) 47) 750) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :translate #f(130 0 0) :world)

  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "hoge hoge ~%")
  )

(defun off-stove ()
  (send *ri* :start-grasp :larm :wait t)

  ;; スイッチの位置
  (setq s-pos (send (send *s-panel* :copy-worldcoords) :worldpos))
  (send *arrow* :newcoords (make-coords :pos (float-vector (elt s-pos 0) (+ (elt s-pos 1) 37) 750) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :translate #f(120 0 0) :world)

  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (push-stove-button)

  (setq s-pos (send (send *s-panel* :copy-worldcoords) :worldpos))
  (send *arrow* :newcoords (make-coords :pos (float-vector (elt s-pos 0) (+ (elt s-pos 1) 37) 750) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :translate #f(130 0 0) :world)

  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  )

(defun push-knob ()
  (send *ri* :start-grasp :larm :wait t)

  (setq s-pos (send (send *s-panel* :copy-worldcoords) :worldpos))
  (send *arrow* :newcoords (make-coords :pos (float-vector (elt s-pos 0) (+ (elt s-pos 1) 30) 715) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :translate #f(130 0 0) :world)

  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (push-stove-button)
  
  (setq s-pos (send (send *s-panel* :copy-worldcoords) :worldpos))
  (send *arrow* :newcoords (make-coords :pos (float-vector (elt s-pos 0) (+ (elt s-pos 1) 30) 715) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :translate #f(130 0 0) :world)

  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  )

(defun grasp-knob ()
  (send *ri* :stop-grasp :larm :wait t)
  
  (setq s-pos (send (send *s-panel* :copy-worldcoords) :worldpos))
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector (elt s-pos 0) (+ (elt s-pos 1) 30) 715) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :newcoords (make-coords :pos (float-vector 680 (+ (elt s-pos 1) 30) 715) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :rotate (deg2rad 90) :x)
  (send *arrow* :translate #f(130 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 13)
    (send *pr2* :larm :move-end-pos #f(-10 0 0) :world)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    )

  (send *ri* :angle-vector-sequence avs tms)

  (ros::unsubscribe "/left_endeffector/wrench")
  (setq *topic-name* "/left_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/left_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-x-cb)
  
  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
            (ros::spin-once)
            (if *cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      (warn "cancel!!! ~%")
      )
    )
  
  (ros::unsubscribe "/left_endeffector/wrench")

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(10 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  
  (send *ri* :start-grasp :larm :wait t :gain 100)
  )

(defun rotate-knob (&rest args &key (deg 30) &allow-other-keys)
  ;; rotate
  (setq avs (list))
  (setq tms (list))
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :rotate (deg2rad deg) :x)
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view t)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 600)))
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)

  )

(defun release-knob ()
  (send *ri* :stop-grasp :larm :wait t)
  
  (send *arrow* :translate #f(30 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (setq s-pos (send (send *s-panel* :copy-worldcoords) :worldpos))
  (send *arrow* :newcoords (make-coords :pos (float-vector 680 (+ (elt s-pos 1) 30) 715) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :rotate (deg2rad 90) :x)
  (send *arrow* :translate #f(130 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  )

(defun push-boil-button ()
  (send *ri* :start-grasp :larm :wait t)

  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 706.961 1714.929 711.89) :rpy (float-vector -3.036 0.054 1.588)))
  ;; つまみの位置
  (send *arrow* :newcoords (make-coords :pos (float-vector 677 1690 665) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :translate #f(130 0 0) :world)

  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq avs (list))
  (setq tms (list))

  (send *pr2* :larm :move-end-pos #f(-100 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 1000)))

  (send *pr2* :larm :move-end-pos #f(-30 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 1000)))
  
  (send *pr2* :larm :move-end-pos #f(30 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 1000)))

  (send *pr2* :larm :move-end-pos #f(100 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 1000)))

  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)  
  )


(defun now-test ()
  (set-pose-3)
  (on-stove)
  (push-knob)
  (grasp-knob)
  (rotate-knob :deg 30)
  (release-knob)
  (push-knob)
  (off-stove)
  )
