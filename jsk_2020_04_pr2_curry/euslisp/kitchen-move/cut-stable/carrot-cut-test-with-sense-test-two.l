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

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (objects (list *pr2* *cutting-board*))

  ;; def global values
  (setq s-time 3)

  ;; 調整用
  (setq adj 0)

  ;; set carrot
  (load "../../model/carrot-test-new-type.l")
  ;; (load "../../model/carrot-ellipsoid-model.l")

  (setq width 160)
  (setq length 40)
  (setq height 40)
  )

(defun set-pose ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(init)


;; ros init
(ros::roseus "carrot_rec_test" :anonymous t)

;; ros init
(setq *topic-name* "/right_endeffector/wrench")
(ros::load-ros-manifest "geometry_msgs")
(setq *cb-flag* nil)


(defun wrench-y-cb (msg)
  (when msg
    (let ((y nil))
      (setq y (send msg :wrench :force :y))
      (if (< y -10)
      (progn 
        (setq *cb-flag* t)
        (format t "OK!! ~A ~%" y)
        )
    (format t "~A ~%" y))
      )))

(defun wrench-y-cb-2 (msg)
  (when msg
    (let ((y nil))
      (setq y (send msg :wrench :force :y))
      (if (> y 2)
      (progn 
        (setq *cb-flag* t)
        (format t "OK!! ~A ~%" y)
        )
    (format t "~A ~%" y))
      )))

(defun wrench-z-cb (msg)
  (when msg
    (let ((z nil))
      (setq z (send msg :wrench :force :z))
      (if (< z -5)
          (progn 
            (setq *cb-flag* t)
            (format t "OK!! z: ~A ~%" z)
            )
        (format t "z: ~A ~%" z))
      )))

(warn "please run (set-carrot :w 160 :l 40 :h 40) or (now-devel)~%")

(defun set-carrot (&rest args &key (w 160) (l 40) (h 40) &allow-other-keys)

  (setq width w)
  (setq length l)
  (setq height h)
  
  (setq *carrot* (carrot :w w :l l :h h))
  (send *carrot* :transform (make-coords :pos (float-vector 500.0 2000.0 (+ 850.0 (/ h 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (send *carrot* :cut)
  
  (objects (list *kitchen* *pr2* *cutting-board* *carrot*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (grasp-carrot) ~%")
  )


(defun grasp-carrot ()
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
  
  ;; 人参の掴む所に
  (send *arrow* :newcoords (send *carrot* :copy-worldcoords))
  ;; (send *arrow* :translate (float-vector (+ (/ width -2) 20) 0 0))
  (send *arrow* :translate (float-vector (* (+ (/ width -2) 20) 2) 0 0))
  (send *arrow* :rotate (deg2rad 70) :y)

  ;; (send *arrow* :translate #f(-10 -20 -10) :world)

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

  (send *ri* :start-grasp :larm :wait t :gain 0.05)  
 
  (warn "please run  (grasp-knife-hor) ~%")
  )

(defun grasp-knife-hor ()

  ;; grasp knife
  (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :speak-jp "包丁を握らせて下さい")
  (unix:sleep s-time)
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  
  (setq *knife* (knife))
  (send *knife* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  ;; (send *knife* :translate #f(12 0 0))

  (send *knife* :translate #f(20 0 0))

  (send *knife* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *knife*)

  (objects (list *kitchen* *pr2* *cutting-board* *carrot* *knife*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (touch-test-set) ~%")
  )

(defun set-knife-hor ()
  (setq *knife* (knife))
  (send *knife* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  ;; (send *knife* :translate #f(12 0 0))

  (send *knife* :translate #f(20 0 0))

  (send *knife* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *knife*)
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  
  (objects (list *kitchen* *pr2* *cutting-board* *carrot* *knife*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (touch-test-set) ~%")
  )

(defun touch-test-set ()
  
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
  ;; (send *arrow* :translate (float-vector 0 0 (* height 1)))

  ;; (send *arrow* :translate (float-vector 0 -20 (* height 1)))
  (send *arrow* :translate (float-vector 0 -40 (* height 1)))
  
  ;;調整
  (send *arrow* :translate (float-vector 0 adj 0))

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

  (warn "please run (touch-test) , (touch-test-2) or (touch-test-3) ~%")
  )

(defun touch-test ()
  (setq interval 10)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  ;; (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)
    
  (until *cb-flag*
    (print 4)
    (send *arrow* :translate (float-vector 0 0 (* interval -1)))
    (send *pr2* :rarm :inverse-kinematics
        *arrow*
        :move-target (car (send *knife* :attention))
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

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  
  (warn "you can retry (cut-test), (continue-cut 4) or you want to finish please run (finish-pose)  ~%")
  ;; (warn "please run (slide-knife) ~%")
  (warn "please run (up-knife) ~%")
  )


(defun touch-test-2 ()
  (setq interval 10)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)

  ;; armが接触するか，一定距離動かす関数
  (send *arrow* :translate (float-vector 0 0 (- (* height -1) 10)))
  ;; (send *arrow* :translate (float-vector 0 0 (* height -1)))
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view nil)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)

  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
        (ros::spin-once)
        (if *cb-flag* t)
        )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      
      (ros::unsubscribe "/right_endeffector/wrench")

      (warn "please run (up-knife) ~%")
      (return-from touch-test-2 t))
    )

  (ros::unsubscribe "/right_endeffector/wrench")
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (warn "fail cancel !! ~%")  
  (warn "please run (up-knife) ~%")  
  )

(defun touch-test-3 ()
  (setq interval 10)

  ;; armが接触するか，一定距離動かす関数
  (send *arrow* :translate (float-vector 0 0 (- (* height -1) 10)))
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (warn "please run (up-knife) ~%")
  )


(defun touch-test-4 ()
  (setq interval 10)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)

  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i (+ (round (/ (* height 2) interval)) 1))
    (send *arrow* :translate (float-vector 0 0 (* interval -1)))
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :move-target (car (send *knife* :attention))
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
      
      (ros::unsubscribe "/right_endeffector/wrench")

      (warn "please run (up-knife) ~%")
      (return-from touch-test-4 t))
    )

  (ros::unsubscribe "/right_endeffector/wrench")
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (warn "fail cancel !! ~%")  
  (warn "please run (up-knife) ~%")  
  )


(defun up-knife ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (setq interval 10)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  ;; (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb-2)
    
  (until *cb-flag*
    (print 4)
    (send *arrow* :translate (float-vector 0 0 (* interval 1)))
    (send *pr2* :rarm :inverse-kinematics
        *arrow*
        :move-target (car (send *knife* :attention))
        :rotation-axis t
        :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)

    (setq msg (one-shot-subscribe *topic-name* geometry_msgs::WrenchStamped))
    (wrench-y-cb-2 msg)
    
    ;; (ros::spin-once)
    ;; (ros::sleep)
    )

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (warn "please run (slide-knife) ~%")  
  )

(defun up-knife-2 ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (setq interval 5)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb-2)
    
  ;; armが接触するか，一定距離動かす関数
  (send *arrow* :translate (float-vector 0 0 (* height 1)) :world)
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
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
      
      (ros::unsubscribe "/right_endeffector/wrench")

      (warn "please run (slide-knife) ~%")  
      (return-from up-knife-2 t))
    )

  (ros::unsubscribe "/right_endeffector/wrench")
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (warn "fail cancel !! ~%")  
  (warn "please run (slide-knife) ~%")  
  )

(defun up-knife-3 ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    
  ;; armが接触するか，一定距離動かす関数
  (send *arrow* :translate (float-vector 0 0 (* height 1)) :world)
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  
  (warn "please run (slide-knife) ~%")  
  )


(defun up-knife-4 ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (setq interval 5)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb-2)
    
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i (+ (* (round (/ height interval)) 2) 1))
    (send *arrow* :translate (float-vector 0 0 (* interval 1)) :world)
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :move-target (car (send *knife* :attention))
          :rotation-axis t
          :debug-view t)

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
      
      (ros::unsubscribe "/right_endeffector/wrench")

      (warn "please run (slide-knife) ~%")  
      (return-from up-knife-4 t))
    )

  (ros::unsubscribe "/right_endeffector/wrench")
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))


  (warn "fail cancel !! ~%")  
  (warn "please run (slide-knife) ~%")  
  )



(setq adj2 0)

(defun slide-knife ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  ;; 少し上げる
  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 adj2) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  ;; (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-z-cb)
  
  (until *cb-flag*
    (print 4)
    (send *arrow* :translate #f(0 -5 0) :world)
    (send *pr2* :rarm :inverse-kinematics
        *arrow*
        :move-target (car (send *knife* :attention))
        :rotation-axis t
        :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)
    
    (setq msg (one-shot-subscribe *topic-name* geometry_msgs::WrenchStamped))
    (wrench-z-cb msg)

    ;; (ros::spin-once)
    ;; (ros::sleep)
    )

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (warn "please run (set-cut-1) ~%")  
  )

(defun slide-knife-2 ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  ;; 少し上げる
  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 adj2) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-z-cb)

      
  ;; armが接触するか，一定距離動かす関数
  (send *arrow* :translate (float-vector 0 (* (+ 50 10) -1) 0) :world)
  (send *pr2* :rarm :inverse-kinematics
        *arrow*
        :move-target (car (send *knife* :attention))
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
      
      (ros::unsubscribe "/right_endeffector/wrench")

      (warn "please run (set-cut-1) or (cut-all)~%")  
      (return-from slide-knife-2 t))
    )

  (ros::unsubscribe "/right_endeffector/wrench")
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (warn "fail cancel !! ~%")  
  (warn "please run (set-cut-1) ~%")  
  )

