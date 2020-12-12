#!/usr/bin/env roseus

(ros::roseus "simple-screen-point-test")             
(ros::load-ros-package "geometry_msgs")
(setq *pub-topic* "/head_mount_kinect/rgb/image_raw/screenpoint")
(setq *sub-topic* "/pointcloud_screenpoint_nodelet/output_point")
(setq *camera-frame* "head_camera_rgb_optical_frame")

(load "package://pr2eus/pr2-interface.l")
(pr2-init)

(unless (boundp '*tfl*)
  (setq *tfl* (instance ros::transform-listener :init)))

(defun look-table ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :head :look-at
        (send (send (send *pr2* :torso :end-coords :copy-worldcoords)
                    :translate #f(750 0 0)) :worldpos))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation))

(defun cb (msg)
  (let ((waist-to-camera (send *tfl* :lookup-transform "odom" *camera-frame* (ros::time 0)))
        ;; use ros::tf-point->coords
        (coords (make-coords :pos (ros::tf-point->pos (send msg :point)))))
    (send coords :transform waist-to-camera :world)
    (format t "food coords is ~A~%" (send coords :pos))))


(ros::advertise *pub-topic* geometry_msgs::PointStamped 1)
(ros::subscribe *sub-topic* geometry_msgs::PointStamped #'cb)

;; main
(look-table)

(let* ((x 240)
       (y 320)
       (pub-msg (instance geometry_msgs::Pointstamped :init)))
  ;; publish
  (format t "x y ~A ~A~%" x y)
  (send pub-msg :header :stamp (ros::time-now))
  (send pub-msg :header :frame_id *camera-frame*)
  (send (send pub-msg :point) :x x)
  (send (send pub-msg :point) :y y)
  (send (send pub-msg :point) :z 0)
  (ros::publish *pub-topic* pub-msg)
  ;; subscribe
  (unix:usleep (* 100 1000))
  (ros::spin-once)
  )

(ros::exit)
