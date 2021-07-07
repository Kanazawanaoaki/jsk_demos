(defun init ()
  (load "../../model/my-room73b2-scene.l")
  (setq *room* (room73b2))

  (load "models/room73b2-kitchen-object.l")
  (setq *kitchen* (room73b2-kitchen))
  (send *kitchen* :transform (make-coords :pos (float-vector 305.0 2175.0 20.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))

  (load "package://pr2eus/pr2-interface.l")
  (pr2-init)
  ;; (pr2)

  ;; set まな板
  (load "../../model/cutting-board.l")
  (setq *cutting-board* (cutting-board))
  (send *cutting-board* :transform (make-coords :pos (float-vector 500.0 2000.0 840.0) :rot #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))))
  
  ;; set objects
  (load "../../model/peeler.l")
  ;; (load "../../model/my-knife.l")
  (load "../../model/knife-new-attention.l")
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
  (setq s-time 3)

  ;; def global coords
  (setq *micro-cup-put-coords* (make-coords :pos (float-vector 300 2050 1030) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0)))) ;; 300も良さげではあった．
  (setq *bowl-1-put-coords* (make-coords :pos (float-vector 328 1933 997) :rpy #f(2.837 0.793 -1.721)))
  (setq *bowl-2-put-coords* (make-coords :pos (float-vector 323 2131 960) :rpy #f(2.697 0.249 3.102)))
    
  (setq width 160)
  (setq length 40)
  (setq height 40)
  )

(init)


;; トピックなどを定義
(setq *topic-name* "/segmentation_decomposer/boxes")

;; ros init
(ros::roseus "vegs_rec_test" :anonymous t)
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
    (when (send *msg* :boxes)
      (let ((cam-coords nil))
    (setq tm2 (send *l* :get-latest-common-time "base_footprint" "head_mount_kinect_rgb_optical_frame"))    
    (setq *dim* (send *bbox* :dimensions))
    (setq width (* (send *dim* :x) 1000))
    (setq length (* (send *dim* :y) 1000))
    (setq height (* (send *dim* :z) 1000))
    (setq *pose* (send *bbox* :pose))
    (setq cam->obj-coords (ros::tf-pose->coords *pose*))
    (when (send *l* :wait-for-transform  "base_footprint" "head_mount_kinect_rgb_optical_frame" tm2 10)
      (setq cam-coords (send (send *pr2* :copy-worldcoords) :transform 
                 (send *l* :lookup-transform "base_footprint" "head_mount_kinect_rgb_optical_frame" tm2))))
    (when cam-coords
      (setq obj-coord (send cam-coords :transform cam->obj-coords))
      (setq tmp (- (+ (elt (send obj-coord :pos) 2) (/ height 2)) (+ (elt (send *cutting-board* :worldpos) 2) 10)))
      (send obj-coord :translate (float-vector 0 0 (- (/ height 2) (/ tmp 2))) :world)
      (setq height tmp)
        
      (setq obj-pos (scale 0.001 (send obj-coord :worldpos)))
      (if (> width 0)
          (setq found-obj t))
      (print (list 'found? found-obj obj-pos)))
    obj-pos))))
  

;; subscribeして認識
;; (ros::subscribe *topic-name* jsk_recognition_msgs::BoundingBoxArray #'object-pose-cb 1)

(print 3)
(setq *cube* (make-cube 10 50 50))
(send *cube* :set-color :red)
(send *cube* :locate #f(500 0 1000) :world)
(objects (list *cube* *pr2*))

(warn "please run (recognition) or (transfer-all)~%")

(setq *end-flag* nil)
(setq *first-flag* t)
(setq *fail-flag* nil)

(defun recognition ()
  (setq found-obj nil)
  (setq cnt 0)
  (until found-obj
     (print 4)
     (x::window-main-one) ;; IRT viewerの視点を変えられる。見にくければ変えよう

     (setq msg (one-shot-subscribe *topic-name* jsk_recognition_msgs::BoundingBoxArray :timeout 2000))
     (when msg
       (object-pose-cb msg)

       ;; 中身が空なら抜ける
       (unless (send *msg* :boxes) 
         (progn
           (setq *end-flag* t)
           (return-from recognition)
           ))
       ;; 中身が0だったらカウントする
       (if (= width 0)
           (progn
         (setq cnt (+ cnt 1))
         ))
       ;; カウントが５以上になったら抜ける
       (if (>= cnt 5)
           (progn
           (setq *end-flag* t)
           (return-from recognition)
           ))
       )
     ;; メッセージが来ていなかったら抜ける
     (unless msg
       (progn
         (setq *end-flag* t)
         (return-from recognition)
         ))
     )

  
  ;; ikを解く
  (load "models/arrow-object.l")
  (setq *arrow* (arrow))
  (send *arrow* :newcoords (send obj-coord :copy-worldcoords))
  
  (setq *tar* (make-cube width length height))
  (send *tar* :newcoords (send obj-coord :copy-worldcoords))
  (send *tar* :rotate (deg2rad 180) :x)
  
  (objects (list *tar* *pr2* *cutting-board* *kitchen*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))
  (send *irtviewer* :draw-objects)
  
  (warn "please run (grasp-target) or (now-devel) ~%")
  )

(defun grasp-target ()
  (if *first-flag*
      (progn 
    ;;少し上に
    (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send *arrow* :translate #f(0 0 250) :world)
    (send *pr2* :larm :inverse-kinematics
          (send *arrow* :copy-worldcoords)
          :rotation-axis nil
          :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
    (send *ri* :wait-interpolation)
    
    ;;少し前に
    (send *arrow* :newcoords (make-coords :pos (send (send *pr2* :larm :end-coords) :worldpos)))
    (send *arrow* :translate #f(-200 50 50) :world)
    (send *arrow* :rotate (deg2rad 90) :z :world)
    (send *pr2* :larm :inverse-kinematics
          (send *arrow* :copy-worldcoords)
          :rotation-axis t
          :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
    (send *ri* :wait-interpolation)
    (setq *first-flag* nil)
    ))

  
  ;; 掴む所に
  (send *arrow* :newcoords (send *tar* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 90) :y)

  (send *arrow* :translate #f(-10 -20 0) :world)

  ;;gripperを開く
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;gripperを閉じる
  (send *ri* :start-grasp :larm :wait t)
  (send (send *pr2* :larm :end-coords) :assoc *tar*)
  ;; (send *ri* :start-grasp :larm :wait t :gain 0.05)

  ;; 掴めなかったらflagをtに
  (setq gripper-len (send *ri* :state :gripper :larm :position))
  (if (< gripper-len 10)
      (setq *fail-flag* t))
     
  (warn "please run  (put-target) ~%")
  )

(defun put-target ()
  ;; 左手を上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 位置に．
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 300.0 2050.0 1030) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0)))) ;; 300も良さげではあった．
  (send *arrow* :newcoords (send *micro-cup-put-coords* :copy-worldcoords))
  
  (send *arrow* :translate #f(0 0 30) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :move-target *tar*
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -30) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :move-target *tar*
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm)
  (send (send *pr2* :larm :end-coords) :dissoc *tar*)

  ;; 左手を上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run  (avoid-larm) ~%")
  )

(defun put-target-bowl-1 ()
  ;; 左手を上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 位置に．
  (send *arrow* :newcoords (send *bowl-1-put-coords* :copy-worldcoords))
  
  (send *arrow* :translate #f(0 0 30) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :move-target *tar*
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -30) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :move-target *tar*
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm)
  (send (send *pr2* :larm :end-coords) :dissoc *tar*)

  ;; 左手を上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run  (avoid-larm) ~%")
  )

(defun put-target-bowl-2 ()
  ;; 左手を上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 位置に．
  (send *arrow* :newcoords (send *bowl-2-put-coords* :copy-worldcoords))
  
  (send *arrow* :translate #f(0 0 30) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :move-target *tar*
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -30) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :move-target *tar*
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm)
  (send (send *pr2* :larm :end-coords) :dissoc *tar*)

  ;; 左手を上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run  (avoid-larm) ~%")
  )


(defun reset-larm ()
  ;; 少し上にして水平に
  (setq *angle-vector-1* #f(325.0 19.8423 -8.21823 103.656 -49.9233 -17.8074 -61.6826 -444.344 -75.9572 52.4233 -108.235 -109.764 -0.12391 -9.4595 8.93627 0.0 50.0))
  (send *pr2* :angle-vector *angle-vector-1*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手前にする
  (setq *angle-vector-2* #f(325.0 41.6856 -14.6471 88.8332 -81.5531 -11.5752 -49.6524 -454.261 -75.9572 52.4233 -108.235 -109.764 -0.12391 -9.4595 8.93627 0.0 50.0))
  (send *pr2* :angle-vector *angle-vector-2*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq *angle-vector-3* #f(325.0 44.2075 -13.6922 86.5799 -85.3975 -9.44283 -48.0339 -455.926 -75.9572 52.4233 -108.235 -109.764 -0.12391 -9.4595 8.93627 0.0 50.0))
  (send *pr2* :angle-vector *angle-vector-3*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)


  (setq *angle-vector-4* #f(325.0 75.9096 52.2991 108.325 -109.775 -0.931123 -9.46065 -403.181 -75.9572 52.4233 -108.235 -109.764 -0.12391 -9.4595 8.93627 0.0 50.0))
  (send *pr2* :angle-vector *angle-vector-4*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


(defun avoid-larm ()
  ;; 少し上にして水平に
  (setq *lav1* #f(3.90826 -19.7839 166.352 -51.2831 -79.3544 -82.7576 -59.6161))
  (send *pr2* :larm :angle-vector *lav1*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  
  ;; 手前にする
  (setq *lav2* #f(45.918 -19.9401 104.684 -121.15 -182.857 -72.0687 66.4371))
  (send *pr2* :larm :angle-vector *lav2*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  

  (warn "please run (recognition) ~%")
  )

(defun return-larm ()
  ;; 左手を少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (avoid-larm)
  )



(defun transfer-all ()
  (recognition)
  (until *end-flag*
     (grasp-target)
     (put-target)
     (avoid-larm)
     (recognition)
     )
  )


(defun now-transfer ()
  (setq *end-flag* nil)
  (recognition)
  (until *end-flag*
     (setq *fail-flag* nil)
     (grasp-target)
     (if (eql *fail-flag* nil)
         (progn
           (put-target)
           (avoid-larm)
           (recognition))
       (progn
         (return-larm)
         (recognition))
       )
     )
  )

(defun now-transfer-bowl-1 ()
  (setq *end-flag* nil)
  (recognition)
  (until *end-flag*
     (setq *fail-flag* nil)
     (grasp-target)
     (if (eql *fail-flag* nil)
         (progn
           (put-target-bowl-1)
           (avoid-larm)
           (recognition))
       (progn
         (return-larm)
         (recognition))
       )
     )
  )

(defun now-transfer-bowl-2 ()
  (setq *end-flag* nil)
  (recognition)
  (until *end-flag*
     (setq *fail-flag* nil)
     (grasp-target)
     (if (eql *fail-flag* nil)
         (progn
           (put-target-bowl-2)
           (avoid-larm)
           (recognition))
       (progn
         (return-larm)
         (recognition))
       )
     )
  )



(defun now-devel ()
  (recognition)
  (grasp-target)
  (put-target)
  (avoid-larm)
  (recognition)
  )


(defun now-test ()
  (recognition)
  (until *end-flag*
     (grasp-target)
     (put-target)
     (avoid-larm)
     (recognition)
     )
  )


(defun exec-all ()
  (recognition)
  (until *end-flag*
     (grasp-target)
     (put-target)
     (avoid-larm)
     (recognition)
     )
  )
