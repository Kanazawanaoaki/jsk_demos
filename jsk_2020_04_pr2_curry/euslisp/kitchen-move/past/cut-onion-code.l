(load "../model/my-room73b2-scene.l")
(setq *room* (room73b2))

(load "package://pr2eus/pr2-interface.l")
(pr2-init)


(defun grav-sim-func (abody floor)
  (setq t-flag nil)
  (until t-flag
     (send abody :translate #f(0 0 -1) :world)
     (send *viewer* :draw-objects)     
     (if (= (pqp-collision-check abody floor) 1)
         (setq t-flag t))
     )
  )



 ;; set まな板
(load "../model/cutting-board.l")
(setq *cutting-board* (cutting-board))
(send *cutting-board* :transform (make-coords :pos (float-vector 500.0 2000.0 820.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))

;; set objects
(load "../model/onion-test-model.l")
(load "../model/my-knife.l")
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
(setq length 90)
(setq height 60)

(warn "please run (set-onion :w 90 :l 90 :h 60) or (now-devel)~%")

(defun set-onion (&rest args &key (w 90) (l 90) (h 60) &allow-other-keys)

  (setq width w)
  (setq length l)
  (setq height h)
  
  (setq *onion* (onion :w w :l l :h h))
  (send *onion* :transform (make-coords :pos (float-vector 500.0 2000.0 (+ 830.0 (/ h 2))) :rot #2f((1.194340e-15 -1.0 0.0) (1.0 1.194340e-15 0.0) (0.0 0.0 1.0))))
  (send *onion* :rotate (deg2rad 90) :z :world)
  (send *onion* :cut)
  
  (objects (list *room* *pr2* *cutting-board* *onion*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (set-knife) ~%")
  )

(defun set-knife-ver ()
  ;; set pose
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; grasp knife
  (send *ri* :stop-grasp :rarm :wait t)
  ;; (send *ri* :speak-jp "包丁を握らせて下さい")
  (unix:sleep s-time)
  ;; (send *ri* :start-grasp :rarm :wait t)
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  
  (setq *knife* (knife))
  (send *knife* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *pr2* :rarm :end-coords :assoc *knife*)

  (objects (list *room* *pr2* *cutting-board* *onion* *knife*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (set-larm) ~%")
  )

(defun set-knife-hor ()
  ;; set pose
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; grasp knife
  (send *ri* :stop-grasp :rarm :wait t)
  ;; (send *ri* :speak-jp "包丁を握らせて下さい")
  (unix:sleep s-time)
  ;; (send *ri* :start-grasp :rarm :wait t)
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  
  (setq *knife* (knife))
  (send *knife* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *knife* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *knife*)

  (objects (list *room* *pr2* *cutting-board* *onion* *knife*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (set-larm) ~%")
  )

(defun set-larm ()
  (if (not (boundp '*knife*))
      (progn
      (setq *knife* (knife))
      (send *knife* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
      (send *pr2* :rarm :end-coords :assoc *knife*)))

  (setq *arrow* (arrow))
  (send *arrow* :newcoords (send *onion* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :z :world)

  (objects (list *room* *pr2* *cutting-board* *onion* *knife* *arrow*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))

  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate #f(0 -100 100) :world)
  (send *pr2* :larm :inverse-kinematics (send *arrow* :copy-worldcoords))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 70 -100) :world)
  (send *pr2* :larm :inverse-kinematics (send *arrow* :copy-worldcoords))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  (send *ri* :start-grasp :larm :wait t)

  (warn "please run (cut-test1) , (cut-test2) or (cut-test3) ~%")  
  )


(defun cut-test1 ()
  (if (not (boundp '*onion*))
      (set-onion :w 90 :l 90 :h 60))

  ;; 少し上に包丁を
  (send *arrow* :newcoords (send *cut-point-1* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 (* height 1)))  
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 (* height -1)))    
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "you can retry (cut-test1) , (cut-test2) , (cut-test3) or you want to finish please run (finish) ~%")
  )

(defun cut-test2 ()
  (if (not (boundp '*onion*))
      (set-onion :w 90 :l 90 :h 60))

  ;; 少し上に包丁を
  (send *arrow* :newcoords (send *cut-point-1* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 (* height 1)))  
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq interval 10)
  (dotimes (i (+ (round (/ height interval)) 1))
    (send *arrow* :translate (float-vector 0 0 (* interval -1)))
    (send *pr2* :rarm :inverse-kinematics
      *arrow*
      :move-target (car (send *knife* :attention))
      :rotation-axis t
      :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)
    )

  
  (warn "you can retry (cut-test1) , (cut-test2) , (cut-test3) or you want to finish please run (finish) ~%")
  )

(defun cut-test3 ()
  (if (not (boundp '*onion*))
      (set-onion :w 90 :l 90 :h 60))

  ;; 少し上に包丁を
  (send *arrow* :newcoords (send *cut-point-1* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 (* height 1)))  
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *knife* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq interval 10)
  (dotimes (i (+ (round (/ height interval)) 1))
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

    )
  
  (warn "you can retry (cut-test1) , (cut-test2) , (cut-test3) or you want to finish please run (finish) ~%")
  )

(defun true-coords ()
  (format t "now coords in eus: ~A ~%" (send (car (send *knife* :attention)) :copy-worldcoords))
  
  (send *ri* :state :potentio-vector)
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (format t "now real coords : ~A ~%" (send (car (send *knife* :attention)) :copy-worldcoords))

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
    (send *ri* :wait-interpolation)  
  ))

(defun finish ()
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :newcoords (send *onion* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :z :world)  
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

  (set-onion :w 90 :l 90 :h 60)  
  (set-knife-ver)
  (set-larm)
  )

(defun set-cut ()
  (set-onion :w 90 :l 90 :h 60)  
  (set-knife-ver)
  (set-larm)
  )

(defun exec-cut ()
  (set-onion :w 90 :l 90 :h 60)  
  (set-knife-ver)
  (set-larm)
  (cut-test3)
  )

(defun hor-test ()
  (set-onion :w 90 :l 90 :h 60)  
  (set-knife-hor)
  (set-larm)
  )



(defun now-test ()
  (set-onion :w 90 :l 90 :h 60)  
  (set-larm)
  )



(defun test1 ()
  (unix:sleep 3)
  
  (set-onion :w 90 :l 90 :h 60)  
  (set-larm)

  (cut-test1)  
  )

(defun test2 ()
  (unix:sleep 3)
  
  (set-onion :w 90 :l 90 :h 60)  
  (set-larm)

  (cut-test2)  
  )

(defun test3 ()
  (unix:sleep 3)
  
  (set-onion :w 90 :l 90 :h 60)  
  (set-larm)

  (cut-test3)  
  )
