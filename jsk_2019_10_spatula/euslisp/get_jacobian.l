#!/usr/bin/env roseus

(ros::load-ros-package "jsk_2019_10_spatula")
(load "package://pr2eus/pr2-interface.l")
(ros::roseus "pr2_send_joints")
(ros::advertise "scrape_left_jacobian" jsk_2019_10_spatula::Jacobian 1)
(ros::advertise "scrape_right_jacobian" jsk_2019_10_spatula::Jacobian 1)
(setq *ri* (instance pr2-interface :init))
(pr2-init t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; define global variables ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq *av3* #f(324.807 51.8719 24.8194 124.823 -101.389 -6.18697 -32.6134 135.062 -29.0716 -9.25665 -86.0776 -118.804 -76.2328 -66.8658 270.291 3.0727 72.0))
(setq *perfect-av* #f(324.807 52.2956 26.3949 124.149 -100.069 -5.19275 -35.2495 136.315 -29.0716 -9.25665 -86.0776 -118.804 -76.2328 -66.8658 270.291 3.0727 72.0))


;;;;;;;;;;;;;;;;;;;;;;
;; define functions ;;
;;;;;;;;;;;;;;;;;;;;;;

(defun get-jacobi-l-local ()
  (setq link-list (send *pr2* :link-list (send (send *pr2* :larm :end-coords) :parent)))
  (setq joint-list (send-all link-list :joint))

  (setq jacobi
	(send *pr2* :calc-jacobian-from-link-list
	      link-list
	      :move-target (send *pr2* :larm :end-coords)
	      :rotation-axis t
	      ))
  (format-array jacobi) ;; print
  (publish-jacobi 0)
 )

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
  (format-array jacobi) ;; print
  (publish-jacobi 0)
  )

(defun get-jacobi-r ()
  (setq link-list (send *pr2* :link-list (send (send *pr2* :rarm :end-coords) :parent)))
  (setq joint-list (send-all link-list :joint))

  (setq jacobi
	(send *pr2* :calc-jacobian-from-link-list
	      link-list
	      :move-target (send *pr2* :rarm :end-coords)
	      :transform-coords (make-coords)
	      :rotation-axis t
	      ))

  (format-array jacobi) ;; print
  (publish-jacobi 1)
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
  ;;print the msg
  (ros::ros-info "msg [~A]" (send msg :x))
  ;;publish the msg
  (if (= arm 0)
      (ros::publish "scrape_left_jacobian" msg)
      (ros::publish "scrape_right_jacobian" msg)
      )
  
  )


;;;;;;;;;;;;;;;;;;;;
;; move the robot ;;
;;;;;;;;;;;;;;;;;;;;

;;(send *pr2* :angle-vector *av3*) 
;;(send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
;;(send *ri* :wait-interpolation)
(get-jacobi-l t)