(defun slide-knife-4 ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  ;; 少し上げる
  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 adj2) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-z-cb)

  (setq interval 5)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i (+ (round (/ 50 interval)) 1))
    (send *arrow* :translate (float-vector 0 (* interval -1) 0) :world)
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :move-target (car (send *knife* :attention))
          :rotation-axis t
          :debug-view t)

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
      
      (ros::unsubscribe "/right_endeffector/wrench")

      (warn "please run (set-cut-1) or (cut-all)~%")  
      (return-from slide-knife-4 t))
    )

  (ros::unsubscribe "/right_endeffector/wrench")
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (warn "fail cancel !! ~%")  
  (warn "please run (set-cut-1) or (cut-all)~%")  
  )


(defun cut-all ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  ;; 薄切りする間隔
  (setq tmp 15)
  
  (setq acc-y (elt (send (send (car (send *knife* :attention)) :copy-worldcoords) :worldpos) 1))
  (setq now-y (elt (send (send *cut-point-1* :copy-worldcoords) :worldpos) 1))
  (setq adj (- now-y acc-y))

  (setq l-y (+ (elt (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos) 1) 20))
  (setq length (- acc-y l-y))

  ;; (dotimes (i (- (round (/ length tmp)) 1))
  (dotimes (i (round (/ length tmp)) )
    (setq adj (+ adj tmp))
    (cut-test)
    )
  )
  

(defun set-cut-1 ()
  (setq acc-y (elt (send (send (car (send *knife* :attention)) :copy-worldcoords) :worldpos) 1))
  (setq now-y (elt (send (send *cut-point-1* :copy-worldcoords) :worldpos) 1))
  (setq adj (+ (- now-y acc-y) 15))
  (warn "please run (cut-test) ~%")  
  )

(defun set-cut-2 ()
  (setq adj (+ adj 10))
  (warn "please run (cut-test) ~%")  
  )

(defun cut-test ()
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
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

  ;;調整
  ;; (send *arrow* :translate #f(0 10 0))
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
  
  (send *arrow* :translate (float-vector 0 0 (* offset -0.5)))  
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 (* offset -0.5)))  
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq avs (list))
  (setq tms (list))
  
  (setq interval 10)
  (dotimes (i (+ (round (/ height interval)) 1))
    (send *arrow* :translate (float-vector (* interval 2) 0 (/ interval -2)))
    (send *pr2* :rarm :inverse-kinematics
        *arrow*
        :move-target (car (send *knife* :attention))
        :rotation-axis t
        :debug-view nil)
    ;; (send *viewer* :draw-objects)
    ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    ;; (send *ri* :wait-interpolation)

    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))

    (send *arrow* :translate (float-vector (* interval -2) 0 (/ interval -2)))
    (send *pr2* :rarm :inverse-kinematics
        *arrow*
        :move-target (car (send *knife* :attention))
        :rotation-axis t
        :debug-view nil)
    ;; (send *viewer* :draw-objects)
    ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    ;; (send *ri* :wait-interpolation)

    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    
    )

  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))  
  
  (warn "you can retry (cut-test), (continue-cut 4) or you want to finish please run (finish-pose)  ~%")
  (warn "or please run (set-cut-2) ~%")
  )

