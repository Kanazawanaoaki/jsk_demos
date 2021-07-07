#!/usr/bin/env roseus

(defun init ()
  (load "../model/my-room73b2-scene.l")
  (setq *room* (room73b2))

  (load "models/room73b2-kitchen-object.l")
  (setq *kitchen* (room73b2-kitchen))
  ;; (send *kitchen* :transform (make-coords :pos (float-vector 305.0 2175.0 0.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))
  (send *kitchen* :transform (make-coords :pos (float-vector 305.0 2175.0 20.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))

  (load "package://pr2eus/pr2-interface.l")
  ;; (pr2-init)
  (pr2)


  ;; set まな板
  (load "../model/cutting-board.l")
  (setq *cutting-board* (cutting-board))
  ;; (send *cutting-board* :transform (make-coords :pos (float-vector 480.0 1950.0 820.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))
  (send *cutting-board* :transform (make-coords :pos (float-vector 480.0 1950.0 840.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))

  ;; set objects
  (load "../model/peeler.l")
  (load "../model/my-knife.l")
  (load "models/arrow-object.l")
  (setq *arrow* (arrow))

  ;; set spots
  (setq *cook-spot* (send *room73b2* :spot "cook-spot"))
  (setq *sink-spot* (make-coords :pos #f(1055 2600 0) :rpy #f(3.14 0 0))) 
  (setq *kitchen-spot* (send *room73b2* :spot "kitchen-spot"))


  ;; キッチンの場所まで移動 (初期値)
  (defun move-to-kitchen-irt ()
    (send *pr2* :move-to *kitchen-spot* :world)
    )
  (move-to-kitchen-irt)
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)

  (objects (list *pr2* *cutting-board*))

  ;; def global values
  (setq s-time 4)

  ;; set potato
  (load "../model/potato-test-model.l")

  (setq width 90)
  (setq length 60)
  (setq height 60)
  )

(init)

;; WIP!!!!!!!!!!!!!!!!!!!!!!!!!!!


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


;; define cb
(defun object-pose-cb (msg)
  (setq *msg* msg)
  (setq *bbox* (car (send msg :boxes)))
  ;; (print 1)
  (when msg
    (setq tm2 (send *l* :get-latest-common-time "base_footprint" "head_mount_kinect_rgb_optical_frame"))
    ;; (setq tm2 (send *l* :get-latest-common-time "base_lnik" "head_mount_kinect_rgb_optical_frame"))
    
    (setq *dim* (send *bbox* :dimensions))
    (setq width (* (send *dim* :x) 1000))
    (setq length (* (send *dim* :y) 1000))
    (setq height (* (send *dim* :z) 1000))
    (setq *pose* (send *bbox* :pose))
    (setq cam->obj-coords (ros::tf-pose->coords *pose*))
    ;; (setq cam-coords (send (send *pr2* :head_mount_kinect_rgb_optical_frame_lk) :copy-worldcoords))    
    ;; (setq cam-coords (send *l* :lookup-transform "base_footprint" "head_mount_kinect_rgb_optical_frame" tm2))

    (setq cam-coords (send (send *pr2* :copy-worldcoords) :transform (send *l* :lookup-transform "base_footprint" "head_mount_kinect_rgb_optical_frame" tm2)))
    ;; (setq cam-coords (send (send *pr2* :copy-worldcoords) :transform (send *l* :lookup-transform "base_lnik" "head_mount_kinect_rgb_optical_frame" tm2)))

    (setq obj-coord (send cam-coords :transform cam->obj-coords))
    (setq tmp (- (+ (elt (send obj-coord :pos) 2) (/ height 2)) (+ (elt (send *cutting-board* :worldpos) 2) 10)))
    (send obj-coord :translate (float-vector 0 0 (- (/ height 2) (/ tmp 2))) :world)
    (setq height tmp)
    
    (setq obj-pos (scale 0.001 (send obj-coord :worldpos)))
    (setq found-obj t)
    (print (list 'found? found-obj obj-pos))
    obj-pos))


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
  ;; (when (> (norm obj-pos) 0)
  ;;   (send box :locate (scale 1000 obj-pos) :world);;;)
  ;;   (send *irtviewer* :draw-objects)

  ;;   ;;Rvizに表示をする。
  ;;   ;; (setq tm (ros::time-now))
  ;;   ;; (send *b* :send-transform obj-coord "base_footprint" "kettle" tm)

  ;;   )
  ;;
  (x::window-main-one) ;; IRT viewerの視点を変えられる。見にくければ変えよう
  (ros::spin-once)
  (ros::sleep)
  )


;; ikを解く
(load "models/arrow-object.l")
(setq *arrow* (arrow))
(send *arrow* :newcoords (send obj-coord :copy-worldcoords))

;; (load "../model/potato-test-model.l")
(load "../model/potato-new-type.l")
(setq *potato* (potato :w  width :l length :h height))
(send *potato* :newcoords (send obj-coord :copy-worldcoords))
(send *potato* :rotate (deg2rad 180) :x)
(send *potato* :cut)
(objects (list *potato* *pr2* *cutting-board* *arrow*))
(send *irtviewer* :draw-objects)

(send *arrow* :newcoords (send *potato* :copy-worldcoords))
(send *arrow* :locate (float-vector (/ width -3) 0 0))
(send *arrow* :rotate (deg2rad 20) :y)

(send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t
      )


(send *arrow* :newcoords (send *cut-point-1* :copy-worldcoords))
