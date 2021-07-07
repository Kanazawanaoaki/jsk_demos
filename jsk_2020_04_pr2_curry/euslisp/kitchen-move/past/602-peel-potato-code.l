(load "../model/my-room73b2-scene.l")
(setq *room* (room73b2))

(load "package://pr2eus/pr2-interface.l")
(pr2-init)


 ;; set まな板
(load "../model/cutting-board.l")
(setq *cutting-board* (cutting-board))
(send *cutting-board* :transform (make-coords :pos (float-vector 500.0 2000.0 825.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))

;; set objects
(load "../model/potato-test-model.l")
(load "../model/peeler.l")
(load "models/arrow-object.l")


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

(objects (list *room* *pr2* *cutting-board*))
(send *irtviewer* :look-all
      (geo::make-bounding-box 
       (flatten (send-all (send *pr2* :bodies) :vertices))))

;; def global values
(setq s-time 4)

(setq width 90)
(setq length 60)
(setq height 60)

(warn "please run (set-potato :w 90 :l 60 :h 60) or (now-devel)~%")

(defun set-potato (&rest args &key (w 90) (l 60) (h 60) &allow-other-keys)

  (setq width w)
  (setq length l)
  (setq height h)
  
  (setq *potato* (potato :w w :l l :h h))
  (send *potato* :transform (make-coords :pos (float-vector 500.0 2000.0 (+ 835.0 (/ h 2))) :rot #2f((1.194340e-15 -1.0 0.0) (1.0 1.194340e-15 0.0) (0.0 0.0 1.0))))
  (send *potato* :peel)
  (send *potato* :translate #f(0 0 40) :world)
  
  (objects (list *room* *pr2* *cutting-board* *potato*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (set-peeler) ~%")
  )

(defun set-peeler ()
  ;; set pose
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; grasp peeler
  (send *ri* :stop-grasp :rarm :wait t)
  ;; (send *ri* :speak-jp "ピーラーを握らせて下さい")
  (unix:sleep s-time)
  ;; (send *ri* :start-grasp :rarm :wait t)
  ;; (send *ri* :start-grasp :rarm :wait t :arg :gain 100)
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  
  (setq *peeler* (peeler))
  (send *peeler* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *pr2* :rarm :end-coords :assoc *peeler*)

  (objects (list *room* *pr2* *cutting-board* *potato* *peeler*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (set-larm) ~%")
  )

(defun set-larm ()
  (if (not (boundp '*peeler*))
      (progn
    (setq *peeler* (peeler))
    (send *peeler* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    (send *pr2* :rarm :end-coords :assoc *peeler*)))

  (setq *arrow* (arrow))
  (send *arrow* :newcoords (send *potato* :copy-worldcoords))

  (objects (list *room* *pr2* *cutting-board* *potato* *peeler* *arrow*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate #f(0 -100 100) :world)
  (send *pr2* :larm :inverse-kinematics (send *arrow* :copy-worldcoords))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 100 -100) :world)
  (send *pr2* :larm :inverse-kinematics (send *arrow* :copy-worldcoords))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  (send *ri* :start-grasp :larm :wait t)

  (warn "please run (peel-test1) or (peel-test2) ~%")  
  )

(defun peel-test1 ()
  (if (not (boundp '*potato*))
      (set-potato :w 90 :l 60 :h 60))
  
  (send *arrow* :newcoords (send *potato* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 180) :x :world)
  (send *arrow* :translate (float-vector (/ width 2) 0 (* height -1)))
  
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 皮剥き始める所
  (send *arrow* :translate (float-vector 0 0 (* 1 height)))
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 剥き終わり
  (send *arrow* :translate (float-vector (* (+ width 20) -1) 0 0))
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send p1 :set-color :moccasin)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "you can retry (peel-test1) , (peel-test2) or you want to finish please run (finish) ~%")
  )

(defun peel-test2 ()
  (if (not (boundp '*potato*))
      (set-potato :w 90 :l 60 :h 60))

  (send *arrow* :newcoords (send *potato* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 180) :x :world)
  (send *arrow* :translate (float-vector (/ width 2) 0 (* height -1)))
  
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 皮剥き始める所
  (send *arrow* :translate (float-vector 0 0 (+ (* 1 height) 10)))
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 剥き終わり
  (setq interval 10)
  (dotimes (i (+ (round (/ width interval)) 1))
    (send *arrow* :translate (float-vector (* interval -1) 0 0))
    (send *pr2* :rarm :inverse-kinematics
      *arrow*
      :move-target (car (send *peeler* :attention))
      :rotation-axis t
      :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)
    )

  (send p1 :set-color :moccasin)
  (send *viewer* :draw-objects)  
  
  (warn "you can retry (peel-test1) , (peel-test2) or you want to finish please run (finish) ~%")
  )


(defun finish ()
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :newcoords (send *potato* :copy-worldcoords))
  (send *arrow* :translate #f(0 -100 100) :world)
  (send *pr2* :larm :inverse-kinematics (send *arrow* :copy-worldcoords))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  )

(defun now-devel ()
  (setq s-time 0)

  (set-potato :w 90 :l 60 :h 60)  
  (set-peeler)
  (set-larm)
  )

(defun set-peel ()
  (set-potato :w 90 :l 60 :h 60)  
  (set-peeler)
  (set-larm)
  )

(defun exec-peel ()
  (set-potato :w 90 :l 60 :h 60)  
  (set-peeler)
  (set-larm)
  (peel-test1)
  )


(defun now-test ()
  (set-potato :w 90 :l 60 :h 60)  
  (set-larm)
  )



(defun test1 ()
  (unix:sleep 3)
  
  (set-potato :w 90 :l 60 :h 60)  
  (set-larm)

  (peel-test1)  
  )

(defun test2 ()
  (unix:sleep 3)
  
  (set-potato :w 90 :l 60 :h 60)  
  (set-larm)

  (peel-test2)  
  )
