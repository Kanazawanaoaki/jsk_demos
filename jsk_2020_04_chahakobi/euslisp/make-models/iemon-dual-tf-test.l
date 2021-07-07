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
(send *iemon* :locate #f(750 0 765) :world)
;; (send *iemon* :rotate (deg2rad 180) :z) 

(load "models/room73b2-karimoku-table-object.l")
(setq *table* (room73b2-karimoku-table))
(send *table* :locate #f(1020 0 0) :world)


(load "models/arrow-object.l")
(setq *axis* (arrow))
(send *axis* :move-to (send *iemon* :copy-worldcoords) :world)

(setq *axis2* (arrow))

(objects (list *pr2* *iemon* *axis* *table* *axis2*))

;; IKを解いてつかむ
(send *axis* :move-to (send *iemon* :worldcoords) :world)
(send *axis* :translate #f(-80 0 30) :world)

(defun grasp ()
  (send *axis* :move-to (send *iemon* :worldcoords) :world)
  (send *axis* :translate #f(-80 0 40) :world)

  (send *irtviewer* :draw-objects)

  ;; 手前にIKを解く
  (send *ri* :stop-grasp :larm)
  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis :t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  ;; 少し奥側にIKを解いて掴む
  (send *axis* :translate #f(100 0 0) :world)
  (send *irtviewer* :draw-objects)

  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis :t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  
  (send *ri* :start-grasp :larm :wait t)
  (unix:sleep 2)
  (send (send *pr2* :larm :end-coords :parent) :assoc *iemon*)

  (send *pr2* :larm :move-end-pos #f(0 0 200) :world
	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (format t ";; please run (pose1) pr (l-pose)~%")
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
  
  (format t ";; please run (pose2)~%")
  )

(defun pose2 ()
  (send *axis* :newcoords (make-coords :pos #f(400 0 800) :rpy #f(-1.57 0 0)))
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

  (format t ";; please run (pose3)~%")
  )

(defun pose3 ()
  (send *axis* :newcoords (make-coords :pos #f(400 0 800) :rpy #f(-1.57 0 -1.571)))
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

  (format t ";; please run (pose4)~%")
  )

(defun pose4 ()
  (send *axis* :newcoords (make-coords :pos #f(400 0 800) :rpy #f(-1.57 0 -3.142)))
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

  (format t ";; please run (pose5)~%")
  )

(defun pose5 ()
  (send *axis* :newcoords (make-coords :pos #f(400 0 800) :rpy #f(-1.57 0 1.571)))
  (send *axis* :rotate (deg2rad 90) :y)
  (send *axis* :rotate (deg2rad 90) :x)
  (send *axis* :rotate (deg2rad -30) :y)
  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis t
	:debug-view t)
  (send *pr2* :head :look-at (send *iemon* :worldpos))
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  (publish-semantic-annotation-merge (format nil "vision_4"))
  (unix:sleep 1)

  (format t ";; please run (pose6)~%")
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

  (format t ";; please run (pose7)~%")
  )

(defun pose7 ()
  (send *pr2* :angle-vector *pose1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  (publish-semantic-annotation-merge (format nil "vision_end"))

  (format t ";; please run (motikae)~%")
  )


;; (defun motikae ()
;;   (send *axis* :newcoords (make-coords :pos #f(400 0 800) :rpy #f(0 0 -1.57)))
;;   (send *pr2* :larm :inverse-kinematics
;; 	*axis*
;; 	:rotation-axis t
;; 	:debug-view t)

;;   (send *axis2* :move-to (send *iemon* :worldcoords) :world)
;;   (send *axis2* :locate #f(0 0 -55))
;;   (send *axis2* :rotate (deg2rad -90) :y)

;;   ;; 少し手前にIKを解く
;;   (send *axis2* :translate #f(0 -40 0) :world)
;;   (send *ri* :stop-grasp :rarm)
;;   (send *pr2* :rarm :inverse-kinematics
;; 	*axis2*
;; 	:rotation-axis t
;; 	:debug-view t)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector))
;;   (send *ri* :wait-interpolation)

;;   ;; Ikを解いて掴む
;;   (send *axis2* :translate #f(0 40 0) :world)
;;   (send *pr2* :rarm :inverse-kinematics
;; 	*axis2*
;; 	:rotation-axis t
;; 	:debug-view t)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector))
;;   (send *ri* :wait-interpolation)

;;   ;; 持ち替え
;;   (send *ri* :start-grasp :rarm :wait t)
;;   (send *ri* :stop-grasp :larm)
;;   (send (send *pr2* :larm :end-coords :parent) :dissoc *iemon*)
;;   (send (send *pr2* :rarm :end-coords :parent) :assoc *iemon*) 

;;   (send *pr2* :reset-manip-pose)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector))
;;   (send *ri* :wait-interpolation)

;;   (format t ";; please run (r-pose1)~%")
;;   )

(defun motikae ()
  (send *axis* :newcoords (make-coords :pos #f(400 0 800) :rpy #f(0 0 -1.57)))
  (send *pr2* :larm :inverse-kinematics
	*axis*
	:rotation-axis t
	:debug-view t)

  (send *axis2* :move-to (send *iemon* :worldcoords) :world)
  (send *axis2* :locate #f(0 0 -55))
  (send *axis2* :rotate (deg2rad -90) :y)

  ;; 少し手前にIKを解く
  (send *axis2* :translate #f(0 -40 0) :world)
  (send *ri* :stop-grasp :rarm)
  (send *pr2* :rarm :inverse-kinematics
	*axis2*
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  ;; Ikを解いて掴む
  (send *axis2* :translate #f(0 40 0) :world)
  (send *pr2* :rarm :inverse-kinematics
	*axis2*
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  ;; 持ち替え
  (send *ri* :start-grasp :rarm :wait t)
  (send *ri* :stop-grasp :larm)
  (send (send *pr2* :larm :end-coords :parent) :dissoc *iemon*)
  (send (send *pr2* :rarm :end-coords :parent) :assoc *iemon*)
  (unix:sleep 2)

  (publish-semantic-annotation-merge (format nil "vision_motikae"))
  
  (format t ";; please run (r-set-pose)~%")
  )

(defun r-set-pose ()
  ;; 少しずらす
  (send *axis2* :translate #f(0 -50 0) :world)
  (send *pr2* :rarm :inverse-kinematics
	*axis2*
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  
  (send *pr2* :reset-manip-pose)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  (format t ";; please run (r-pose1) or (r-pose)~%")
  )
  

(defun r-pose1 ()
  (send *axis2* :newcoords (make-coords :pos #f(500 0 950) :rpy #f(0 -0.524 0)))
  (send *pr2* :rarm :inverse-kinematics
	*axis2*
	:rotation-axis t
	:debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (publish-semantic-annotation-merge (format nil "vision_0"))

  (format t ";; please run (r-pose2)~%")
  )


(defun r-pose2 ()
  (send *pr2* :r_wrist_roll_joint :joint-angle (+ (send *pr2* :r_wrist_roll_joint :joint-angle) 90)) 
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (publish-semantic-annotation-merge (format nil "vision_1"))

  (format t ";; please run (r-pose3)~%")
  )

(defun r-pose3 ()
  (send *pr2* :r_wrist_roll_joint :joint-angle (+ (send *pr2* :r_wrist_roll_joint :joint-angle) 90)) 
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (publish-semantic-annotation-merge (format nil "vision_2"))

  (format t ";; please run (r-pose4)~%")
  )

(defun r-pose4 ()
  (send *pr2* :r_wrist_roll_joint :joint-angle (+ (send *pr2* :r_wrist_roll_joint :joint-angle) 90)) 
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (publish-semantic-annotation-merge (format nil "vision_3"))

  (format t ";; please run (r-pose5)~%")
  )

(defun r-pose5 ()
  (send *axis2* :newcoords (make-coords :pos #f(500 0 950) :rpy #f(0 -0.524 0)))
  (send *pr2* :rarm :inverse-kinematics
	*axis2*
	:rotation-axis t
	:debug-view t)

  (send *axis2* :rotate (deg2rad -90) :y)
  (send *pr2* :rarm :inverse-kinematics
	*axis2*
	:rotation-axis t
	:debug-view t)


  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  (publish-semantic-annotation-merge (format nil "vision_4"))

  (format t ";; please run (r-pose6)~%")
  )

(defun r-pose6 ()
  (send *axis2* :newcoords (make-coords :pos #f(500 0 950) :rpy #f(0 -0.524 0)))
  (send *pr2* :rarm :inverse-kinematics
	*axis2*
	:rotation-axis t
	:debug-view t)
  
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)  
  (publish-semantic-annotation-merge (format nil "vision_end"))
  )
  

(defun l-pose ()
  (pose1)
  (pose2)
  (pose3)
  (pose4)
  (pose5)
  (pose6)

  (format t ";; please run (pose7)~%")
  )

(defun r-pose ()
  (r-pose1)
  (r-pose2)
  (r-pose3)
  (r-pose4)
  (r-pose5)

  (format t ";; please run (r-pose6)~%")
  )
  
