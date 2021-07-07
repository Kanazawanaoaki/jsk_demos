#!/usr/bin/env roseus
;;;;
;;;; make scraping movement with right hand, move the bowl with the left Hand until the spatula touches the bowl. 
;;;;
(ros::load-ros-package "jsk_2019_10_spatula")
(load "package://pr2eus/pr2-interface.l")
(ros::roseus "pr2_send_joints")
;;(ros::advertise "start_scraping" std_msgs::bool 1)
(ros::advertise "action_r_arm" std_msgs::string 1)
(setq *ri* (instance pr2-interface :init))
(pr2-init t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;define global variables;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;send *ri* :state :potentio-vector
;;(objects *r-tcp*)
;;define how many bowl-positions there should be
(setq *n-bowl-position* 5)
(setq oldtype -1)

(setq *av-reset-pose-high* #f(324.834 59.9994 74.0014 69.9995 -119.999 20.0009 -30.0145 180.014 -60.0002 74.0039 -69.9992 -119.999 -20.0041 -30.0008 180.001 3.0667 74.01))
(setq *av-base* #f(324.807 40.8419 14.9609 135.498 -100.854 -34.67 -39.7441 158.407 -33.4418 -10.5944 -86.243 -121.259 -73.9459 -64.4677 278.291 2.2447 74.2702))

(setq *av1* #f(324.807 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -16.9966 -9.03369 -111.73 -116.714 -76.193 -57.7095 266.18 3.0727 72))
(setq *av2* #f(324.807  49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -29.1714 -9.19364 -117.398 -118.456 -81.5623 -50.4353 263.348 3.0727 72))
(setq *av3* #f(324.807  49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -29.0716 -9.25665 -86.0776 -118.804 -76.2328 -66.8658 270.291 3.0727 72))

(setq *av-r-approach* #f(324.807 56.1185 28.9347 130.252 -106.951 -4.19415 -27.7583 140.0 -32.5695 -12.6491 -76.4196 -115.819 -67.3766 -74.5905 266.454 3.0727 72))
(setq *av-newbowl* #f(324.807 56.1185 28.9347 130.252 -106.951 -4.19415 -27.7583 145.49 -44.3293 -11.7819 -87.1801 -121.541 -68.7655 -64.4132 266.2 3.3307 72))

;;define angle-vectors for vision
(setq *av-snapshot* #f(324.807 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -15.2124 -9.77758 -83.654 -81.938 -58.164 -102.254 344.738 3.0727 72.0))
(setq *look-front* #f(324.807 48.1046 24.0788 125.944 -102.011 -13.0963 -30.5362 126.148 -12.2823 -12.0782 -84.1743 -68.6902 -58.5151 -108.045 336.0 3.0727 72.0))
(setq *look-back* #f(324.807 51.737 30.1327 120.422 -101.764 4.18285 -28.8173 149.013 -15.7055 -13.3653 -80.7665 -83.8848 -54.1232 -103.834 348.24 3.0727 72.0))
(setq *look-right* #f(324.807 45.4864 16.3124 126.845 -108.835 -5.52084 -15.5745 129.482 -14.2446 -9.58389 -84.0429 -77.551 -59.1313 -103.819 341.559 3.0727 72.0))
(setq *look-left* #f(324.807 51.1648 45.4815 116.822 -85.7364 -9.41469 -61.5682 142.069 -18.4818 -17.5874 -75.8746 -87.1968 -48.6971 -106.389 352.394 3.0727 72.0))


;;;;;;;;;;;;;;;;;;;;;;;;
;;function definitions;;
;;;;;;;;;;;;;;;;;;;;;;;;

(defun move-left-arm (d)
  ;;(send *l-tcp* :translate (float-vector 0 0 (* -1 (* d 10)))) ;;new bowl
  (send *l-tcp* :translate (float-vector (* d 10) 0 0)) ;;new bowl
  (send *pr2* :larm :inverse-kinematics *l-tcp*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :larm-controller)
  (while (send *ri* :interpolatingp :larm-controller)
    (send *ri* :spin-once))
  )

;;define callback function
(defun string-cb (msg)
  (print (list 'cb (sys::thread-self) (send msg :data)))
  (if (= (send msg :data) 0)
      (print "everything perfect!");;no reaction, touching
      (move-left-arm (send msg :data))
      )
  )

;;define callback function
(defun schedule-scraping (msg)
  (print "schedule scraping now")
  (setq *label* (send msg :data))
  (setq i 0)
  (dolist (dirty *label*)
    (print dirty)
    (when dirty
      (print "scrape, it is dirty!")
      (clean i)
      )
    (setq i (+ i 1))
    )
  )

(defun clean (i)
  (print "clean")
  ;;slight offset of 0.3 on the position as inverse-linematics fail for i=0 -> position=0
  ;;(setq position (+ (* 1.0 (mod i *n-bowl-position*)) 0.3))
  (setq position (* 1.0 (mod i *n-bowl-position*)))
  (if (= position 0)
      (setq position 0.3)
      )
  (setq step-size (/ 360 (* 4  *n-bowl-position*)))
  (setq omega (* (* (/ (- 90 (+ (* position  step-size) (/ step-size 2))) 360) 2) pi))
  (if (< i *n-bowl-position*)
      (setq type 0)
      (if (< i (* 2 *n-bowl-position*)) ;;elseif
	  (setq type 1)
	  (if (< i (* 3 *n-bowl-position*)) ;;elseif
	      (setq type 2)
	      (setq type 3) ;;else
	      )
	  )
      )
  (unless (= oldtype type)
     (send *pr2* :angle-vector *av-base*)	  
     (send *ri* :angle-vector (send *pr2* :angle-vector) 500 :rarm-controller)	  
     (send *ri* :wait-interpolation)	  	
     )
  (position-left-arm omega)
  (scrape-wall 1000 type position)
  (setq oldtype type)
  )

(defun position-left-arm (omega)
  (print "position left arm")
  (setq r 97.5)
  (send *l-tcp* :translate (float-vector r 0 0)) ;;move KS into middle of bowl
  (send *l-tcp* :translate (float-vector (- 0 (* r (cos omega))) (- 0 (* r (sin omega))) 0) ) 
  (send *l-tcp* :rotate omega :z)
  (send *pr2* :larm :inverse-kinematics *l-tcp*)
  (if (boundp '*irtviewer*)
      (send *irtviewer* :draw-objects))
  (unless (arm-collision-check)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :larm-controller)
    (send *ri* :wait-interpolation)
    )
  ;;move KS back into original Position
  (send *l-tcp* :rotate (- omega) :z) ;;rotate back
  (send *l-tcp* :translate (float-vector (+ 0 (* r (cos omega))) (+ 0 (* r (sin omega))) 0) )
  (send *l-tcp* :translate (float-vector (- 0 r) 0 0)) ;;move KS into middle
  )

;;collision check function
(defun arm-collision-check ()
    (send *pr2* :self-collision-check :pairs
          (append
           (mapcar
            #'(lambda (l) (cons l (car (send *pr2* :larm :links))))
            (all-child-links (send *pr2* :larm-elbow-p :parent-link)))
           (mapcar
            #'(lambda (l) (cons l (car (send *pr2* :rarm :links))))
            (all-child-links (send *pr2* :rarm-elbow-p :parent-link))))
          ))

;;reaction to feedback_touching, the left arm adjusts the bowl in order to make the spatula touch it
(defun move-left-arm (msg)
  (print "move left arm!!")
  (setq d (send msg :data))
  ;;(send *l-tcp* :translate (float-vector 0 0 (* -1 (* d 10)))) ;;new bowl
  ;;for scraping the wall
  (print "moving")
  (print d)
  (send *l-tcp* :translate (float-vector (* d 10) 0 0)) ;;new bowl
  (send *pr2* :larm :inverse-kinematics *l-tcp*)
  (unless (arm-collision-check)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 500 :larm-controller)
    )
  (while (send *ri* :interpolatingp :larm-controller)
    (send *ri* :spin-once))
  )


;;scraping movement of the right arm to scrape the wall of the bowl
(defun scrape-wall (speed type bowl-position)
  ;;decide where to scrape
  ;;scrape the side of handle
  (when (= type 3)
    (setq *av1-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -31.7304 18.8068 -77.3953 -120.967 -93.5516 -70.375 265.871 0.006701 72.0))
    ;;(setq *av1-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -27.8823 24.7971 -67.263 -121.533 -93.4203 -63.5745 265.59 0.006701 72.0))
    ;;(setq *av2-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -15.2191 9.85133 -94.9152 -114.105 -101.092 -67.2035 280.509 0.006701 72))
    (setq *av2-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -23.0904 12.2131 -93.6752 -117.796 -100.776 -70.1569 275.7 0.006701 72.0))
    (setq *av4-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -27.7253 2.64068 -84.0543 -120.025 -86.5879 -74.2459 273.116 0.006701 72))
    (setq *av3-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -31.3168 2.62658 -102.552 -120.701 -94.8818 -58.5094 270.153 0.006701 72))
    )
  ;;scrape the opposite of handle
  (when (= type 1)
    (setq *av4-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -5.2312 -8.16999 -94.3449 -111.498 -81.3893 -105.243 106.913 0.006701 72))
    ;;(setq *av1-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -11.9428 -8.01119 -95.1722 -116.346 -83.26 -104.16 104.923 0.006701 72))
    (setq *av1-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -25.6936 -3.30056 -90.0068 -121.542 -90.1433 -92.7314 97.9966 0.006701 72.0))
    (setq *av2-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -15.4138 1.14411 -111.984 -118.289 -99.6087 -93.6034 105.892 0.006701 72))
    (setq *av3-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -10.9854 3.42308 -98.4213 -116.226 -100.264 -84.5856 108.02 0.006701 72))
    )
  ;;scrape the back, close to robot
  (when (= type 2)
    (setq *av4-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -13.1883 -7.75134 -95.2939 -99.6978 -61.4526 -89.0247 170.473 0.006701 72));;535.473 0.006701 -2.298))
    (setq *av1-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -15.7707 -7.21133 -89.2349 -110.308 -60.662 -90.1109 176.284 0.006701 72))
    ;;(setq *av2-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -13.5759 5.14166 -100.562 -121.539 -77.5958 -80.4759 197.015 0.006701 72))
    (setq *av2-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -15.1281 8.06644 -102.077 -112.142 -79.5531 -82.7633 186.828 0.006701 72.0))
    ;;(setq *av3-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -15.2797 3.51531 -98.9968 -99.3912 -73.3151 -87.7253 173.869 0.006701 72))
    (setq *av3-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -14.8898 3.8411 -103.206 -110.282 -93.7681 -82.0022 187.578 0.006701 72.0))
    )
  ;;scrape the front, away from robot
  (when (= type 0)
    (setq *av1-wall* #f(324.807 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -17.5146 -8.98024 -89.3891 -119.057 -104.227 -87.4079 374.123 0.006701 72))
    ;;(setq *av2-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -18.3871 9.03037 -95.5761 -113.695 -122.878 -87.4583 367.803 0.006701 72))
    ;;(setq *av2-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -18.2571 6.30386 -94.2089 -114.321 -119.853 -87.8347 368.184 0.006701 72.0))
    (setq *av2-wall* #f(324.807 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -16.2524 -1.61327 -102.752 -121.339 -132.039 -86.4849 381.158 0.006701 72.0))
    (setq *av4-wall* #f(324.807 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -14.741 -0.964581 -84.7095 -117.467 -81.8724 -96.6787 368.785 0.006701 72));;195.043 0.006701 -2.298))
    (setq *av3-wall* #f(324.807 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -18.3619 10.089 -92.1263 -113.945 -100.031 -88.7665 367.505 0.006701 72))
    )

  (setq msg (instance std_msgs::string :init))
  (send msg :data (format nil "av1wall_~a_~a" type bowl-position))
  (ros::ros-info "msg [~A]" (send msg :data))
  (ros::publish "action_r_arm" msg)

  ;;start with home pos
  (unless (= oldtype type)
    (send *pr2* :angle-vector *av4-wall*)
    (unless (arm-collision-check)
      (send *ri* :angle-vector (send *pr2* :angle-vector) speed :rarm-controller)
      (send *ri* :wait-interpolation) 
      )
    )
  
  (send *pr2* :angle-vector *av1-wall*)
  (unless (arm-collision-check)
    (send *ri* :angle-vector (send *pr2* :angle-vector) speed :rarm-controller)
    (send *ri* :wait-interpolation)
    )
  ;;publish that the scraping starts
  (setq msg (instance std_msgs::string :init))
  (send msg :data (format nil "av2wall_~a_~a" type bowl-position))
  (ros::ros-info "msg [~A]" (send msg :data))
  (ros::publish "action_r_arm" msg)
  
  (send *pr2* :angle-vector *av2-wall*)
  (unless (arm-collision-check)
    (send *ri* :angle-vector (send *pr2* :angle-vector) speed :rarm-controller)
    (send *ri* :wait-interpolation)
    )
  ;;publish that the scraping stopped
  (setq msg (instance std_msgs::string :init))
  (send msg :data (format nil "av3wall_~a_~a" type bowl-position))
  (ros::ros-info "msg [~A]" (send msg :data))
  (ros::publish "action_r_arm" msg)

  (send *pr2* :angle-vector *av3-wall*)
  (unless (arm-collision-check)
    (send *ri* :angle-vector (send *pr2* :angle-vector) speed :rarm-controller)
    (send *ri* :wait-interpolation)
    )
  (setq msg (instance std_msgs::string :init))
  (send msg :data (format nil "av4wall_~a_~a" type bowl-position))
  (ros::ros-info "msg [~A]" (send msg :data))
  (ros::publish "action_r_arm" msg)
  
  (send *pr2* :angle-vector *av4-wall*)
  (unless (arm-collision-check)
    (send *ri* :angle-vector (send *pr2* :angle-vector) speed :rarm-controller)
    (send *ri* :wait-interpolation)
    )
  (setq msg (instance std_msgs::string :init))
  (send msg :data (format nil "end_~a_~a" type bowl-position))
  (ros::ros-info "msg [~A]" (send msg :data))
  (ros::publish "action_r_arm" msg)
  )

;;;;;;;;;;;;;;;;
;;subcriptions;;
;;;;;;;;;;;;;;;;

(ros::subscribe "pcl_nodelet/dirt_label" jsk_2019_10_spatula::BoolArray #'schedule-scraping)
(ros::subscribe "feedback_touching" std_msgs::float64 #'string-cb)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;fixed movement in beginning;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(send *pr2* :angle-vector  *av-reset-pose-high*)
;;start robot from reset position
;;(send *pr2* :reset-pose)
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
(send *pr2* :head :neck-p :joint-angle 72)

(if (boundp '*irtviewer*)    
    (send *irtviewer* :draw-objects))
(send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
(send *ri* :wait-interpolation)

;; hand the robot the spatula
(send *pr2* :stop-grasp)
(send *ri* :stop-grasp)
(send *ri* :wait-interpolation)
(unix:sleep 5)
(send *pr2* :start-grasp :rarm)
(send *ri* :start-grasp :rarm :gain 0.05)
(send *ri* :wait-interpolation)

;;start position
(send *pr2* :angle-vector *av-newbowl*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :larm-controller)
(send *ri* :wait-interpolation)

;;hand the robot the bowl
(unix:sleep 2)
(send *pr2* :start-grasp :larm)
(send *ri* :start-grasp :larm :gain 0.05)
(send *ri* :wait-interpolation)

;;one vector inbetween the start to avoid hitting the bowl with the spatula
(send *pr2* :angle-vector *av-r-approach*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 1500 :rarm-controller)
(send *ri* :wait-interpolation)

(send *pr2* :angle-vector *av3*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 700 :larm-controller)
(send *ri* :wait-interpolation)

(setq *l-tcp* (send (send *pr2* :larm :end-coords) :copy-worldcoords))
(setq *ltargetframe* (send *pr2* :larm :end-coords))





#|
;;move the bowl to gather dense pointcloud
(setq *joint-angle-time* (list 1000 1000 1000 1000 1000)) 
(setq *joint-angle-list* (list *look-front* *look-right* *look-back* *look-left* *av-snapshot*))
(ros::service-call "passthrough_points/request" (instance std_srvs::EmptyRequest :init))
(send *ri* :angle-vector-sequence *joint-angle-list* *joint-angle-time*)
(send *ri* :wait-interpolation)
|#

#|
once the result is published, the scraping can start planned with the labels
(while t
  (ros::spin-once);;to see if labels where published
  )
|#


#|
;;scrape the bowl hardcoded
(print "schedule hardcoded scraping now")
(setq *label* (list t t t t t t t t t t nil nil nil nil nil nil nil nil nil nil))
(setq i 0)
(dolist (dirty *label*)
  (print dirty)
  (when dirty
    (print "scrape!")
    (clean i)
    )
  (setq i (+ i 1))
  )
|#

#|
;;clean the whole bowl
(dolist (i (list 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19))
  (clean i))
|#




#|
(dolist (i (list 0 1 2 3 4))
  (setq position (+ (* 1.0 (mod i *n-bowl-position*)) 0.3))
  (setq step-size (/ 360 (* 4  *n-bowl-position*)))
  (setq omega (* (* (/ (- 90 (+ (* position  step-size) (/ step-size 2))) 360) 2) pi))
  (position-left-arm omega)
  )
|#

