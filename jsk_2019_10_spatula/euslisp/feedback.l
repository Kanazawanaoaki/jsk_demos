#!/usr/bin/env roseus
;;;;
;;;; make scraping movement with right hand, move the bowl with the left Hand until the spatula touches the bowl. 
;;;;

(load "package://pr2eus/pr2-interface.l")
(ros::roseus "pr2_send_joints")

;;(ros::advertise "start_scraping" std_msgs::string 1)
(ros::advertise "start_scraping" std_msgs::bool 1)

(setq *ri* (instance pr2-interface :init))
(pr2-init t)

(defun move-left-arm (d)
  (print "move left arm!!")
  (send *l-tcp* :translate (float-vector 0 (* d 10) 0)) ;;old bowl  
  (send *pr2* :inverse-kinematics
	*l-tcp*
	:move-target *ltargetframe*
	:use-torso nil
	)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :larm-controller)
  (while (send *ri* :interpolatingp :larm-controller)
    (send *ri* :spin-once))
  )


;;define callback function
(defun string-cb (msg)
  (print (list 'cb (sys::thread-self) (send msg :data)))
  (if (= (send msg :data) 0)
      (print "everything perfect!");;no reaction, touching
      (move-left-arm (send msg :data)) ;;else
      )
  )
;;(ros::subscribe "chatter" std_msgs::string #'string-cb)
(ros::subscribe "feedback_touching" std_msgs::float64 #'string-cb)

;;start robot from reset position
(send *pr2* :reset-pose)
(if (boundp '*irtviewer*)    
    (send *irtviewer* :draw-objects))

(send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
(send *ri* :wait-interpolation)


;; move robot into initial position
(send *pr2* :rarm :shoulder-p :joint-angle -20)
(send *pr2* :larm :shoulder-p :joint-angle 50)
(send *pr2* :rarm :shoulder-r :joint-angle -130)
(send *pr2* :larm :shoulder-r :joint-angle 120)
(send *pr2* :larm :elbow-p :joint-angle -100)
(send *pr2* :rarm :elbow-p :joint-angle -70)
(send *pr2* :rarm :elbow-r :joint-angle 0)
(send *pr2* :rarm :wrist-p :joint-angle -40)
(send *pr2* :larm :wrist-r :joint-angle 30)

(if (boundp '*irtviewer*)    
    (send *irtviewer* :draw-objects))

(send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
(send *ri* :wait-interpolation)


;; hand the robot the spatula and bowl
(send *pr2* :stop-grasp)
(send *ri* :stop-grasp)
(send *ri* :wait-interpolation)
(unix:sleep 2)		     
;;some time to place the bowl and then close the left gripper
(send *pr2* :start-grasp :larm)
(send *ri* :start-grasp :larm :gain 0.05)
(send *ri* :wait-interpolation)
(unix:sleep 2)
;;some time to place the spatula, then close the right gripper
(send *pr2* :start-grasp :rarm)
(send *ri* :start-grasp :rarm :gain 0.05)
(send *ri* :wait-interpolation)

;;got these angle vectors from the real robot by moving it manually to the desired positions, they turned out to work better than the previously constructed
;;with: send *ri* :state :potentio-vector
(setq *av1* #f(49.9331 62.6833 33.1418 127.946 -117.444 -7.41574 -5.72958 51.833 -16.9966 -9.03369 -111.73 -116.714 -76.193 -57.7095 266.18 3.0727 -21.2682))
(setq *av2* #f(49.9331 62.3888 32.6716 129.774 -117.502 -7.41574 -5.72958 51.833 -29.1714 -9.19364 -117.398 -118.456 -81.5623 -50.4353 263.348 3.0727 -21.2682))
(setq *av3* #f(49.9331 62.6975 32.5311 129.278 -117.386 -7.41574 -5.72958 51.833 -29.0716 -9.25665 -86.0776 -118.804 -76.2328 -66.8658 270.291 3.0727 -21.2682))


(send *pr2* :angle-vector *av3*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 3000 :rarm-controller)
(send *ri* :wait-interpolation)


(setq *l-tcp* (send (send *pr2* :larm :end-coords) :copy-worldcoords))
(setq *ltargetframe* (send *pr2* :larm :end-coords))

(send *l-tcp* :translate (float-vector 10 -40 0)) ;;move down and front to make sure it is not touchign in the beginning
(send *pr2* :inverse-kinematics
      *l-tcp*
      :move-target *ltargetframe*
      :use-torso nil
      )
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :larm-controller)
(send *ri* :wait-interpolation)
(unix:sleep 2)


;;added this to make synchonization possible
(send *pr2* :angle-vector *av1* :rarm-controller) ;;added rarm-controller
(send *ri* :angle-vector (send *pr2* :angle-vector) 3000 :rarm-controller)
(send *ri* :wait-interpolation)


;;scrape the bottom of the bowl
(dotimes (i 3)
  ;;signalize to detect_toching that a new wiping sequence starts
  (setq msg (instance std_msgs::bool :init))
  (send msg :data t)
  (ros::ros-info "msg [~A]" (send msg :data))
  (ros::publish "start_scraping" msg)

  (send *ri* :angle-vector-sequence (list *av2* *av3* *av1*) (list 3000 3000 3000) :rarm-controller)
  (send *ri* :spin-once)

  (while (send *ri* :interpolatingp :rarm-controller)
    (send *ri* :spin-once)
    (ros::spin-once);;to see if chatter published
    (if (send *ri* :simulation-modep)
      (send *ri* :robot-interface-simulation-callback))
    )
  )

(setq msg (instance std_msgs::bool :init))
(send msg :data nil)
(ros::ros-info "msg [~A]" (send msg :data))
(ros::publish "start_scraping" msg)

