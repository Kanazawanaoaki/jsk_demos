;; トピックなどを定義
(defvar *topic-name* "/segmentation_decomposer/boxes")

;; ros init
(ros::roseus "potato_rec_test" :anonymous t)
(ros::load-ros-manifest "jsk_recognition_msgs")
(setq *l* (instance ros::transform-listener :init))
(setq found-obj nil)
(setq obj-pos #f(0 0 0))
(setq obj-coord (make-coords :pos #f(0 0 0)))
(print 0)


(load "package://pr2eus/pr2.l")
(pr2)

(send *pr2* :reset-manip-pose)
(send *pr2* :torso_lift_joint :joint-angle 325)

;; define cb
(defun object-pose-cb (msg)
  (setq *msg* msg)
  (setq *bbox* (car (send msg :boxes)))
  ;; (print 1)
  (when msg
    (setq *dim* (send *bbox* :dimensions))
    (setq *cube* (make-cube (* (send *dim* :x) 1000) (* (send *dim* :y) 1000) (* (send *dim* :z) 1000)))
    (setq *pose* (send *bbox* :pose))
    (setq cam->obj-coords (ros::tf-pose->coords *pose*))
    (setq cam-coords (send (send *pr2* :head_mount_kinect_rgb_optical_frame_lk) :copy-worldcoords))
    ;; (cam-coords (send *l* :lookup-transform "base_footprint" "head_mount_kinect_rgb_optical_frame" tm2)))
    (setq obj-coord (send cam-coords :transform cam->obj-coords))
    (setq obj-pos (scale 0.001 (send obj-coord :worldpos)))
    (setq found-obj t)
    (print (list 'found? found-obj obj-pos))
    obj-pos))
    
    
    ;; (setq found-obj t)
    ;; )
  ;; (when msg
  ;;   (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  ;;   (setq tm2 (send *l* :get-latest-common-time "base_footprint" "head_mount_kinect_rgb_optical_frame"))
  ;;   (let* ((b (send msg :pose))
  ;; 	  (cam->obj-coords (ros::tf-pose->coords b))
  ;; 	  ;; (cam-coords (send (send *pr2* :head_mount_kinect_rgb_optical_frame_lk) :copy-worldcoords)))
  ;; 	  (cam-coords (send *l* :lookup-transform "base_footprint" "head_mount_kinect_rgb_optical_frame" tm2)))
  ;;     (setq obj-coord (send cam-coords :transform cam->obj-coords))
  ;;     (setq obj-pos (scale 0.001 (send obj-coord :worldpos)))
  ;;     (setq found-obj t)
  ;;     (print (list 'found? found-obj obj-pos))
  ;;     obj-pos))
  ;; )


;; subscribeして認識
(ros::subscribe *topic-name* jsk_recognition_msgs::BoundingBoxArray #'object-pose-cb 1)
(setq *b* (instance ros::transform-broadcaster :init))

(print 3)
(setq *cube* (make-cube 10 50 50))
(send *cube* :set-color :red)
(send *cube* :locate #f(500 0 1000) :world)
(objects (list *cube* *pr2*))

(setq found-obj nil)
;; (do-until-key ;;
(until found-obj
  (print 4)
  (when (> (norm obj-pos) 0)
    ;; (send *cube* :locate (scale 1000 obj-pos) :world);;;)
    ;; (objects (list *cube* *pr2*))
    ;; (send *irtviewer* :draw-objects)

    ;;Rvizに表示をする。
    ;; (setq tm (ros::time-now))
    ;; (send *b* :send-transform obj-coord "base_footprint" "kettle" tm)

    )
  ;;
  (x::window-main-one) ;; IRT viewerの視点を変えられる。見にくければ変えよう
  (ros::spin-once)
  (ros::sleep)
  )


;; ikを解く
(send *cube* :newcoords (send obj-coord :copy-worldcoords))
(objects (list *cube* *pr2*))
(send *irtviewer* :draw-objects)
