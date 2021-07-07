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
  (load "../../model/potato-peeler.l")
  (load "../../model/knife-new-attention.l")
  (load "models/arrow-object.l")
  (setq *arrow* (arrow))

  ;; set spots
  (setq *cook-spot* (send *room73b2* :spot "cook-spot"))
  (setq *sink-spot* (make-coords :pos #f(1055 2600 0) :rpy #f(3.14 0 0))) 
  (setq *kitchen-spot* (send *room73b2* :spot "kitchen-spot"))
  (setq *stove-spot* (make-coords :pos #f(1400 1600 0) :rpy #f(3.14 0 0)))


  ;; キッチンの場所まで移動 (初期値)
  (defun move-to-kitchen-irt ()
    (send *pr2* :move-to *stove-spot* :world)
    )
  (move-to-kitchen-irt)

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  ;; def global values
  (setq s-time 3)
  
  (setq adj 0)

  ;; set spatula
  (load "../../model/spatula.l")
  (setq *spatula* (spatula))

  ;; set pot
  (load "../../model/cooking-pot-73b2.l")
  (setq *pot* (cooking-pot))
  (send *pot* :newcoords (make-coords :pos (float-vector 420.0 1500.0 840.0) :rot #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))))
  
  (setq width 90)
  (setq length 60)
  (setq height 60)
  )

(defun set-pose ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (on-stove) ~%")
  )

(init)
(objects (list *pr2* *pot* *kitchen*))


(warn "please run (set-spatula) ~%")

(defun set-spatula ()
  ;; へらをセットする．
  (send *spatula* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *spatula* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *spatula*)

  (objects (list *kitchen* *pr2* *spatula* *pot*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box
     (flatten (send-all (send *pr2* :bodies) :vertices))))  

  (warn "please run (peel-test) ~%")
  )
