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


  ;; キッチンの場所まで移動 (初期値)
  (defun move-to-kitchen-irt ()
    (send *pr2* :move-to *kitchen-spot* :world)
    )
  (move-to-kitchen-irt)

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

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

(defun set-pose ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(init)


(setq *knife* (knife))
(setq *knife-coords* (make-coords :pos (float-vector 580.098 2226.215 857.185) :rpy (float-vector 3.14 0.073 1.498)))
(send *knife* :newcoords (send *knife-coords* :copy-worldcoords))

(load "../../model/peeler.l")
(setq *peeler* (peeler))
;; (setq *peeler-coords* (make-coords :pos (float-vector 492.877 2300.143 900.499) :rpy (float-vector 3.14 0.049 1.51))) ;; old ver
(setq *peeler-coords* (make-coords :pos (float-vector 492.877 2300.143 895) :rpy (float-vector 3.14 0.049 1.51))) ;; new ver
(send *peeler* :newcoords (send *peeler-coords* :copy-worldcoords))

(load "../../model/potato-peeler.l")
(setq *potato-peeler* (peeler))
;; (setq *potato-peeler-coords* (make-coords :pos (float-vector 542.121 2414.771 895.736) :rpy (float-vector 3.14 0.013 1.545))) ;; old ver.
(setq *potato-peeler-coords* (make-coords :pos (float-vector 542.121 2414.771 900) :rpy (float-vector 3.14 0.013 1.545))) ;; new ver. tmp
(send *potato-peeler* :newcoords (send *potato-peeler-coords* :copy-worldcoords))

(objects (list *pr2* *cutting-board* *peeler* *knife* *potato-peeler* *kitchen*))
