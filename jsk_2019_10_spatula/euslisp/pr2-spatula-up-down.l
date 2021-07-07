#!/usr/bin/env roseus
;;;;
;;;; make PR2 use a spatula to scrape through a bowl without feedback, this is only a simple experiment in order to gathe data for analysis of PR2 effort accuracy
;;;;

(load "package://pr2eus/pr2-interface.l")
(ros::roseus "pr2_send_joints")

(setq *ri* (instance pr2-interface :init))
(pr2-init t)

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
(unix:sleep 5)		     
;;some time to place the bowl and then close the left gripper
(send *pr2* :start-grasp :larm)
(send *ri* :start-grasp :larm :gain 0.05)
(send *ri* :wait-interpolation)
(unix:sleep 5)
;;some time to place the spatula, then close the right gripper
(send *pr2* :start-grasp :rarm)
(send *ri* :start-grasp :rarm :gain 0.05)
(send *ri* :wait-interpolation)

;;got these angle vectors from the real robot by moving it manually to the desired positions, they turned out to work better than the previously constructed
;;with: send *ri* :state :potentio-vector
(setq *av1* #f(49.9309 46.9174 16.1048 91.3424 -106.669 83.8063 -70.7673 -48.572 -29.0811 -20.2598 -34.2316 -83.3109 -53.8209 -103.838 173.943 2.7007 -21.2682))
(send *pr2* :angle-vector *av1*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
(send *ri* :wait-interpolation)


(setq *av2* #f(49.9304 31.56 19.2117 74.8322 -71.3499 90.3357 -75.0202 -39.7572 -11.3582 -3.91533 -84.2033 -67.7666 -87.6674 -86.0261 203.242 2.7667 -21.2682))

(send *pr2* :angle-vector *av2*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
(send *ri* :wait-interpolation)

;;pan was 29.8927
(setq *av3* #f(49.926 30 31.0479 71.0285 -61.6202 102.708 -67.3895 -25.8046 -8.97355 -20.1962 -118.629 -80.582 -75.7356 -66.5916 236.422 3.6607 -21.2682))

(setq *av4* #f(49.9259 30 31.0479 71.0285 -61.6202 102.708 -67.3895 -25.8046 10.6353 -13.5947 -134.0 -60.6995 -79.2157 -84.8993 238.836 3.8287 -21.2682))

;;lift was -9.41175
(setq *av5* #f(49.926 30 31.0479 71.0285 -61.6202 102.708 -67.3895 -25.8046 -1.21648 4 -124.326 -66.7463 -81.8739 -64.9937 235.702 3.6607 -21.2682))



(send *pr2* :angle-vector *av3*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
(send *ri* :wait-interpolation)

;;scrape the bottom of the bowl 40 times
(dotimes (i 10)
  (send *ri* :angle-vector-sequence (list *av4* *av5* *av3*))
  (send *ri* :wait-interpolation)  
  )



