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
  (send *cutting-board* :transform (make-coords :pos (float-vector 500.0 2000.0 840.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))

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

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (objects (list *pr2* *cutting-board*))

  ;; def global values
  (setq s-time 3)

  ;; (setq adj 10)
  (setq adj 0)

  (setq adj2 0)

  ;; 掴む力
  (setq gf 0.1)

  ;; set carrot
  (load "../../model/carrot-ellipsoid-model.l")
  ;; (load "../../model/carrot-test-new-type.l")

  (setq width 150)
  (setq length 40)
  (setq height 40)
  )

(init)


;; トピックなどを定義
(setq *topic-name* "/segmentation_decomposer/boxes")

;; ros init
(ros::roseus "carrot_rec_test" :anonymous t)
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
      (if (= width 0)
      (return-from object-pose-cb))
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
(ros::unsubscribe *topic-name*)
;; (ros::subscribe *topic-name* jsk_recognition_msgs::BoundingBoxArray #'object-pose-cb 1)
(setq *b* (instance ros::transform-broadcaster :init))

(print 3)
(setq *cube* (make-cube 10 50 50))
(send *cube* :set-color :red)
(send *cube* :locate #f(500 0 1000) :world)
(objects (list *cube* *pr2*))

(setq found-obj nil)
(until found-obj
  (print 4)

  (x::window-main-one) ;; IRT viewerの視点を変えられる。見にくければ変えよう

  (setq msg (one-shot-subscribe *topic-name* jsk_recognition_msgs::BoundingBoxArray))
  (object-pose-cb msg)
  
  ;; (ros::spin-once)
  ;; (ros::sleep)
  )


;; ikを解く
(load "models/arrow-object.l")
(setq *arrow* (arrow))
(send *arrow* :newcoords (send obj-coord :copy-worldcoords))

(load "../../model/carrot-ellipsoid-model.l")
(setq *carrot* (carrot :w  width :l length :h height))
(send *carrot* :newcoords (send obj-coord :copy-worldcoords))
;; (send *carrot* :translate (float-vector (- (/ width 2) 20) 0 0))
(send *carrot* :rotate (deg2rad 180) :x)
;; (send *carrot* :cut)
(objects (list *carrot* *pr2* *cutting-board* *kitchen*))
(send *irtviewer* :look-all
      (geo::make-bounding-box 
       (flatten (send-all (send *pr2* :bodies) :vertices))))
(send *irtviewer* :draw-objects)

(setq interval height)

;; add for sense

;; (setq *y-thre* -12)
(setq *y-thre* -10)

(setq *topic-name* "/right_endeffector/wrench")
(ros::load-ros-manifest "geometry_msgs")
(setq *cb-flag* nil)
(defun wrench-y-cb (msg)
  (when msg
    (let ((y nil))
      (setq y (send msg :wrench :force :y))
      (if (< y *y-thre*)
          (progn 
            (setq *cb-flag* t)
            (format t "OK!! y: ~A ~%" y)
            )
        (format t "y: ~A ~%" y))
      )))


;; add for rosservice
(ros::load-ros-manifest "std_srvs")
(ros::wait-for-service "after_stow_data_collection/save_request")
(setq req (instance std_srvs::TriggerRequest :init))


(defun rossrv-test ()
  (setq res (ros::service-call "after_stow_data_collection/save_request" req t))
  )


(warn "please run (grasp-carrot-peel) or (now-devel)~%")

(defun grasp-carrot-peel ()
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
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate #f(-200 50 50) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; 人参の掴む所に
  (send *arrow* :newcoords (send *carrot* :copy-worldcoords))
  (send *arrow* :translate #f(-30 0 0))

  (send *arrow* :rotate (deg2rad 45) :y)

  (send *arrow* :translate #f(-10 -15 -5) :world)
  
  ;;gripperを開く
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate #f(0 -100 100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 100 -100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;gripperを閉じる
  (send *ri* :start-grasp :larm :wait t)
  (send (send *pr2* :larm :end-coords) :assoc *carrot*)
  ;; (send *ri* :start-grasp :larm :wait t :gain 0.05)

  (send *ri* :start-grasp :larm :wait t :gain gf)
     
  ;; (warn "please run  (set-carrot-1) ~%")
  (warn "please run  (set-peeler) or (grasp-peeler) ~%")

  ;; 掴めなかったらflagをtに
  (setq gripper-len (send *ri* :state :gripper :larm :position))
  (if (< gripper-len 10)
      (progn 
    (setq *fail-flag* t)
    (reset-larm)
    ))

  )

(defun set-carrot ()
  ;; 左手を上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 50) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 人参を位置に．
  (send *pr2* :larm :inverse-kinematics
    (send *c-arrow* :copy-worldcoords)
    :move-target *carrot*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun before-set ()
  ;; 左手を上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 50) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun set-peeler ()
  ;; ピーラーをセットする．
  (setq *peeler* (peeler))
  (send *peeler* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *peeler* :translate #f(15 0 0))
  (send *peeler* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *peeler*)

  (objects (list *kitchen* *pr2* *cutting-board* *carrot* *peeler*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (peel-test) ~%")
  )

(defun grasp-peeler ()
  ;; ピーラーを握る
  (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :speak-jp "ピーラーを握らせて下さい")
  (unix:sleep s-time)
  (send *ri* :start-grasp :rarm :wait t :gain 100)

  (setq *peeler* (peeler))
  (send *peeler* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *peeler* :translate #f(15 0 0))
  (send *peeler* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *peeler*)

  (objects (list *kitchen* *pr2* *cutting-board* *carrot* *peeler*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (peel-test) ~%")
  )

(defun peel-test ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :head :look-at (send (send *pr2* :larm :end-coords) :worldpos))
  (send *ri* :angle-vector (send *pr2* :angle-vector))

  ;; 右手を上げる
  (setq *c* (make-coords))
  (send *c* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *c* :translate #f(0 0 200) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *c* :copy-worldcoords)
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 剥く位置
  (send *c* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *c* :translate #f(0 20 0) :world)
  (send *c* :rotate (deg2rad -90) :z :world)

  (send *c* :translate (float-vector 0 0 (* 1 height)) :world)
  (send *c* :rotate (deg2rad 30) :y)
  (send *c* :translate (float-vector 0 80 80) :world)

  ;;調整
  (send *c* :translate (float-vector 0 adj 0))

  (send *c* :translate (float-vector adj2 0 0))

  (send *pr2* :rarm :inverse-kinematics
    *c*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *c* :translate (float-vector 0 -80 -80) :world)
  (send *pr2* :rarm :inverse-kinematics
    *c*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 皮剥き始める所
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  ;; (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)

  (until *cb-flag*
    (send *c* :translate (float-vector 0 0 (* 10 -1)) :world)
    (send *pr2* :rarm :inverse-kinematics
        *c*
      :move-target (car (send *peeler* :attention))
        :rotation-axis t
        :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)

    (setq msg (one-shot-subscribe *topic-name* geometry_msgs::WrenchStamped))
    (wrench-y-cb msg)
    
    ;; (ros::spin-once)
    ;; (ros::sleep)
    )

  ;; 剥き終わり
  (send *c* :rotate (deg2rad -30) :y)
  (send *c* :translate (float-vector (* (+ width 20) -1) 0 0) )
  (send *c* :rotate (deg2rad 30) :y)

  (send *pr2* :rarm :inverse-kinematics
    *c*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "you can retry (peel-test) or (finish-pose-peel) , (set-carrot-2)~%")
  )

(defun peel-test2 ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :head :look-at (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos))
  (send *ri* :angle-vector (send *pr2* :angle-vector))

  ;; 右手を上げる
  (setq *c* (make-coords))
  (send *c* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *c* :translate #f(0 0 200) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *c* :copy-worldcoords)
        :rotation-axis nil
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 剥く位置
  (send *c* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *c* :translate #f(0 15 0) :world)
  (send *c* :rotate (deg2rad -90) :z :world)

  (send *c* :translate (float-vector 0 0 (* 1 height)) :world)
  (send *c* :rotate (deg2rad 30) :y)
  (send *c* :translate (float-vector 0 80 80) :world)

  ;;調整
  (send *c* :translate (float-vector 0 adj 0))

  (send *c* :translate (float-vector adj2 0 0))

  (send *pr2* :rarm :inverse-kinematics
        *c*
        :move-target (car (send *peeler* :attention))
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *c* :translate (float-vector 0 -80 -80) :world)
  (send *pr2* :rarm :inverse-kinematics
        *c*
        :move-target (car (send *peeler* :attention))
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 皮剥き始める所
  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)

  ;; arm が接触するか、一定距離動かす
  (send *c* :translate (float-vector 0 0 (- (* height -1) 10)) :world)
  (send *pr2* :rarm :inverse-kinematics
        *c*
        :move-target (car (send *peeler* :attention))
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)

  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
            (ros::spin-once)
            (if *cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      
      ;; 剥き終わり
      (send *c* :rotate (deg2rad -30) :y)
      (send *c* :translate (float-vector (* (+ width 20) -1) 0 0) )
      (send *c* :rotate (deg2rad 30) :y)
      
      (send *pr2* :rarm :inverse-kinematics
            *c*
            :move-target (car (send *peeler* :attention))
            :rotation-axis t
            :debug-view t)
      (send *viewer* :draw-objects)
      (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
      (send *ri* :wait-interpolation)

      (ros::unsubscribe "/right_endeffector/wrench")
      
      (warn "you can retry (peel-test) or (finish-pose-peel) , (set-carrot-2)~%")
      (return-from peel-test2 t))
    )

  ;; 剥き終わり
  (send *c* :rotate (deg2rad -30) :y)
  (send *c* :translate (float-vector (* (+ width 20) -1) 0 0) )
  (send *c* :rotate (deg2rad 30) :y)
  
  (send *pr2* :rarm :inverse-kinematics
        *c*
        :move-target (car (send *peeler* :attention))
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (ros::unsubscribe "/right_endeffector/wrench")

  (warn "fail cancel !! ~%")
  (warn "you can retry (peel-test) or (finish-pose-peel) , (set-carrot-2)~%")
  )

(defun peel-test4 ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :head :look-at (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos))
  (send *ri* :angle-vector (send *pr2* :angle-vector))

  ;; 右手を上げる
  (setq *c* (make-coords))
  (send *c* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *c* :translate #f(0 0 200) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *c* :copy-worldcoords)
        :rotation-axis nil
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 剥く位置
  (send *c* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *c* :translate #f(0 15 0) :world)
  (send *c* :rotate (deg2rad -90) :z :world)

  (send *c* :translate (float-vector 0 0 (* 1 height)) :world)
  (send *c* :rotate (deg2rad 30) :y)
  (send *c* :translate (float-vector 0 80 80) :world)

  ;;調整
  (send *c* :translate (float-vector 0 adj 0))

  (send *c* :translate (float-vector adj2 0 0))

  (send *pr2* :rarm :inverse-kinematics
        *c*
        :move-target (car (send *peeler* :attention))
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *c* :translate (float-vector 0 -80 -80) :world)
  (send *pr2* :rarm :inverse-kinematics
        *c*
        :move-target (car (send *peeler* :attention))
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 皮剥き始める所
  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)

  (setq interval 10)

  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i (+ (round (/ (* height 2) interval)) 1))
    (send *c* :translate (float-vector 0 0 (* interval -1)) :world)
    (send *pr2* :rarm :inverse-kinematics
          *c*
          :move-target (car (send *peeler* :attention))
          :rotation-axis t
          :debug-view nil)

    (setq av (send *pr2* :angle-vector))

    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )

  (send *ri* :angle-vector-sequence avs tms)
  
  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
            (ros::spin-once)
            (if *cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
          
      ;; 剥き終わり
      (send *c* :rotate (deg2rad -30) :y)
      (send *c* :translate (float-vector (* (+ width 20) -1) 0 0) )
      (send *c* :rotate (deg2rad 30) :y)
      
      (send *pr2* :rarm :inverse-kinematics
            *c*
            :move-target (car (send *peeler* :attention))
            :rotation-axis t
            :debug-view t)
      (send *viewer* :draw-objects)
      (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
      (send *ri* :wait-interpolation)

      (ros::unsubscribe "/right_endeffector/wrench")
      
      (warn "you can retry (peel-test) or (finish-pose-peel) , (set-carrot-2)~%")
      (return-from peel-test4 t))
    )

  ;; 剥き終わり
  (send *c* :rotate (deg2rad -30) :y)
  (send *c* :translate (float-vector (* (+ width 20) -1) 0 0) )
  (send *c* :rotate (deg2rad 30) :y)
  
  (send *pr2* :rarm :inverse-kinematics
        *c*
        :move-target (car (send *peeler* :attention))
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (ros::unsubscribe "/right_endeffector/wrench")

  (warn "fail cancel !! ~%")
  (warn "you can retry (peel-test) or (finish-pose-peel) , (set-carrot-2)~%")
  )


(defun touch-test-set ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :head :look-at (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos))
  (send *ri* :angle-vector (send *pr2* :angle-vector))

  ;; 右手を上げる
  (setq *c* (make-coords))
  (send *c* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *c* :translate #f(0 0 200) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *c* :copy-worldcoords)
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 剥く位置
  (send *c* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *c* :translate #f(0 15 0) :world)
  (send *c* :rotate (deg2rad -90) :z :world)

  (send *c* :translate (float-vector 0 0 (* 1 height)) :world)
  (send *c* :rotate (deg2rad 30) :y)
  (send *c* :translate (float-vector 0 80 80) :world)

  ;;調整
  (send *c* :translate (float-vector 0 adj 0))

  (send *c* :translate (float-vector adj2 0 0))

  (send *pr2* :rarm :inverse-kinematics
    *c*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *c* :translate (float-vector 0 -80 -80) :world)
  (send *pr2* :rarm :inverse-kinematics
    *c*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (touch-test) or (touch-test-2) ~%")
  )

(defun touch-test ()

  ;; 皮剥き始める所
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  ;; (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)

  (until *cb-flag*
    (send *c* :translate (float-vector 0 0 (* 10 -1)) :world)
    (send *pr2* :rarm :inverse-kinematics
        *c*
      :move-target (car (send *peeler* :attention))
        :rotation-axis t
        :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)

    (setq msg (one-shot-subscribe *topic-name* geometry_msgs::WrenchStamped))
    (wrench-y-cb msg)
    
    ;; (ros::spin-once)
    ;; (ros::sleep)
    )

  (warn "please run (finish-touch) or (exec-peel)~%")
  )

(defun touch-test-2 ()

  ;; 皮剥き始める所
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)

  ;; arm が接触するか、一定距離動かす
  (send *c* :translate (float-vector 0 0 (- (* height -1) 10)) :world)
  (send *pr2* :rarm :inverse-kinematics
        *c*
        :move-target (car (send *peeler* :attention))
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)

  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
            (ros::spin-once)
            (if *cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      
      (warn "please run (finish-touch) or (exec-peel)~%")
      (return-from touch-test-2 t))
    )

  (warn "cancel fail! ~%")
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      
  (warn "please run (finish-touch) or (exec-peel)~%")
  )

(defun finish-touch ()
  ;; 手を少し上に
  (setq *c* (make-coords))
  (send *c* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *c* :translate #f(0 0 150) :world)
  (send *pr2* :rarm :inverse-kinematics
      (send *c* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *c* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *c* :translate #f(0 150 0) :world)
  (send *pr2* :rarm :inverse-kinematics
      (send *c* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run  (set-carrot-2)~%")
  )

(defun exec-peel ()
  ;; 剥き終わり
  (send *c* :rotate (deg2rad -30) :y)
  (send *c* :translate (float-vector (* (+ width 20) -1) 0 0) )
  (send *c* :rotate (deg2rad 30) :y)

  (send *pr2* :rarm :inverse-kinematics
    *c*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "you can retry (peel-test) or (finish-pose-peel) , (set-carrot-2)~%")
  )

(defun set-carrot-1 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  ;; (set-carrot)

  (before-set)
  (setq *cav1* #f(22.3152 -20.2206 104.497 -67.2575 27.1601 -58.4014 241.489))
  (send *pr2* :larm :angle-vector *cav1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (rossrv-test)
  (warn "please run  (set-carrot-1-2) ~%")  
  )

(defun set-carrot-1-2 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 500.0 2000.0 (+ 850.0 (/ height 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  ;; (set-carrot)

  (before-set)
  ;; (setq *cav1-2* #f(14.9432 6.73849 101.458 -45.16 41.7268 -59.5005 257.077))
  (setq *cav1-2* #f(22.2375 6.99489 100.811 -44.1724 41.1502 -65.4659 263.167))
  (send *pr2* :larm :angle-vector *cav1-2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  (warn "please run  (peel-test-1) ~%")  
  )

(defun peel-test-1 ()
  (peel-test4)
  (rossrv-test)
  (warn "please run  (set-carrot-1) ~%")  
  )

(defun set-carrot-2 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 45) :y :world)
  ;; (set-carrot)

  (before-set)
  (setq *cav2* #f(29.8664 -13.2655 93.323 -89.495 84.5614 -27.1668 225.645))
  (send *pr2* :larm :angle-vector *cav2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (rossrv-test)
  (warn "please run  (peel-test-2) ~%")  
  )

(defun peel-test-2 ()
  (peel-test4)
  (rossrv-test)
  (warn "please run  (set-carrot-3) ~%")  
  )

(defun set-carrot-3 ()
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 90) :y :world)
  ;; (set-carrot)

  (before-set)
  (setq *cav3* #f(28.6469 21.8904 67.0654 -99.0555 145.509 -29.3133 238.125))
  (send *pr2* :larm :angle-vector *cav3*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (rossrv-test)
  (warn "please run  (peel-test-3) ~%")  
  )

(defun peel-test-3 ()
  (peel-test4)
  (rossrv-test)
  (warn "please run  (set-carrot-4) ~%")  
  )

(defun set-carrot-4 ()
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 135) :y :world)
  ;; (set-carrot)

  (before-set)
  (setq *cav4* #f(26.0117 33.9343 63.1475 -89.1481 -16.6711 -10.7218 446.063))
  (send *pr2* :larm :angle-vector *cav4*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (rossrv-test)
  (warn "please run  (peel-test-4) ~%")  
  )

(defun peel-test-4 ()
  (peel-test4)
  (rossrv-test)
  (warn "please run  (set-carrot-5) ~%")  
  )

(defun set-carrot-5 ()
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad -45) :y :world)
  ;; (set-carrot)

  (before-set)
  (setq *cav5* #f(11.4967 -14.8606 117.229 -40.0273 0.832231 -97.5426 585.576))
  (send *pr2* :larm :angle-vector *cav5*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (rossrv-test)
  (warn "please run  (peel-test-5) ~%")  
  )

(defun peel-test-5 ()
  (peel-test4)
  (rossrv-test)
  (warn "please run  (set-carrot-6) ~%")  
  )

(defun set-carrot-6 ()
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad -90) :y :world)
  ;; (set-carrot)

  (before-set)
  (setq *cav6* #f(8.78136 0.997566 91.3453 -28.5004 0.010485 -114.592 541.679))
  (send *pr2* :larm :angle-vector *cav6*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (rossrv-test)
  (warn "please run  (peel-test-6) ~%")  
  )

(defun peel-test-6 ()
  (peel-test4)
  (rossrv-test)
  (warn "please run  (set-carrot-7) ~%")  
  )

(defun set-carrot-7 ()
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad -135) :y :world)
  ;; (set-carrot)

  (before-set)
  (setq *cav7* #f(8.34967 -3.13322 134.846 -38.6712 -63.4229 -113.639 519.101))
  (send *pr2* :larm :angle-vector *cav7*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (rossrv-test)
  (warn "please run  (peel-test-7) ~%")  
  )

(defun peel-test-7 ()
  (peel-test4)
  (rossrv-test)
  (warn "please run  (set-carrot-8) ~%")  
  )

(defun set-carrot-8 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 180) :y :world)
  ;; (set-carrot)

  (before-set)
  (setq *cav8* #f(18.3182 -2.39234 124.222 -66.2168 -76.2232 -86.4503 500.063))
  (send *pr2* :larm :angle-vector *cav8*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (rossrv-test)
  (warn "please run  (peel-test-8) ~%")  
  )

(defun peel-test-8 ()
  (peel-test4)
  (rossrv-test)
  (warn "please run  (finsih-pose-peel) ~%")  
  )

(defun finish-pose-peel ()
  ;; 手を少し上に
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(100 0 150) :world)
  (send *pr2* :rarm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; set pose
  (send *arrow* :newcoords (make-coords :pos #f(800.191 2189.104 866.677) :rpy #f(-2.341 -0.222 -0.482)))
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)

  (warn "please run (put-carrot)~%")
  )

(defun put-carrot ()
  (send *pr2* :larm :end-coords :assoc *carrot*)

  ;; 置く
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 500.0 2000.0 (+ 850.0 (/ height 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  
  (send *c-arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *c-arrow* :copy-worldcoords)
    :move-target *carrot*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *c-arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *c-arrow* :copy-worldcoords)
    :move-target *carrot*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; release carrot
  (send *pr2* :larm :end-coords :dissoc *carrot*)
  (send *ri* :stop-grasp :larm :wait t)

  (warn "please run (reset-larm)~&")
  )

(defun regrasp-carrot ()
  (send *pr2* :larm :end-coords :assoc *carrot*)

  ;; 置く
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 500.0 2000.0 (+ 850.0 (/ height 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  
  (send *c-arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *c-arrow* :copy-worldcoords)
        :move-target *carrot*
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *c-arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *c-arrow* :copy-worldcoords)
        :move-target *carrot*
        :rotation-axis t
        :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; release carrot
  (send *pr2* :larm :end-coords :dissoc *carrot*)
  (send *ri* :stop-grasp :larm :wait t)

  ;; regrasp carrot
  (send *pr2* :larm :end-coords :assoc *carrot*)
  (send *ri* :start-grasp :larm :wait t)

  (send *ri* :start-grasp :larm :wait t :gain 0.1)

  ;; set carrot
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 500.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (set-carrot)
  
  (warn "please run (set-carrot-2)~&")
  )

(defun reset-larm ()
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

  ;; 少し上にして水平に
  (send *arrow* :newcoords (make-coords :pos (send *arrow* :worldpos)))
  (send *arrow* :translate #f(0 0 50) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手前にする
  (send *arrow* :newcoords (make-coords :pos (send (send *pr2* :larm :end-coords) :worldpos)))
  (send *arrow* :translate #f(140 -100 90) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos #f(800.191 1810.896 866.677) :rpy #f(2.341 -0.222 -0.133)))
  (send *pr2* :larm :inverse-kinematics
    *arrow*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 8000)
  (send *ri* :wait-interpolation)  
  )


(defun check-carrot-1 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (set-carrot)
  (warn "please run (set-carrot-1-2) or (check-carrot-2) ~%")  
  )

(defun check-carrot-2 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 30) :y :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-3) ~%")  
  )

(defun check-carrot-3 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 60) :y :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-4) ~%")  
  )

(defun check-carrot-4 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 90) :y :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-5) ~%")  
  )

(defun check-carrot-5 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 120) :y :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-6) ~%")  
  )

(defun check-carrot-6 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 150) :y :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-7) ~%")  
  )

(defun check-carrot-7 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 180) :y :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-8) ~%")  
  )

(defun check-carrot-8 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 210) :y :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-9) ~%")  
  )

(defun check-carrot-9 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 240) :y :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-10) ~%")  
  )

(defun check-carrot-10 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 270) :y :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-11) ~%")  
  )

(defun check-carrot-11 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 300) :y :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-12) ~%")  
  )

(defun check-carrot-12 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *c-arrow* :rotate (deg2rad 330) :y :world)
  (set-carrot)
  (warn "please run (peel-test) or (put-carrot) ~%")  
  )



(defun fail-check ()
  (setq *fail-flag* nil)
  (setq gripper-len (send *ri* :state :gripper :larm :position))
  (if (< gripper-len 10)
      (setq *fail-flag* t))
  )


(defun now-devel ()
  ;; (set-carrot-peel :w width :l length :h height)
  (grasp-carrot-peel)
  (set-carrot-1)
  (grasp-peeler)
  (peel-test)
  (set-carrot-2)
  (peel-test-2)
  (set-carrot-3)
  (peel-test-3)
  (set-carrot-4)
  (peel-test-4)
  (set-carrot-5)
  (peel-test-5)
  (set-carrot-6)
  (peel-test-6)
  (set-carrot-7)
  (peel-test-7)
  (set-carrot-8)
  (peel-test-8)

  (finish-pose-peel)
  (put-carrot)
  (reset-larm)
  )



(defun now-test ()
  (grasp-carrot-peel)
  (set-peeler)
  (set-carrot-1)
  (set-carrot-2)
  (peel-test4)
  (set-carrot-3)
  (peel-test4)
  (set-carrot-4)
  (peel-test4)
  (set-carrot-5)
  (peel-test4)
  (set-carrot-6)
  (peel-test4)
  (set-carrot-7)
  (peel-test4)
  (set-carrot-8)
  (peel-test4)

  (finish-pose-peel)
  (put-carrot)
  (reset-larm)
  )

(defun now-peel ()
  (grasp-carrot-peel)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
    (reset-larm)
    (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/carrot-fail-set.l")
    (now-set)
    (return-from now-peel)))
  (set-carrot-1)
  (set-carrot-1-2)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
    (reset-larm)
    (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/carrot-fail-set.l")
    (now-set)
    (return-from now-peel)))
  (set-peeler)
  (setq adj (+ adj 10))
  (peel-test-1)
  (setq adj (- adj 10))
  (set-carrot-1)
  (set-carrot-2)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
    (reset-larm)
    (finish-pose-peel)
    (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/carrot-fail-set.l")
    ;; (load "carrot-fail-set.l")
    (now-set)
    (return-from now-peel)))
  (peel-test-2)
  (set-carrot-3)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
    (reset-larm)
    (finish-pose-peel)
    (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/carrot-fail-set.l")
    ;; (load "carrot-fail-set.l")
    (now-set)
    (return-from now-peel)))
  (peel-test-3)
  (set-carrot-4)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
    (reset-larm)
    (finish-pose-peel)
    (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/carrot-fail-set.l")
    (now-set)
    (return-from now-peel)))
  (peel-test-4)
  (set-carrot-5)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
    (reset-larm)
    (finish-pose-peel)
    (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/carrot-fail-set.l")
    (now-set)
    (return-from now-peel)))
  (peel-test-5)
  (set-carrot-6)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
    (reset-larm)
    (finish-pose-peel)
    (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/carrot-fail-set.l")
    (now-set)
    (return-from now-peel)))
  (peel-test-6)
  (set-carrot-7)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
    (reset-larm)
    (finish-pose-peel)
    (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/carrot-fail-set.l")
    (now-set)
    (return-from now-peel)))
  (peel-test-7)
  (set-carrot-8)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
    (reset-larm)
    (finish-pose-peel)
    (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/carrot-fail-set.l")
    (now-set)
    (return-from now-peel)))
  (peel-test-8)

  (finish-pose-peel)
  (put-carrot)
  (reset-larm)
  )

