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

  (objects (list *pr2* *cutting-board*))

  ;; def global values
  (setq s-time 3)

  (setq adj 10)
  ;; (setq adj 0)

  (setq adj2 0)

  ;; set carrot
  (load "../../model/carrot-ellipsoid-model.l")
  ;; (load "../../model/carrot-test-new-type.l")

  (setq width 150)
  (setq length 40)
  (setq height 40)
  )

(init)


(ros::roseus "carrot_rec_test" :anonymous t)




(setq *y-thre* -12)

;; add for sense
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


(warn "please run (set-carrot-peel :w 150 :l 40 :h 40) or (now-devel)~%")

(defun set-carrot-peel (&rest args &key (w 150) (l 40) (h 40) &allow-other-keys)

  (setq width w)
  (setq length l)
  (setq height h)
  
  (setq *carrot* (carrot :w w :l l :h h))
  (send *carrot* :transform (make-coords :pos (float-vector 500.0 2000.0 (+ 850.0 (/ h 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  ;; (send *carrot* :cut)

  ;; (send *carrot* :translate (float-vector (- (/ width 2) 20) 0 0))
  
  (objects (list *kitchen* *pr2* *cutting-board* *carrot*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (setq interval height)

  (warn "please run (grasp-carrot-peel) ~%")
  )

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
  ;; (send *arrow* :translate (float-vector (+ (/ width -2) 20) 0 0))
  (send *arrow* :translate #f(-20 0 0))
  ;; (send *arrow* :rotate (deg2rad 30) :y)
  (send *arrow* :rotate (deg2rad 45) :y)

  ;; (send *arrow* :translate #f(-10 -15 0) :world)
  ;; (send *arrow* :translate #f(20 -15 -20) :world)

  ;; (send *arrow* :translate #f(-10 -15 -10) :world)

  

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

  (send *ri* :start-grasp :larm :wait t :gain 0.1)
     
  (warn "please run  (set-carrot-1) ~%")
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

(defun set-carrot-1 ()
  (setq *c-arrow* (arrow))
  (send *c-arrow* :newcoords (make-coords :pos (float-vector 500.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (set-carrot)
  (warn "please run  (set-peeler) or (grasp-peeler) ~%")
  )

(defun set-peeler ()
  ;; ピーラーをセットする．
  (setq *peeler* (peeler))
  (send *peeler* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
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
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 200) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 剥く位置
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate #f(0 20 0) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)

  (send *arrow* :translate (float-vector 0 0 (* 1 height)) :world)
  (send *arrow* :rotate (deg2rad 30) :y)
  (send *arrow* :translate (float-vector 0 80 80) :world)

  ;;調整
  (send *arrow* :translate (float-vector 0 adj 0))

  (send *arrow* :translate (float-vector adj2 0 0))

  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 -80 -80) :world)
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 皮剥き始める所

  (defvar *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)

  (until *cb-flag*
    (send *arrow* :translate (float-vector 0 0 (* 10 -1)) :world)
    (send *pr2* :rarm :inverse-kinematics
        *arrow*
      :move-target (car (send *peeler* :attention))
        :rotation-axis t
        :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)
    
    (ros::spin-once)
    (ros::sleep)
    )

  ;; 剥き終わり
  (send *arrow* :rotate (deg2rad -30) :y)
  (send *arrow* :translate (float-vector (* (+ width 20) -1) 0 0) )
  (send *arrow* :rotate (deg2rad 30) :y)

  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "you can retry (peel-test) or (finish-pose-peel) , (set-carrot-2)~%")
  )

(defun touch-test ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :head :look-at (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos))
  (send *ri* :angle-vector (send *pr2* :angle-vector))

  ;; 右手を上げる
  
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 200) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 剥く位置
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate #f(0 15 0) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)

  (send *arrow* :translate (float-vector 0 0 (* 1 height)) :world)
  (send *arrow* :rotate (deg2rad 30) :y)
  (send *arrow* :translate (float-vector 0 80 80) :world)

  ;;調整
  (send *arrow* :translate (float-vector 0 adj 0))

  (send *arrow* :translate (float-vector adj2 0 0))

  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 -80 -80) :world)
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 皮剥き始める所
  (defvar *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)

  (until *cb-flag*
    (send *arrow* :translate (float-vector 0 0 (* 10 -1)) :world)
    (send *pr2* :rarm :inverse-kinematics
        *arrow*
      :move-target (car (send *peeler* :attention))
        :rotation-axis t
        :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)
    
    (ros::spin-once)
    (ros::sleep)
    )

  (warn "please run (finish-touch) or (exec-peel)~%")
  )

(defun finish-touch ()
  ;; 手を少し上に
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
  (send *pr2* :rarm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 150 0) :world)
  (send *pr2* :rarm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run  (set-carrot-2)~%")
  )

(defun exec-peel ()
  ;; 剥き終わり
  (send *arrow* :rotate (deg2rad -30) :y)
  (send *arrow* :translate (float-vector (* (+ width 20) -1) 0 0) )
  (send *arrow* :rotate (deg2rad 30) :y)

  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "you can retry (peel-test) or (finish-pose-peel) , (set-carrot-2)~%")
  )

(defun set-carrot-2 ()
  (send *c-arrow* :newcoords (make-coords :pos (float-vector 500.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (send *c-arrow* :rotate (deg2rad 45) :y :world)
  (set-carrot)
  (warn "please run  (peel-test-2) ~%")  
  )

(defun peel-test-2 ()
  (peel-test)
  (warn "please run  (set-carrot-3) ~%")  
  )

(defun set-carrot-3 ()
  (send *c-arrow* :newcoords (make-coords :pos (float-vector 500.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (send *c-arrow* :rotate (deg2rad 90) :y :world)
  (set-carrot)
  (warn "please run  (peel-test-3) ~%")  
  )

(defun peel-test-3 ()
  (peel-test)
  (warn "please run  (set-carrot-4) ~%")  
  )

(defun set-carrot-4 ()
  (send *c-arrow* :newcoords (make-coords :pos (float-vector 500.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (send *c-arrow* :rotate (deg2rad 135) :y :world)
  (set-carrot)
  (warn "please run  (peel-test-4) ~%")  
  )

(defun peel-test-4 ()
  (peel-test)
  (warn "please run  (set-carrot-5) ~%")  
  )

(defun set-carrot-5 ()
  (send *c-arrow* :newcoords (make-coords :pos (float-vector 500.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (send *c-arrow* :rotate (deg2rad 180) :y :world)
  (set-carrot)
  (warn "please run  (peel-test-5) ~%")  
  )

(defun peel-test-5 ()
  (peel-test)
  (warn "please run  (set-carrot-6) ~%")  
  )

(defun set-carrot-6 ()
  (send *c-arrow* :newcoords (make-coords :pos (float-vector 550.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (send *c-arrow* :rotate (deg2rad -135) :y :world)
  (set-carrot)
  (warn "please run  (peel-test-6) ~%")  
  )

(defun peel-test-6 ()
  (peel-test)
  (warn "please run  (set-carrot-7) ~%")  
  )

(defun set-carrot-7 ()
  (send *c-arrow* :newcoords (make-coords :pos (float-vector 570.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (send *c-arrow* :rotate (deg2rad -90) :y :world)
  (set-carrot)
  (warn "please run  (peel-test-7) ~%")  
  )

(defun peel-test-7 ()
  (peel-test)
  (warn "please run  (set-carrot-8) ~%")  
  )

(defun set-carrot-8 ()
  (send *c-arrow* :newcoords (make-coords :pos (float-vector 550.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (send *c-arrow* :rotate (deg2rad -45) :y :world)
  (set-carrot)
  (warn "please run  (peel-test-8) ~%")  
  )

(defun peel-test-8 ()
  (peel-test)
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
  (send *c-arrow* :newcoords (make-coords :pos (float-vector 500.0 2000.0 (+ 850.0 (/ height 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  
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
  (send *c-arrow* :newcoords (make-coords :pos (float-vector 500.0 2000.0 (+ 850.0 (/ height 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  
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
  (send *c-arrow* :newcoords (make-coords :pos (float-vector 500.0 2000.0 1100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
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
  ;; (set-carrot-peel :w width :l length :h height)
  (grasp-carrot-peel)
  (set-carrot-1)
  (set-peeler)
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
