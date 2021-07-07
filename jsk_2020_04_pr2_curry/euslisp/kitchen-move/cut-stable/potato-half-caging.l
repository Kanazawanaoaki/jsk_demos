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

  (setq num 100)

  ;; set potato
  (load "../../model/potato-new-type.l")

  (setq width 90)
  (setq length 60)
  (setq height 60)
  )

(init)



(warn "please run (set-potato :w 90 :l 60 :h 60) or (now-devel)~%")

(defun set-potato (&rest args &key (w 90) (l 60) (h 60) &allow-other-keys)
  
  (setq width w)
  (setq length l)
  (setq height h)
  
  (setq *potato* (potato :w w :l l :h h))
  (send *potato* :transform (make-coords :pos (float-vector 500.0 2000.0 (+ 850.0 (/ h 2))) :rot #2f((1.194340e-15 -1.0 0.0) (1.0 1.194340e-15 0.0) (0.0 0.0 1.0))))
  (send *potato* :cut)

  (send p4 :dissoc p7)
  (send p7 :translate #f(0 0 -100) :world)
  (send p4 :dissoc p8)
  (send p8 :translate #f(0 0 -100) :world)

  (send p4 :dissoc p1)
  (send p4 :dissoc p2)
  (send p4 :dissoc p3)

  (send p4 :translate #f(0 0 -100) :world)
  (send *viewer* :draw-objects)

  (send p1 :assoc p2)
  (send p1 :assoc p3)
  (send p1 :translate #f(0 50 0) :world)
  
  (objects (list *kitchen* *pr2* *cutting-board* *potato*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))
  
  (warn "please run (set-larm) ~%")
  )

(defun set-larm ()
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
  (send *arrow* :newcoords (send p1 :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 (/ (- width 30) 4) 0) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)
  (send *arrow* :rotate (deg2rad 45) :y)


  ;; tmp
  ;; (send *arrow* :translate #f(0 0 -10) :world)

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

  ;; ;; gripperを閉じる
  ;; (send *ri* :start-grasp :larm :wait t)

  ;; (warn "please run  (set-knife-hor) or (grasp-knife-hor) ~%")
  (warn "please run  (caging-test) ~%")
  )

(setq tmp 0)

(defun caging-test ()
  (send *arrow* :translate (float-vector 0 0 tmp) :world)
  
  (send *arrow* :translate (float-vector 0 (* num -1) 0) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 (* num 1.5) 0) :world)
  ;; (send *arrow* :translate (float-vector 0 (* num -0.5) 0) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run  (reset-larm) ~%")
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
  (setq *angle-vector-1* #f(325.0 3.90826 -19.7839 166.352 -51.2831 -79.3544 -82.7576 -59.6161 -75.9561 52.4204 -108.237 -109.764 -0.099029 -9.45949 8.91288 0.0 50.0))
  (send *pr2* :angle-vector *angle-vector-1*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手前にする
  (setq *angle-vector-2* #f(325.0 38.3886 -20.1671 106.299 -84.5044 -33.3479 -50.7117 -72.7731 -75.9561 52.4204 -108.237 -109.764 -0.099029 -9.45949 8.91288 0.0 50.0))
  (send *pr2* :angle-vector *angle-vector-2*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  
  (setq *angle-vector-3* #f(325.0 75.9843 52.494 108.184 -109.757 -359.276 -9.46019 315.263 -75.9561 52.4204 -108.237 -109.764 -0.099029 -9.45949 8.91288 0.0 50.0))
  (send *pr2* :angle-vector *angle-vector-3*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  )

(defun now-devel ()
  (set-potato :w width :l length :h height)
  (set-larm)
  (caging-test)
  ;; (reset-larm)
  )



(defun now-test ()
  (set-potato :w width :l length :h height)
  (set-larm)
  (caging-test)
  (reset-larm)
  )


(defun exec-all ()
  (set-potato :w width :l length :h height)
  (set-larm)
  (caging-test)
  (reset-larm)
  )