(defun now-peel-old ()
  (grasp-carrot-peel)
  (fail-check)
  (set-carrot-1)
  (set-carrot-1-2)
  (set-peeler)
  (setq adj (+ adj 10))
  (peel-test4)
  (setq adj (- adj 10))
  (set-carrot-1)
  (set-carrot-2)
  (peel-test4)
  (set-carrot-3)
  (peel-test4)
  (set-carrot-4)
  (peel-test4)
  (set-carrot-5)
  (peel-test4)
  (set-carrot-6)
  (peel-test4)
  (set-carrot-7)
  (peel-test4)
  (set-carrot-8)
  (peel-test4)

  (finish-pose-peel)
  (put-carrot)
  (reset-larm)
  )


(defun exec-all ()
  ;; (set-carrot-peel :w width :l length :h height)
  (grasp-carrot-peel)
  (set-carrot-1)
  (grasp-peeler)
  (peel-test)
  (set-carrot-2)
  (peel-test-2)
  (set-carrot-3)
  (peel-test-3)
  (set-carrot-4)
  (peel-test-4)
  (set-carrot-5)
  (peel-test-5)
  (set-carrot-6)
  (peel-test-6)
  (set-carrot-7)
  (peel-test-7)
  (set-carrot-8)
  (peel-test-8)

  (finish-pose-peel)
  (put-carrot)
  (reset-larm)
  )