(defun cut-test2 ()
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
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

  ;;調整
  ;; (send *arrow* :translate #f(0 10 0))
  (send *arrow* :translate (float-vector 0 adj 0))

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

  (setq interval 20)
  (dotimes (i (+ (round (/ height interval)) 1))
    (send *arrow* :translate (float-vector (* interval 1) 0 (/ interval -2)))
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
  
  (warn "you can retry (cut-test), (continue-cut 4) or you want to finish please run (finish-pose)  ~%")
  (warn "or please run (set-cut-2) ~%")
  )

(defun continue-cut (num)
  (setq interval 10)
  (dotimes (i num)
    (send *arrow* :translate (float-vector (* interval 2) 0 (/ interval -2)))
    (send *pr2* :rarm :inverse-kinematics
      *arrow*
      :move-target (car (send *knife* :attention))
      :rotation-axis t
      :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)

    (send *arrow* :translate (float-vector (* interval -2) 0 (/ interval -2)))
    (send *pr2* :rarm :inverse-kinematics
      *arrow*
      :move-target (car (send *knife* :attention))
      :rotation-axis t
      :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation))
  (warn "you can retry (cut-test), (continue-cut 4) or you want to finish please run (finish-pose)  ~%")
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

  (setq *rav1* #f(-16.0652 5.94641 -77.1102 -121.467 184.962 -106.138 -192.692))
  (send *pr2* :rarm :angle-vector *rav1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (setq *rav2* #f(-30.0303 1.63624 -169.166 -116.783 100.843 -98.3015 -58.1037))
  (send *pr2* :rarm :angle-vector *rav2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (warn "please run (reset-larm)~%")  
  )

(defun avoid-pose ()
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

  (setq *rav1* #f(-16.0652 5.94641 -77.1102 -121.467 184.962 -106.138 -192.692))
  (send *pr2* :rarm :angle-vector *rav1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (setq *rav0* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav0*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (warn "please run (reset-larm)~%")  
  )


(defun reset-larm ()
  ;; release carrot
  (send *pr2* :larm :end-coords :dissoc *carrot*)
  (send *ri* :stop-grasp :larm :wait t)

  ;; 左手を少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 少し上にして水平に
  (setq *lav1* #f(16.6222 -20.2483 123.957 -51.9842 -42.7912 -65.3348 -437.304))
  (send *pr2* :larm :angle-vector *lav1*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手前にする
  (setq *lav2* #f(41.8129 -20.2467 85.9536 -82.3235 -13.8272 -47.9804 -458.658))
  (send *pr2* :larm :angle-vector *lav2*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq *lav3* #f(75.8217 52.0712 108.49 -109.796 -2.86542 -9.47056 -401.362))
  (send *pr2* :larm :angle-vector *lav3*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)  

  (warn "please run (change-peeler)~&")
  )


(defun change-peeler ()
  (send *pr2* :angle-vector (send *ri* :state :potantio-vector))
  
  ;; release knife
  (send *pr2* :rarm :end-coords :dissoc *knife*)
  (send *ri* :speak-jp "包丁を離します")
  (unix:sleep s-time)
  (send *ri* :stop-grasp :rarm :wait t)
  
  ;; grasp peeler
  (send *ri* :speak-jp "ピーラーを握らせて下さい")
  (unix:sleep s-time)
  (send *ri* :start-grasp :rarm :wait t :gain 100)

  (setq *peeler* (peeler))
  (send *peeler* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *pr2* :rarm :end-coords :assoc *peeler*)

  (objects (list *kitchen* *pr2* *cutting-board* *carrot* *peeler*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  ;; (warn "please run (peel-test) ~%")
  )

(defun now-devel ()
  (set-carrot :w width :l length :h height)
  (grasp-carrot)
  (grasp-knife-hor)
  (cut-test)
  (finish-pose)
  (put-carrot)
  (reset-larm)
  (change-peeler)
  )



(defun now-test ()
  (set-carrot :w width :l length :h height)
  (grasp-carrot)
  (set-knife-hor)
  (cut-test)
  (finish-pose)
  (put-carrot)
  (reset-larm)
  ;; (change-peeler)
  )


(defun exec-all ()
  (set-carrot :w width :l length :h height)
  (grasp-carrot)
  (grasp-knife-hor)
  (cut-test)
  (finish-pose)
  (put-carrot)
  (reset-larm)
  (change-peeler)
  )

(defun now-cut ()
  (set-potato :w width :l length :h height)
  (grasp-potato)
  (set-knife-hor)
  (cut-test)
  (finish-pose)
  (put-potato)
  (reset-larm)
  )


(defun tmp-test ()
  (set-carrot :w 150 :l 40 :h 40)
  (grasp-carrot)
  (grasp-knife-hor)
  (cut-test)
  (avoid-pose)
  (reset-larm)
  )
