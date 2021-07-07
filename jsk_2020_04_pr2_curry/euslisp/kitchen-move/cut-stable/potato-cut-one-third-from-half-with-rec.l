(defun init ()
  (if (not (boundp '*room*))
      (progn
        (load "../../model/my-room73b2-scene.l")
        (setq *room* (room73b2))
        ))
    
  (if (not (boundp '*kitchen*))
      (progn 
        (load "models/room73b2-kitchen-object.l")
        (setq *kitchen* (room73b2-kitchen))
        (send *kitchen* :transform (make-coords :pos (float-vector 305.0 2175.0 20.0) :rot #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))))
        ))

  (if (not (boundp '*pr2*))
      (progn
        (load "package://pr2eus/pr2-interface.l")
        (pr2-init)
        ))

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

  ;; 調整用
  (setq adj 0)

  ;; set potato
  ;; (load "../../model/potato-new-type.l")
  (load "../../model/potato-half-model.l")

  (setq width 90)
  (setq length 60)
  (setq height 60)
  )

(init)


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
      obj-pos)))

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

  (x::window-main-one) ;; IRT viewerの視点を変えられる。見にくければ変えよう
  (ros::spin-once)
  (ros::sleep)
  )


;; ikを解く
(load "models/arrow-object.l")
(setq *arrow* (arrow))
(send *arrow* :newcoords (send obj-coord :copy-worldcoords))

;; (load "../../model/potato-new-type.l")
(load "../../model/potato-half-model.l")

(setq hoge width)
(setq width (+ (* height 2) 30))
(setq height hoge)

(setq *potato* (potato :w  width :l length :h height))
(send *potato* :newcoords (send obj-coord :copy-worldcoords))

(send *potato* :rotate (deg2rad 180) :x)
(send *potato* :cut)

(send p4 :dissoc p7)
(send p7 :translate #f(0 0 -100) :world)
(send p4 :dissoc p8)
(send p8 :translate #f(0 0 -100) :world)  

(send p4 :dissoc p1)

(send p4 :translate #f(0 0 -100) :world)
(send *viewer* :draw-objects)

;; (send p1 :rotate (deg2rad 90) :x :world)
(send p1 :rotate (deg2rad -90) :y)
(send p1 :translate (float-vector 0 0 (* -0.25 (- width 30))) :world)


(objects (list *potato* *pr2* *cutting-board* *kitchen*))
(send *irtviewer* :look-all
      (geo::make-bounding-box 
       (flatten (send-all (send *pr2* :bodies) :vertices))))
(send *irtviewer* :draw-objects)

(warn "please run  (set-knife-hor) or (grasp-knife-hor) ~%")

(defun set-knife-hor ()
  (setq *knife* (knife))
  (send *knife* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *knife* :translate #f(12 0 0))
  (send *knife* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *knife*)

  (objects (list *kitchen* *pr2* *cutting-board* *potato* *knife*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (cut-test-4) ~%")
  )

(defun grasp-knife-hor ()

  ;; grasp knife
  (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :speak-jp "包丁を握らせて下さい")
  (unix:sleep s-time)
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  
  (setq *knife* (knife))
  (send *knife* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *knife* :translate #f(12 0 0))
  (send *knife* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *knife*)

  (objects (list *kitchen* *pr2* *cutting-board* *potato* *knife*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (cut-test-4) ~%")
  )

(defun cut-test-4 ()
  (if (not (boundp '*potato*))
      (set-potato :w width :l length :h height))

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
  (send *arrow* :newcoords (send *cut-point-4* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 (* height 0.5)))

  ;;調整
  (send *arrow* :translate (float-vector 0 adj 0))

  ;; 少し上にするために
  (setq offset 50)
 
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
  (dotimes (i (+ (round (/ (* height 0.5) interval)) 1))
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

    (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    
    )
  
  (warn "you can retry (cut-test-4), (continue-cut 4) or you want to finish please run (finish-pose-4)  ~%")
  )

(defun cut-test-5 ()
  (if (not (boundp '*potato*))
      (set-potato :w width :l length :h height))

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
  (send *arrow* :newcoords (send *cut-point-5* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 (* height 0.5)))

  ;;調整
  (send *arrow* :translate (float-vector 0 adj 0))

  ;; 少し上にするために
  (setq offset 50)
 
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
  (dotimes (i (+ (round (/ (* height 0.5) interval)) 1))
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

    (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    
    )
  
  (warn "you can retry (cut-test-5), (continue-cut 4) or you want to finish please run (finish-pose-5)  ~%")
  )

(defun continue-cut (num)
  (setq interval 10)
  (dotimes (i num)
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
    (send *ri* :wait-interpolation))
  (warn "you can retry (cut-test), (continue-cut 4) or you want to finish please run (finish-pose-4)  ~%")
  )

(defun finish-pose ()
  (send *pr2* :angle-vector (send *ri* :state :potantio-vector))
  
  ;; 包丁を上に上げる
  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector -30 30 50) :world)
  (send *pr2* :rarm :inverse-kinematics
        *arrow*
        :move-target (car (send *knife* :attention))
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 50) :world)
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 50) :world)
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  )

(defun finish-pose-4 ()
  (finish-pose)
  (warn "please run (cut-test-5)~%")  
  )

(defun finish-pose-5 ()
  (finish-pose)

  (setq *rav1* #f(-16.0652 5.94641 -77.1102 -121.467 184.962 -106.138 -192.692))
  (send *pr2* :rarm :angle-vector *rav1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (setq *rav2* #f(-30.0303 1.63624 -169.166 -116.783 100.843 -98.3015 -58.1037))
  (send *pr2* :rarm :angle-vector *rav2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun now-devel ()
  ;; (set-potato :w width :l length :h height)
  (grasp-knife-hor)
  (cut-test-4)
  (finish-pose-4)
  (cut-test-5)
  (finish-pose-5)
  )



(defun now-test ()
  ;; (set-potato :w width :l length :h height)
  (set-knife-hor)
  (cut-test-4)
  (finish-pose-4)
  (cut-test-5)
  (finish-pose-5)
  )


(defun exec-all ()
  ;; (set-potato :w width :l length :h height)
  (grasp-knife-hor)
  (cut-test-4)
  (finish-pose-4)
  (cut-test-5)
  (finish-pose-5)
  )
