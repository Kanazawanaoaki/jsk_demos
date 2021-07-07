#!/usr/bin/env roseus

;; load pr2-interface.l
(load "package://pr2eus/pr2-interface.l")

;; init 
(pr2-init)

;; ros init
(ros::roseus "pr2_send_joints")
(ros::advertise "semantic_annotation_merge" std_msgs::header 1)


;; reset-manip-pose
(send *pr2* :reset-manip-pose)
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
(send *ri* :wait-interpolation)


;; init
(load "models/iemon-object.l")
(setq *iemon* (iemon))
(send *iemon* :locate #f(750 0 800) :world)
;; (send *iemon* :rotate (deg2rad 180) :z) 

(load "models/arrow-object.l")
(setq *axis* (arrow))
(send *axis* :move-to (send *iemon* :copy-worldcoords) :world)
(objects (list *pr2* *iemon* *axis*))

;; IKを解いてつかむ

(send *axis* :move-to (send *iemon* :worldcoords) :world)
(send *axis* :translate #f(-80 0 -40) :world)

(setq s-time 3)

(warn "please run (grasp) ~%")

(defun grasp ()
  (send *irtviewer* :draw-objects)

  (send *ri* :stop-grasp :larm)
  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis :t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (send *axis* :translate #f(120 0 0) :world)
  (send *irtviewer* :draw-objects)

  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis :t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (send *ri* :speak-jp "物体を握らせて下さい")
  (unix:sleep s-time)
  
  (send *ri* :start-grasp :larm)
  (send (send *pr2* :larm :end-coords :parent) :assoc *iemon*)

  (send *pr2* :larm :move-end-pos #f(0 0 100) :world
	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos #f(100 -100 -100) :world
	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (warn "please run (pose1) ~%")
  )


(defun publish-semantic-annotation-merge (annotation-str)
  (setq msg (instance std_msgs::header :init))
  (send msg :stamp (ros::time-now))
  (send msg :frame_id annotation-str)
  (ros::ros-info "msg [~A]" (send msg :frame_id))
  (ros::publish "semantic_annotation_merge" msg)
  )


(defun pose1 ()
  (send *axis* :newcoords (make-coords :pos #f(400 0 800) :rpy #f(-1.57 0 0)))
  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis t
	:debug-view t)
  (send *pr2* :head :look-at (send *iemon* :worldpos))
  (setq *pose1* (send *pr2* :angle-vector))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  (publish-semantic-annotation-merge (format nil "vision_0"))
  (unix:sleep 1)

  (warn "please run (pose2) ~%")
  )

(defun pose2 ()
  (send *axis* :rotate (deg2rad -90) :x)
  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis t
	:debug-view t)
  (send *pr2* :head :look-at (send *iemon* :worldpos))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  (publish-semantic-annotation-merge (format nil "vision_1"))
  (unix:sleep 1)
  )

(defun pose3 ()
  (send *axis* :rotate (deg2rad -90) :x)
  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis t
	:debug-view t)
  (send *pr2* :head :look-at (send *iemon* :worldpos))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  (publish-semantic-annotation-merge (format nil "vision_2"))
  (unix:sleep 1)
  )

(defun pose4 ()
  (send *axis* :rotate (deg2rad -90) :x)
  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis t
	:debug-view t)
  (send *pr2* :head :look-at (send *iemon* :worldpos))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  (publish-semantic-annotation-merge (format nil "vision_3"))
  (unix:sleep 1)
  )

(defun pose5 ()
  (send *axis* :newcoords (make-coords :pos #f(400 0 800) :rpy #f(-1.57 0 0)))
  (send *axis* :rotate (deg2rad 90) :z)
  (send *axis* :rotate (deg2rad 60) :y)
  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis t
	:debug-view t)
  (send *pr2* :head :look-at (send *iemon* :worldpos))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  (publish-semantic-annotation-merge (format nil "vision_4"))
  (unix:sleep 1)
  )

(defun pose6 ()
  (send *axis* :newcoords (make-coords :pos #f(400 0 800) :rpy #f(-1.57 0 0)))
  (send *axis* :rotate (deg2rad -90) :z)
  (send *axis* :rotate (deg2rad -60) :y)
  (send *pr2* :torso_lift_joint :joint-angle 100)
  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis t
	:debug-view t)
  (send *pr2* :head :look-at (send *iemon* :worldpos))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (publish-semantic-annotation-merge (format nil "vision_5"))
  (unix:sleep 1)
  )


(defun pose7 ()
  (send *pr2* :angle-vector *pose1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  (publish-semantic-annotation-merge (format nil "vision_end"))
  )

(defun auto ()
  (grasp)
  (pose1)
  (pose2)
  (pose3)
  (pose4)
  (pose5)
  (pose6)
  (pose7)
  )

