#!/usr/bin/env roseus
;;;
;;; euslisp version of ros_tutorials/rospy_tutorials/001_talker_listener
;;;

(ros::load-ros-manifest "roseus")

;;;
(ros::roseus "smach_state_msg-publisher")
(ros::advertise "smach_state_msg" std_msgs::string 1)
(ros::rate 100)


;; (while (ros::ok)
;;   (setq msg (instance std_msgs::string :init))
;;   (send msg :data (format nil "hello world ~a" (send (ros::time-now) :sec-nsec)))
;;   (ros::ros-info "msg [~A]" (send msg :data))
;;   (ros::publish "chatter" msg)
;;   (ros::sleep)
;;   )
;; (ros::roseus "shutdown")
;; (exit)

(warn "please run (pub-msg args) ~%")

(defun pub-msg (data)
  (setq msg (instance std_msgs::string :init))
  (send msg :data data)
  (ros::ros-info "msg [~A]" (send msg :data))
  (ros::publish "smach_state_msg" msg)
  )

(defun pub-open ()
  (setq msg (instance std_msgs::string :init))
  (send msg :data 'open)
  (ros::ros-info "msg [~A]" (send msg :data))
  (ros::publish "smach_state_msg" msg)
  )
