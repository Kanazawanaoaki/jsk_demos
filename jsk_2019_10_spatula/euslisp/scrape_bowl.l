#!/usr/bin/env roseus

(ros::load-ros-package "jsk_2019_10_spatula")
(load "package://pr2eus/pr2-interface.l")
(ros::roseus "pr2_send_joints")
(ros::advertise "scrape_left_jacobian" jsk_2019_10_spatula::Jacobian 1)
(ros::advertise "scrape_right_jacobian" jsk_2019_10_spatula::Jacobian 1)
(ros::advertise "semantic_annotation" std_msgs::string 1)
(setq *ri* (instance pr2-interface :init))
(pr2-init t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;define global variables;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

(load "angle-vectors.l")


;;;;;;;;;;;;;;;;;;;;;;;;
;;function definitions;;
;;;;;;;;;;;;;;;;;;;;;;;;

(defun publish-semantic-annotation (annotation-str)
  (setq msg (instance std_msgs::string :init))
  (send msg :data annotation-str)
  (ros::ros-info "msg [~A]" (send msg :data))
  (ros::publish "semantic_annotation" msg)
  )

(defun publish-jacobi (arm)
  ;;get the line components of the jacobi
  (setq selection #f(1 0 0 0 0 0))
  (setq jacobi-x (transform selection jacobi))
  (setq selection #f(0 1 0 0 0 0)) 
  (setq jacobi-y (transform selection jacobi))
  (setq selection #f(0 0 1 0 0 0))
  (setq jacobi-z (transform selection jacobi))
  (setq selection #f(0 0 0 1 0 0))
  (setq jacobi-roll (transform selection jacobi))
  (setq selection #f(0 0 0 0 1 0))
  (setq jacobi-pitch (transform selection jacobi))
  (setq selection #f(0 0 0 0 0 1))
  (setq jacobi-yaw (transform selection jacobi))
  ;;pack the line components into Jacobian msg
  (setq msg (instance jsk_2019_10_spatula::Jacobian :init))
  (send msg :x jacobi-x)
  (send msg :y jacobi-y)
  (send msg :z jacobi-z)
  (send msg :roll jacobi-yaw)
  (send msg :pitch jacobi-pitch)
  (send msg :yaw jacobi-yaw)
  ;;publish the msg
  (if (= arm 0)
      (ros::publish "scrape_left_jacobian" msg)
      (ros::publish "scrape_right_jacobian" msg))
  )

;;get jacobian in world coordinate frame
(defun get-jacobi-l-world ()
  (setq link-list (send *pr2* :link-list (send (send *pr2* :larm :end-coords) :parent)))
  (setq joint-list (send-all link-list :joint))
  (setq jacobi
	(send *pr2* :calc-jacobian-from-link-list
	      link-list
	      :move-target (send *pr2* :larm :end-coords)
	      :transform-coords (make-coords) ;;in world coords, if left out it is in local coords
	      :rotation-axis t
	      ))
  ;;(format-array jacobi) ;; print
  (publish-jacobi 0)
  )

(defun get-jacobi-r-world ()
  (setq link-list (send *pr2* :link-list (send (send *pr2* :rarm :end-coords) :parent)))
  (setq joint-list (send-all link-list :joint))
  (setq jacobi
	(send *pr2* :calc-jacobian-from-link-list
	      link-list
	      :move-target (send *pr2* :rarm :end-coords)
	      :transform-coords (make-coords) ;;jacobian is in world coords
	      :rotation-axis t
	      ))
  ;;(format-array jacobi) ;; print
  (publish-jacobi 1)
  )

(defun adjust-force (msg)
  (let (cmd)
    (setq cmd (+ *cmd* (* 0.7 (send msg :data))))
    ;;only interpolation betwen the two vectors, not etxrapolaiton
    (if (> cmd 1) (setq *cmd* 1)
    (if (< cmd 0) (setq *cmd* 0);;else if 
    (setq *cmd* cmd)));;else
  ))

(defun reset-pose-high ()
  (send *pr2* :angle-vector  *av-reset-pose-high*)
  (if (boundp '*irtviewer*)
    (send *irtviewer* :draw-objects))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun prepare-robot ()

  (reset-pose-high)
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
  (publish-semantic-annotation (format nil "av-new-bowl_start"))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :larm-controller)
  (publish-semantic-annotation (format nil "av-new-bowl"))
  (send *ri* :wait-interpolation)

  (publish-semantic-annotation (format nil "hand-bowl_end"))
  
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
  ;;(setq *l-tcp* (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  ;;(setq *ltargetframe* (send *pr2* :larm :end-coords))
  )

(defun clean-walls()
  (get-dense-ptcloud)
  (while (not label-published)
    (ros::spin-once);;to see if labels where published
    ))

(defun get-dense-ptcloud()
  (ros::service-call "passthrough_points/request" (instance std_srvs::EmptyRequest :init))
  (send *pr2* :angle-vector *look-front*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  (unix:usleep 10000) ;;sleep 1/100 of a second to make sure /tf is fresh
  ;;passthrough the pointcloud data
  (ros::service-call "passthrough_points/request" (instance std_srvs::EmptyRequest :init))
  (publish-semantic-annotation (format nil "vision_0"))
  
  (send *pr2* :angle-vector *look-right*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  (unix:usleep 10000) ;;sleep 1/100 of a second to make sure /tf is fresh
  (ros::service-call "passthrough_points/request" (instance std_srvs::EmptyRequest :init))
  (publish-semantic-annotation (format nil "vision_1"))

  (send *pr2* :angle-vector *look-back*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  ;;(unix:sleep 1)
  (ros::service-call "passthrough_points/request" (instance std_srvs::EmptyRequest :init))
  (publish-semantic-annotation (format nil "vision_2"))

  (send *pr2* :angle-vector *look-left*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  (unix:usleep 10000) ;;sleep 1/100 of a second to make sure /tf is fresh
  (ros::service-call "passthrough_points/request" (instance std_srvs::EmptyRequest :init))
  (publish-semantic-annotation (format nil "vision_3"))

  (send *pr2* :angle-vector *av-snapshot*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  (unix:usleep 10000) ;;sleep 1/100 of a second to make sure /tf is fresh
  (ros::service-call "passthrough_points/request" (instance std_srvs::EmptyRequest :init))
  (publish-semantic-annotation (format nil "vision_end"))
  )

;;define callback function
(defun schedule-scraping (msg)
  (setq label-published t)
  (print "schedule scraping now")
  (setq *label* (send msg :data))
  (setq i 0)
  (dolist (dirty *label*)
    (print dirty)
    (when (and dirty (not (= i 7))) ;;if piece is dirty and not 7
      (print "scrape, it is dirty!")
      (print i)
      (clean i)
      )
    (setq i (+ i 1))
    )
  )

(defun clean (i)
  (setq position (+ (mod i *n-bowl-position*) 1 ))
  (setq step-size (/ 360 (* 4  5)))
  (if (< i *n-bowl-position*)
      (setq type 0)
      (if (< i (* 2 *n-bowl-position*)) ;;elseif
	  (setq type 1)
	  (if (< i (* 3 *n-bowl-position*)) ;;elseif
	      (setq type 2)
	      (setq type 3))));;else
  (unless (= oldtype type)
     (send *pr2* :angle-vector *av-base*)	  
     (send *ri* :angle-vector (send *pr2* :angle-vector) 500 :rarm-controller)	  
     (send *ri* :wait-interpolation))
  (position-left-arm position 1000)
  (scrape-wall 1000 type position)
  (setq oldtype type)
  )


(defun position-left-arm (position speed)
  (print "POSITION")
  (print *cmd*)
  (setq fail nil)
  (setq *av-circulate-bowl-larm-1* (v+ *av-circulate-bowl-larm-1-up* (scale *cmd* (v-  *av-circulate-bowl-larm-1-down* *av-circulate-bowl-larm-1-up*))))
  (setq *av-circulate-bowl-larm-2* (v+ *av-circulate-bowl-larm-2-up* (scale *cmd* (v-  *av-circulate-bowl-larm-2-down* *av-circulate-bowl-larm-2-up*))))
  (setq *av-circulate-bowl-larm-3* (v+ *av-circulate-bowl-larm-3-up* (scale *cmd* (v-  *av-circulate-bowl-larm-3-down* *av-circulate-bowl-larm-3-up*))))
  (setq *av-circulate-bowl-larm-4* (v+ *av-circulate-bowl-larm-4-up* (scale *cmd* (v-  *av-circulate-bowl-larm-4-down* *av-circulate-bowl-larm-4-up*))))
  (if (= position 1) (send *pr2* :larm :angle-vector *av-circulate-bowl-larm-1*)
      (if (= position 2) (send *pr2* :larm :angle-vector *av-circulate-bowl-larm-2*)   
	  (if (= position 3) (send *pr2* :larm :angle-vector *av-circulate-bowl-larm-3*)
	      (if (= position 4) (send *pr2* :larm :angle-vector *av-circulate-bowl-larm-4*)
		  (setq fail t)))))
  (if fail
      (print "sorry the position you chose does not exist")
      ;;(send *ri* :angle-vector (send *pr2* :angle-vector) :fast :larm-controller 0 :min-time 0.0 :scale 20))
      (send *ri* :angle-vector (send *pr2* :angle-vector) speed :larm-controller))
  (send *ri* :wait-interpolation)
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

;;scraping movement of the right arm to scrape the wall of the bowl
(defun scrape-wall (speed type bowl-position)
  ;;scrape the side of handle
  (get-jacobi-l-world)
  (when (= type 3) (load "av-scrape-wall-3.l"))
  ;;scrape the opposite of handle
  (when (= type 1) (load "av-scrape-wall-1.l"))
  ;;scrape the back, close to robot
  (when (= type 2) (load "av-scrape-wall-2.l"))
  ;;scrape the front, away from robot
  (when (= type 0) (load "av-scrape-wall-0.l"))

  ;;start with home pos
  (unless (= oldtype type)
    (send *pr2* :rarm :angle-vector *av4-wall*)
    (unless (arm-collision-check)
      (send *ri* :angle-vector (send *pr2* :angle-vector) speed :rarm-controller)
        (while (send *ri* :interpolatingp :rarm-controller)
	  (send *ri* :spin-once)
	  (ros::spin-once);;to see if err was published
	  (get-jacobi-r-world)
	  (if (send *ri* :simulation-modep)  
	      (send *ri* :robot-interface-simulation-callback)))))
  
  (send *pr2* :rarm :angle-vector *av1-wall*)
  (unless (arm-collision-check)
    (publish-semantic-annotation (format nil "av1wall-~a-~a_start" type bowl-position))
    (send *ri* :angle-vector (send *pr2* :angle-vector) speed :rarm-controller)
    (while (send *ri* :interpolatingp :rarm-controller)
      (send *ri* :spin-once)
      (ros::spin-once);;to see if err was published
      (get-jacobi-r-world)
      (if (send *ri* :simulation-modep)
	  (send *ri* :robot-interface-simulation-callback)))
    (publish-semantic-annotation (format nil "av1wall-~a-~a_end" type bowl-position)))
  
  (send *pr2* :rarm :angle-vector *av2-wall*)
  (unless (arm-collision-check)
    (publish-semantic-annotation (format nil "av2wall-~a-~a_start" type bowl-position))
    (send *ri* :angle-vector (send *pr2* :angle-vector) speed :rarm-controller)
    (while (send *ri* :interpolatingp :rarm-controller)
      (send *ri* :spin-once)
      (ros::spin-once);;to see if err was published
      (get-jacobi-r-world)
      (if (send *ri* :simulation-modep)
	  (send *ri* :robot-interface-simulation-callback)))
    (publish-semantic-annotation (format nil "av2wall-~a-~a_end" type bowl-position)))

  (send *pr2* :rarm :angle-vector *av3-wall*)
  (unless (arm-collision-check)
    (publish-semantic-annotation (format nil "av3wall-~a-~a_start" type bowl-position))
    (send *ri* :angle-vector (send *pr2* :angle-vector) speed :rarm-controller)
    (while (send *ri* :interpolatingp :rarm-controller)
      (send *ri* :spin-once)
      (ros::spin-once);;to see if chatter published
      (get-jacobi-r-world)
      (if (send *ri* :simulation-modep)
	  (send *ri* :robot-interface-simulation-callback))
      )
    
    (publish-semantic-annotation (format nil "av3wall-~a-~a_end" type bowl-position)))

  (send *pr2* :rarm :angle-vector *av4-wall*)
  (unless (arm-collision-check)
    (publish-semantic-annotation (format nil "av4wall-~a-~a_start" type bowl-position))
    (send *ri* :angle-vector (send *pr2* :angle-vector) speed :rarm-controller)
    (while (send *ri* :interpolatingp :rarm-controller)
      (send *ri* :spin-once)
      (ros::spin-once);;to see if chatter published
      (get-jacobi-r-world)
      (if (send *ri* :simulation-modep)
	  (send *ri* :robot-interface-simulation-callback)))
    (publish-semantic-annotation (format nil "av4wall-~a-~a_end" type bowl-position)))
  )

(defun prepare-bowl-transfer-safe ()
  (send *pr2* :angle-vector *av3*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-transfer-1-l*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-transfer-2-l*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-transfer-3-l*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-transfer-4-l*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-transfer-45-l*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-transfer-5-l*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-transfer-6-l*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  )

(defun transfer-dough()
  ;;scrape four different path
  (transfer-dough-path 0)
  (transfer-dough-path 1)
  (transfer-dough-path 4)
  (transfer-dough-path 3)
  (transfer-dough-path 2)
  (transfer-dough-path 4)
  (transfer-dough-path 3)
  (transfer-dough-path 2)
  )

(defun transfer-dough-path (type)
  (get-jacobi-l-world)
  ;;all the way left
  (when (= type 0) (load "av-transfer-dough-0.l"))
  ;;left
  (when (= type 1) (load "av-transfer-dough-1.l"))
  ;;middle
  (when (= type 2) (load "av-transfer-dough-2.l"))
  ;;right
  (when (= type 3) (load "av-transfer-dough-3.l"))
  ;;all the way right
  (when (= type 4) (load "av-transfer-dough-4.l"))

  (setq *av-transfer-1-r* (v+ *av-transfer-1-r-short* (scale *cmd* (v- *av-transfer-1-r-long*  *av-transfer-1-r-short*))))
  (setq *av-transfer-2-r* (v+ *av-transfer-2-r-short* (scale *cmd* (v- *av-transfer-2-r-long*  *av-transfer-2-r-short*))))
  (setq *av-transfer-3-r* (v+ *av-transfer-3-r-short* (scale *cmd* (v- *av-transfer-3-r-long*  *av-transfer-3-r-short*))))
  (setq *av-transfer-4-r* (v+ *av-transfer-4-r-short* (scale *cmd* (v- *av-transfer-4-r-long*  *av-transfer-4-r-short*))))
  (setq *av-transfer-5-r* (v+ *av-transfer-5-r-short* (scale *cmd* (v- *av-transfer-5-r-long*  *av-transfer-5-r-short*))))
  
  (send *pr2* :rarm :angle-vector *av-transfer-r-home-pos*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :angle-vector *av-transfer-1-r*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :angle-vector *av-transfer-2-r*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :rarm :angle-vector *av-transfer-3-r*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :angle-vector *av-transfer-4-r*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :angle-vector *av-transfer-5-r*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
  (send *ri* :wait-interpolation)
  )

(defun clean-edge ()
  (send *pr2* :rarm :angle-vector *av-scrape-edge-1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
  (send *ri* :wait-interpolation)
  (send *pr2* :rarm :angle-vector *av-scrape-edge-2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
  (send *ri* :wait-interpolation)
  (send *pr2* :rarm :angle-vector *av-scrape-edge-3*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
  (send *ri* :wait-interpolation)
  (send *pr2* :rarm :angle-vector *av-scrape-edge-1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
  (send *ri* :wait-interpolation)
  )

(defun place-bowl ()
  (send *pr2* :angle-vector  *av-transfer-6-l*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector  *av-transfer-5-l*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector  *av-transfer-45-l*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector  *av-transfer-4-l*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-set-bowl-counter1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-set-bowl-counter2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-set-bowl-counter3*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-set-bowl-counter4*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :stop-grasp)
  (send *ri* :stop-grasp :rarm)
  (send *ri* :wait-interpolation)
  (send *ri* :stop-grasp :larm)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-set-bowl-counter5*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-set-bowl-counter6*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-set-bowl-counter7*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-set-bowl-counter8*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  )

(defun pick-up-cup ()
  (send *pr2* :angle-vector *av-prepare-cup1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av-prepare-cup2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av1-cup*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av2-cup*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av4-cup*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (send *ri* :start-grasp :rarm :gain 0.05)
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector *av3-cup*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1500)
  (send *ri* :wait-interpolation)
  )


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;functions for debuggin only ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun get-pctloud-piece (i)
  (clean i)
  (get-dense-ptcloud)
  )

(defun get-pctloud-all-clean ()
  ;;clean the whole bowl
  (dolist (i (list 0 1 2 3 4 5 6 8 9 10 11 12 13 14 15)) ;;7 is front, does not need to be cleaned!
    (clean i)
    (get-dense-ptcloud)
    ))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;
;;subcriptions;;
;;;;;;;;;;;;;;;;
(ros::subscribe "pcl_nodelet/dirt_label" jsk_2019_10_spatula::BoolArray #'schedule-scraping)
(ros::subscribe "force_err"  std_msgs::float64 #'adjust-force)


;;;;;;;;;;;;;;;;;
;;main function;;
;;;;;;;;;;;;;;;;;
(defun exec ()
  ;;(prepare-robot)
  (clean-walls)
  (send *ri* :go-pos-unsafe 0.3 0 0)
  (prepare-bowl-transfer-safe)
  (transfer-dough)
  ;;(clean-edge)
  (place-bowl)
  (pick-up-cup)
  ;;later all this should be one function
  (send *ri* :go-pos-unsafe -0.3 0 0)
  (send *pr2* :angle-vector *av-prepare-move-microwave1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  (send *ri* :go-pos-unsafe 0 0 -90)
  (send *ri* :go-pos-unsafe 1.4 0 0)
  (send *ri* :go-pos-unsafe 0 0 -90)
  (send *ri* :go-pos-unsafe -0.1 0 0)
  ;;now microwave demo
  )



