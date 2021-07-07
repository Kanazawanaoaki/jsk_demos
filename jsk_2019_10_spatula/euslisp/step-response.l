
#!/usr/bin/env roseus
;;;;
;;;; make scraping movement with right hand, move the bowl with the left Hand until the spatula touches the bowl. 
;;;;

(load "package://pr2eus/pr2-interface.l")
(ros::roseus "pr2_send_joints")

(ros::advertise "start_scraping" std_msgs::bool 1)

(setq *ri* (instance pr2-interface :init))
(pr2-init t)

;;start robot from reset position
;;(send *pr2* :reset-pose)
;;(if (boundp '*irtviewer*)    
;;    (send *irtviewer* :draw-objects))

;;(send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
;;(send *ri* :wait-interpolation)


(setq *av1* #f(270 56.1185 28.9347 130.252 -106.951 -4.19415 -27.7583 140 -16.9966 -9.03369 -111.73 -116.714 -76.193 -57.7095 266.18 3.0727 -21.2682))
(setq *av2* #f(270  56.1185 28.9347 130.252 -106.951 -4.19415 -27.7583 140 -29.1714 -9.19364 -117.398 -118.456 -81.5623 -50.4353 263.348 3.0727 -21.2682))
(setq *av3* #f(270  56.1185 28.9347 130.252 -106.951 -4.19415 -27.7583 140 -29.0716 -9.25665 -86.0776 -118.804 -76.2328 -66.8658 270.291 3.0727 -21.2682))


(defun step-response (waiting-time exp-time angle-vector)
  
  (send *pr2* :angle-vector angle-vector)
  (if (boundp '*irtviewer*)    
    (send *irtviewer* :draw-objects))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000 :rarm-controller)
  (send *ri* :wait-interpolation)
  
  ;;(speak-en "Place the bottle!")
  (unix:sleep waiting-time)
  
  ;;publish that the experiment starts
  (setq msg (instance std_msgs::bool :init))
  (send msg :data t)
  (ros::ros-info "msg [~A]" (send msg :data))
  (ros::publish "start_scraping" msg)

  (send *pr2* :angle-vector *av2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 10000 :rarm-controller)
  (send *ri* :wait-interpolation)

  ;;(speak-en "Cut!")
    
  ;;start experiment
  (unix:sleep exp-time)

  ;;publish that the scraping stopped
  (setq msg (instance std_msgs::bool :init))
  (send msg :data nil)
  (ros::ros-info "msg [~A]" (send msg :data))
  (ros::publish "start_scraping" msg)

  ;;(speak-en "Done with the experiment!")
  )




(step-response 10 5 *av1*)
