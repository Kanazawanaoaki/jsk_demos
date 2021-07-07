#!/usr/bin/env roseus

(defun init ()
  (load "../model/my-room73b2-scene.l")
  (setq *room* (room73b2))

  (load "models/room73b2-kitchen-object.l")
  (setq *kitchen* (room73b2-kitchen))
  ;; (send *kitchen* :transform (make-coords :pos (float-vector 305.0 2175.0 0.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))
  (send *kitchen* :transform (make-coords :pos (float-vector 305.0 2175.0 20.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))

  (load "package://pr2eus/pr2-interface.l")
  (pr2-init)
  ;; (pr2)


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
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

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

(warn "please run  (grasp-potato) ~%")

(defun grasp-potato ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 200) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; じゃがいもの掴む所に
  (send *arrow* :newcoords (send *potato* :copy-worldcoords))
  (send *arrow* :locate (float-vector (/ width -3) 0 0))
  (send *arrow* :rotate (deg2rad 20) :y)


  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate #f(0 -100 100) :world)
  
  (send *pr2* :larm :inverse-kinematics (send *arrow* :copy-worldcoords))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 100 -100) :world)
  (send *pr2* :larm :inverse-kinematics (send *arrow* :copy-worldcoords))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  (send *ri* :start-grasp :larm :wait t)

  
  ;; (send *pr2* :larm :inverse-kinematics
  ;;     (send *arrow* :copy-worldcoords)
  ;;     :rotation-axis t
  ;;     :debug-view t
  ;;     )
  
   
  (send *arrow* :newcoords (send *cut-point-1* :copy-worldcoords))
  (warn "please run  (set-knife-ver) ~%")
  )

(defun set-knife-ver ()
  ;; set pose
  (send *arrow* :newcoords (make-coords :pos #f(700.191 2189.104 866.677) :rpy #f(-2.341 -0.222 -0.482)))
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  ;; grasp knife
  (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :speak-jp "包丁を握らせて下さい")
  (unix:sleep s-time)
  ;; (send *ri* :start-grasp :rarm :wait t)
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  
  (setq *knife* (knife))
  (send *knife* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *pr2* :rarm :end-coords :assoc *knife*)

  (objects (list *kitchen* *pr2* *cutting-board* *potato* *knife*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (cut-test3) ~%")
  )


(defun cut-test3 ()
  (if (not (boundp '*potato*))
      (set-potato :w 90 :l 60 :h 60))

  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)


  ;; 少し上に包丁を

  (send *arrow* :newcoords (send *cut-point-1* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 (* height 1)))  

  ;; 少し上にするために
  (setq offset 10)
 
  (send *arrow* :translate (float-vector 0 0 offset))  
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  

  (send *arrow* :translate (float-vector 0 0 (* offset -1)))  
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq interval 10)
  (dotimes (i (+ (round (/ height interval)) 1))
    (send *arrow* :translate (float-vector interval 0 (/ interval -2)))
    (send *pr2* :rarm :inverse-kinematics
      *arrow*
      :move-target (car (send *knife* :attention))
      :rotation-axis t
      :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)

    (send *arrow* :translate (float-vector (* interval -1) 0 (/ interval -2)))
    (send *pr2* :rarm :inverse-kinematics
      *arrow*
      :move-target (car (send *knife* :attention))
      :rotation-axis t
      :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)

    )
  
  (warn "you can retry (cut-test1) , (cut-test2) , (cut-test3), (larm-cut) , (larm-cut2) or you want to finish please run (finish)  ~%")
  )

(defun larm-cut ()
  (send *ri* :stop-grasp :larm :wait t)

  (send *arrow* :newcoords (send *potato* :copy-worldcoords))
  (send *arrow* :translate #f(0 -100 100) :world)
  (send *pr2* :larm :inverse-kinematics (send *arrow* :copy-worldcoords))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :larm :wait t)

  (send *arrow* :newcoords (make-coords :pos (send *cut-point-1* :worldpos)))
  (send *arrow* :rotate (deg2rad 90) :z)
  (send *arrow* :rotate (deg2rad 90) :y)

  (send *arrow* :translate (float-vector 0 0 (+ height 30)) :world)
  (send *pr2* :larm :inverse-kinematics
    *arrow*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 (* (+ height 30) -1)) :world)
  (send *pr2* :larm :inverse-kinematics
    *arrow*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (warn "you can set (set-larm) ~%")
  )

(defun finish ()
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :newcoords (send *potato* :copy-worldcoords))
  (send *arrow* :translate #f(0 -100 100) :world)
  (send *pr2* :larm :inverse-kinematics (send *arrow* :copy-worldcoords))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  )
