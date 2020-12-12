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
  
  (setq adj 0)

  ;; set potato
  (load "../../model/potato-new-type.l")

  (setq width 90)
  (setq length 60)
  (setq height 60)
  )

(init)


(setq *knife* (knife))
(send *knife* :transform (make-coords :pos (float-vector 600.0 2500.0 870.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))
(send *knife* :rotate (deg2rad 180) :z :world)
(send *knife* :rotate (deg2rad -90) :x :world)
(send *knife* :rotate (deg2rad -10) :y :world)


;; 手を上げる
(send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
(send *arrow* :translate #f(0 0 50) :world)
(send *pr2* :rarm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
(send *viewer* :draw-objects)
(send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
(send *ri* :wait-interpolation)


;;掴む位置
(send *arrow* :newcoords (send *knife* :copy-worldcoords))
(send *arrow* :translate #f(-12 0 0))
(send *arrow* :rotate (deg2rad -90) :x)

(send *ri* :stop-grasp :rarm :wait t)

(send *arrow* :translate #f(60 -60 100) :world)
(send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
(send *viewer* :draw-objects)
(send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
(send *ri* :wait-interpolation)

(send *arrow* :translate #f(-60 60 -100) :world)

(send *arrow* :rotate (deg2rad -5) :x)
 
(send *pr2* :rarm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
(send *viewer* :draw-objects)
(send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
(send *ri* :wait-interpolation)
(send *ri* :start-grasp :rarm :wait t :gain 100)


;; 手を上げる
(send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
(send *arrow* :translate #f(0 0 50) :world)
(send *pr2* :rarm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
(send *viewer* :draw-objects)
(send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
(send *ri* :wait-interpolation)

;; 手を上げる
(send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
(send *arrow* :translate #f(60 -150 150) :world)
(send *pr2* :rarm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
(send *viewer* :draw-objects)
(send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
(send *ri* :wait-interpolation)




(objects (list *pr2* *cutting-board* *knife*))
