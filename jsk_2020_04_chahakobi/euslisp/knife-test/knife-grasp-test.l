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
(load "models/knife-object.l")
(setq *knife* (knife))
(send *knife* :locate #f(700 0 705) :world)
(send *knife* :rotate (deg2rad -90) :x)

(load "models/room73b2-karimoku-table-object.l")
(setq *table* (room73b2-karimoku-table))
(send *table* :locate #f(1020 0 0) :world)

(load "models/arrow-object.l")
(setq *axis* (arrow))
(send *axis* :move-to (send *knife* :copy-worldcoords) :world)
(objects (list *pr2* *knife* *axis* *table*))

;; IKを解いてつかむ

(defun grasp ()
  (send *irtviewer* :draw-objects)
  (send *axis* :move-to (send (car (send *knife* :handle)) :copy-worldcoords) :world)
  (send *axis* :translate #f(-100 0 150) :world)
  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis :t
	:debug-view t)

  (send *axis* :move-to (send (car (send *knife* :handle)) :copy-worldcoords) :world)
  (send *axis* :rotate (deg2rad 90) :z)
  (send *axis* :rotate (deg2rad 90) :x)
  (send *axis* :translate #f(0 0 50) :world)

  (send *ri* :stop-grasp :larm)
  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis :t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (send *axis* :translate #f(0 0 -50) :world)
  (send *irtviewer* :draw-objects)

  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis :t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  
  (send *ri* :start-grasp :larm :wait t)
  (send (send *pr2* :larm :end-coords :parent) :assoc *knife*)

  (send *pr2* :larm :move-end-pos #f(0 0 100) :world
	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  )


;; (defun publish-semantic-annotation-merge (annotation-str)
;;   (setq msg (instance std_msgs::header :init))
;;   (send msg :stamp (ros::time-now))
;;   (send msg :frame_id annotation-str)
;;   (ros::ros-info "msg [~A]" (send msg :frame_id))
;;   (ros::publish "semantic_annotation_merge" msg)
;;   )


;; (defun pose1 ()
;;   (send *axis* :newcoords (make-coords :pos #f(400 0 800) :rpy #f(-1.57 0 0)))
;;   (send *pr2* :larm :inverse-kinematics
;; 	*axis*
;; 	:rotation-axis t
;; 	:debug-view t)
;;   (send *pr2* :head :look-at (send *knife* :worldpos))
;;   (setq *pose1* (send *pr2* :angle-vector))
;;   (send *ri* :angle-vector (send *pr2* :angle-vector))
;;   (send *ri* :wait-interpolation)
;;   (publish-semantic-annotation-merge (format nil "vision_0"))
;;   (unix:sleep 1)
;;   )

;; (defun pose2 ()
;;   (send *axis* :rotate (deg2rad -90) :x)
;;   (send *pr2* :larm :inverse-kinematics
;; 	*axis*
;; 	:rotation-axis t
;; 	:debug-view t)
;;   (send *pr2* :head :look-at (send *knife* :worldpos))
;;   (send *ri* :angle-vector (send *pr2* :angle-vector))
;;   (send *ri* :wait-interpolation)
;;   (publish-semantic-annotation-merge (format nil "vision_1"))
;;   (unix:sleep 1)
;;   )

;; (defun pose3 ()
;;   (send *axis* :rotate (deg2rad -90) :x)
;;   (send *pr2* :larm :inverse-kinematics
;; 	*axis*
;; 	:rotation-axis t
;; 	:debug-view t)
;;   (send *pr2* :head :look-at (send *knife* :worldpos))
;;   (send *ri* :angle-vector (send *pr2* :angle-vector))
;;   (send *ri* :wait-interpolation)
;;   (publish-semantic-annotation-merge (format nil "vision_2"))
;;   (unix:sleep 1)
;;   )

;; (defun pose4 ()
;;   (send *axis* :rotate (deg2rad -90) :x)
;;   (send *pr2* :larm :inverse-kinematics
;; 	*axis*
;; 	:rotation-axis t
;; 	:debug-view t)
;;   (send *pr2* :head :look-at (send *knife* :worldpos))
;;   (send *ri* :angle-vector (send *pr2* :angle-vector))
;;   (send *ri* :wait-interpolation)
;;   (publish-semantic-annotation-merge (format nil "vision_3"))
;;   (unix:sleep 1)
;;   )

;; (defun pose5 ()
;;   (send *axis* :newcoords (make-coords :pos #f(400 0 800) :rpy #f(-1.57 0 0)))
;;   (send *axis* :rotate (deg2rad 90) :z)
;;   (send *pr2* :larm :inverse-kinematics
;; 	*axis*
;; 	:rotation-axis t
;; 	:debug-view t)
;;   (send *axis* :rotate (deg2rad 45) :y)
;;   (send *pr2* :larm :inverse-kinematics
;; 	*axis*
;; 	:rotation-axis t
;; 	:debug-view t)
;;   (send *pr2* :head :look-at (send *knife* :worldpos))
;;   (send *ri* :angle-vector (send *pr2* :angle-vector))
;;   (send *ri* :wait-interpolation)
;;   (publish-semantic-annotation-merge (format nil "vision_4"))
;;   (unix:sleep 1)
;;   )

;; (defun pose6 ()
;;   (send *axis* :newcoords (make-coords :pos #f(400 0 800) :rpy #f(-1.57 0 0)))
;;   (send *axis* :rotate (deg2rad -90) :z)
;;   (send *axis* :rotate (deg2rad -60) :y)
;;   (send *pr2* :torso_lift_joint :joint-angle 100)
;;   (send *pr2* :larm :inverse-kinematics
;; 	*axis*
;; 	:rotation-axis t
;; 	:debug-view t)
;;   (send *pr2* :head :look-at (send *knife* :worldpos))
;;   (send *ri* :angle-vector (send *pr2* :angle-vector))
;;   (send *ri* :wait-interpolation)

;;   (publish-semantic-annotation-merge (format nil "vision_5"))
;;   (unix:sleep 1)
;;   )


;; (defun pose7 ()
;;   (send *pr2* :angle-vector *pose1*)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector))
;;   (send *ri* :wait-interpolation)
;;   (publish-semantic-annotation-merge (format nil "vision_end"))
;;   )

;; (defun make-pose1 ()
;;   (pose1)
;;   (pose2)
;;   (pose3)
;;   (pose4)
;;   (pose5)
;;   (pose6)
;;   )

;; (defun make-pose2 ()
;;   (pose7)
;;   )
