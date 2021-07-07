#!/usr/bin/env roseus

;; load pr2-interface.l
(load "package://pr2eus/pr2-interface.l")

;; init 
(pr2-init)

;; reset-manip-pose
(send *pr2* :reset-manip-pose)
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
(send *ri* :wait-interpolation)


;; トピックなどを定義
(defvar *topic-name* "/icp_registration/output_pose")

;; ros init
(ros::roseus "icp_tf_check" :anonymous t)
(ros::load-ros-manifest "geometry_msgs")
(setq *l* (instance ros::transform-listener :init))
(setq found-obj nil)
(setq obj-pos #f(0 0 0))
(setq obj-coord (make-coords :pos #f(0 0 0)))

;; define cb
(defun object-pose-cb (msg)
  (setq *msg* msg)
  (print 1)
  (when msg
    (setq tm (send *l* :get-latest-common-time "base_link" "head_mount_kinect_rgb_optical_frame"))
    (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    (let* ((b (send msg :pose))
	   (ref->obj-coords (ros::tf-pose->coords b))
	   (cam->ref (make-coords :pos #f(0 0.13 1.22) :rpy #f(-1.57 2.45 0))))
      (setq cam-coords (send *l* :lookup-transform "base_link" "head_mount_kinect_rgb_optical_frame" tm))
      (setq obj-coord (send (send cam-coords :transform cam->ref) :transform ref->obj-coords))
      (setq obj-pos (scale 0.001 (send obj-coord :worldpos)))
      (setq found-obj t)
      (print (list 'found? found-obj obj-pos))
      obj-pos)))


;; subscribeして認識
(ros::subscribe *topic-name* geometry_msgs::PoseStamped #'object-pose-cb 1)
(setq *b* (instance ros::transform-broadcaster :init))

(print 3)
(setq box (make-cube 10 50 50))
(send box :set-color :red)
(send box :locate #f(500 0 1000) :world)
(objects (list *pr2* box))
(setq found-obj nil)
(do-until-key ;;
;;(until found-obj
 (print 4)
 (when (> (norm obj-pos) 0)
    (send box :locate (scale 1000 obj-pos) :world);;;)
    (send *irtviewer* :draw-objects)

    ;;Rvizに表示をする。
    (setq tm (ros::time-now))
    (send *b* :send-transform cam-coords "base_link" "kettle" tm)

    )
 
 ;;
 (x::window-main-one) ;; IRT viewerの視点を変えられる。見にくければ変えよう
 (ros::spin-once)
 (ros::sleep)
 )

