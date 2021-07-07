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
  (setq adj -20)

  ;; set potato
  (load "../../model/potato-new-type.l")

  (setq width 90)
  (setq length 60)
  (setq height 60)
  )

(init)


;; トピックなどを定義
(defvar *topic-name* "/right_endeffector/wrench")

;; ros init
(ros::roseus "wrench_listener" :anonymous t)
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
      (if (> y -6)
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


(warn "please run (set-potato :w 90 :l 60 :h 60) or (now-devel)~%")

(defun set-potato (&rest args &key (w 60) (l 60) (h 60) &allow-other-keys)
  
  (setq width w)
  (setq length l)
  (setq height h)
  
  (setq *potato* (potato :w w :l l :h h))
  (send *potato* :transform (make-coords :pos (float-vector 500.0 2000.0 (+ 850.0 (/ h 2))) :rot #2f((1.194340e-15 -1.0 0.0) (1.0 1.194340e-15 0.0) (0.0 0.0 1.0))))
  (send *potato* :cut)

  ;; (send p4 :dissoc p7)
  ;; (send p7 :translate #f(0 0 -100) :world)
  ;; (send p4 :dissoc p8)
  ;; (send p8 :translate #f(0 0 -100) :world)  
  
  (objects (list *kitchen* *pr2* *cutting-board* *potato*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))
  
  (warn "please run (grasp-potato) ~%")
  )

(defun grasp-potato ()
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

  ;; 左手を少し前に
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

  ;; じゃがいもの掴む所に
  (send *arrow* :newcoords (send *potato* :copy-worldcoords))
  (send *arrow* :translate #f(0 -20 0) :world)
  (send *arrow* :rotate (deg2rad 70) :y)

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
     
  (send *arrow* :newcoords (send *cut-point-1* :copy-worldcoords))
  (warn "please run  (grasp-knife-hor) or (set-knife-hor) ~%")
  )

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

  (warn "please run (cut-test) or (touch-test)~%")
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

  (warn "please run (cut-test) or (touch-test)~%")
  )

(defun touch-test ()
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
  (send *arrow* :newcoords (send *cut-point-1* :copy-worldcoords))
  ;; (send *arrow* :translate (float-vector 0 0 (* height 1)))
  (send *arrow* :translate (float-vector 0 -50 (* height 1)))

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

  (setq interval 10)

  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)
    
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
    
    (ros::spin-once)
    (ros::sleep)
    )

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  
  (warn "you can retry (cut-test), (continue-cut 4) or you want to finish please run (finish-pose)  ~%")
  ;; (warn "please (slide-knife) ~%")
  (warn "please run (up-knife) ~%")
  )

(defun up-knife ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (setq interval 5)

  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb-2)
    
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
    
    (ros::spin-once)
    (ros::sleep)
    )

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
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

  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-z-cb)
    
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
    
    (ros::spin-once)
    (ros::sleep)
    )

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
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
  (warn "you can retry (cut-test), (continue-cut 4) or you want to finish please run (finish-pose)  ~%")
  )

(defun move-potato-3 ()
  (send p4 :dissoc p1)
  (send p4 :dissoc p2)
  (send p4 :dissoc p3)  
  (send p1 :translate #f(0 100 0) :world)
  (send p2 :translate #f(0 100 0) :world)
  (send p3 :translate #f(0 100 0) :world)
  (send *viewer* :draw-objects)
  )

(defun finish-pose ()
  ;; (move-potato-3)

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

  ;; (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  ;; (send *arrow* :translate (float-vector 0 0 50) :world)
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;     *arrow*
  ;;     :move-target (car (send *knife* :attention))
  ;;     :rotation-axis t
  ;;     :debug-view t)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  ;; (send *ri* :wait-interpolation)
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
  
  ;; set pose
  (send *arrow* :newcoords (make-coords :pos #f(800.191 2189.104 866.677) :rpy #f(-2.341 -0.222 -0.482)))
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)

  (warn "please run (reset-larm)~%")  
  )

(defun reset-larm ()
  ;; release potato
  (send *pr2* :larm :end-coords :dissoc *potato*)
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
  (send *arrow* :translate #f(150 -100 100) :world)
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
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  ;; (warn "please run (change-peeler)~&")
  )

(defun now-devel ()
  (set-potato :w width :l length :h height)
  (grasp-potato)
  (grasp-knife-hor)
  (touch-test)
  (slide-knife)
  (finish-pose)
  ;; (reset-larm)
  )



(defun now-test ()
  (set-potato :w width :l length :h height)
  (grasp-potato)
  (set-knife-hor)
  (touch-test)
  (slide-knife)
  (finish-pose)
  (reset-larm)
  )


(defun exec-all ()
  (set-potato :w width :l length :h height)
  (grasp-potato)
  (grasp-knife-hor)
  (touch-test)
  (slide-knife)
  (finish-pose)
  (reset-larm)
  (change-peeler)
  )
