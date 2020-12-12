(load "../model/my-room73b2-scene.l")
(setq *room* (room73b2))

(load "package://pr2eus/pr2-interface.l")
(pr2-init)

;; kitchen
(load "models/room73b2-kitchen-object.l")
(setq *kitchen* (room73b2-kitchen))
(send *kitchen* :transform (make-coords :pos (float-vector 305.0 2175.0 20.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))

 ;; set まな板
(load "../model/cutting-board.l")
(setq *cutting-board* (cutting-board))
(send *cutting-board* :transform (make-coords :pos (float-vector 500.0 2000.0 840.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))


;; set objects
(load "../model/peeler.l")
(load "../model/my-knife.l")
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

;; def global values
(setq s-time 4)

;; set carrot
;; (setq width1 20)
;; (setq width2 180)
(setq width 160)
(setq length 50)
(setq height 50)

(load "../model/carrot-test-new-type.l")
(setq *carrot* (carrot :w width :l length :h height))
(send *carrot* :transform (make-coords :pos (float-vector 500.0 2000.0 (+ 850.0 (/ height 2))) :rot #2f((1.194340e-15 -1.0 0.0) (1.0 1.194340e-15 0.0) (0.0 0.0 1.0))))
(send *carrot* :cut)

(objects (list *kitchen* *pr2* *cutting-board* *carrot*))
(send *irtviewer* :look-all
      (geo::make-bounding-box 
       (flatten (send-all (send *pr2* :bodies) :vertices))))
(send *viewer* :draw-objects)


(warn "please run (set-knife-ver)~%")

(defun set-larm ()
  (if (not (boundp '*peeler*))
      (progn
    (setq *peeler* (peeler))
    (send *peeler* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    (send *pr2* :rarm :end-coords :assoc *peeler*)))

  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 250) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send *carrot* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 20) :y)

  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate (float-vector 0 (- (+ (* (/ width 6) -5) 15) 20) 100) :world)
  (send *pr2* :larm :inverse-kinematics (send *arrow* :copy-worldcoords))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 20 -100) :world)
  (send *arrow* :translate #f(0 0 -20) :world)
  (send *pr2* :larm :inverse-kinematics (send *arrow* :copy-worldcoords))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  (send *ri* :start-grasp :larm :wait t)

  (warn "please run (cut-test3) ~%")  
  )


(defun move-carrot ()
  (send c2 :dissoc c1)
  (send c1 :translate #f(0 100 0) :world)
  (send *viewer* :draw-objects)

  (warn "(change-peeler)~&")
  )


(defun change-peeler ()
  ;; set pose
  (send *arrow* :newcoords (make-coords :pos #f(700.191 2189.104 866.677) :rpy #f(-2.341 -0.222 -0.482)))
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (send *ri* :stop-grasp :rarm :wait t)
  
  ;; grasp knife
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

  (warn "please run (peel-test) ~%")
  )

(defun peel-test ()
  ;; (if (not (boundp '*potato*))
  ;;     (set-potato :w 90 :l 60 :h 60))

  (setq *larm-peel-coords* (send (send *pr2* :larm :end-coords) :copy-worldcoords))

  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 250) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (send *arrow* :translate #f(-150 0 0) :world)
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;     (send *arrow* :copy-worldcoords)
  ;;     :rotation-axis nil
  ;;     :debug-view t)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  ;; (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 180) :z)
  ;; (send *arrow* :translate (float-vector 0 0 (* 1 height)) :world)
  
  (send *arrow* :translate (float-vector 0 30 (* 1 height)) :world)

  ;; (send *arrow* :rotate (deg2rad 20) :y)
  (send *arrow* :rotate (deg2rad 40) :y)
  (send *arrow* :translate (float-vector 0 100 100) :world)

  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 -100 -100) :world)

  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 皮剥き始める所
  ;; (send *arrow* :translate (float-vector 0 0 (* -1 height)) :world)

  (send *arrow* :translate (float-vector 0 0 (- (* -1 height) 20)) :world)

  ;;調整
  (send *arrow* :translate (float-vector 10 0 0) :world)

  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 剥き終わり
  (send *arrow* :translate (float-vector 0 (* (+ width 20) 1) 0) :world)
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :move-target (car (send *peeler* :attention))
    :rotation-axis t
    :debug-view t)
  ;; (send p1 :set-color :moccasin)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "you can retry (peel-test1) , (peel-test2) or you want to finish please run (finish) ~%")
  )

;; (defun peel-test ()

;;   (setq *larm-peel-coords* (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  
;;   (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
;;   (send *arrow* :rotate (deg2rad 180) :z)
;;   (send *arrow* :translate (float-vector 0 0 (* 1 height)) :world)
;;   (send *arrow* :rotate (deg2rad 20) :y)
  
;;   (send *pr2* :rarm :inverse-kinematics
;;     *arrow*
;;     :move-target (car (send *peeler* :attention))
;;     :rotation-axis t
;;     :debug-view t)
;;   (send *viewer* :draw-objects)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
;;   (send *ri* :wait-interpolation)

;;   ;; 皮剥き始める所
;;   (send *arrow* :translate (float-vector 0 0 (* -1 height)) :world)
;;   (send *pr2* :rarm :inverse-kinematics
;;     *arrow*
;;     :move-target (car (send *peeler* :attention))
;;     :rotation-axis t
;;     :debug-view t)
;;   (send *viewer* :draw-objects)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
;;   (send *ri* :wait-interpolation)

;;   ;; 剥き終わり
;;   (send *arrow* :translate (float-vector 0 (* (+ width 20) 1) 0) :world)
;;   (send *pr2* :rarm :inverse-kinematics
;;     *arrow*
;;     :move-target (car (send *peeler* :attention))
;;     :rotation-axis t
;;     :debug-view t)
;;   (send *viewer* :draw-objects)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
;;   (send *ri* :wait-interpolation)
  
;;   (warn "you can retry (peel-test) or (finish-pose)~%")
;;   )

(defun finish-pose ()
  ;; set pose
  (send *arrow* :newcoords (make-coords :pos #f(700.191 2189.104 866.677) :rpy #f(-2.341 -0.222 -0.482)))
  (send *pr2* :rarm :inverse-kinematics
    *arrow*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (warn "please run (put-carrot)~%")
  )

(defun put-carrot ()
  (send *pr2* :larm :end-coords :assoc *carrot*)
  
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send *cut-point-1* :copy-worldcoords))
  (send *arrow* :translate #f(0 0 -170) :world)
  (send *arrow* :rotate (deg2rad 90) :x)

  (send *arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :move-target *cut-point-1*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  (setq *larm-put-coords0* (send (send *pr2* :larm :end-coords) :copy-worldcoords))

  
  (send *arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :move-target *cut-point-1*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq *larm-put-coords* (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *carrot* :worldcoords)

  (send *ri* :stop-grasp :larm :wait t)
  (send *pr2* :larm :end-coords :dissoc *carrot*)
  
  ;; (send *arrow* :newcoords (make-coords :pos (send (send *carrot* :copy-worldcoords) :worldpos)))
  ;; (send *arrow* :rotate (deg2rad 90) :z)
  ;; (send *arrow* :translate #f(0 -100 100) :world)
  ;; (send *pr2* :larm :inverse-kinematics
  ;;     (send *arrow* :copy-worldcoords)
  ;;     :rotation-axis t
  ;;     :debug-view t)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  ;; (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send *larm-put-coords* :copy-worldcoords))
  (send *arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq *larm-wait-coords* (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  
  (warn "please run (next-grasp)~&")
  )

(defun next-grasp ()
  ;;
  (send *arrow* :newcoords (send *carrot* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 20) :y)
  ;; (send *arrow* :translate (float-vector 0 0 width2) :world)
  (send *arrow* :translate (float-vector 0 0 (- (* (/ width 6) 5) 15)) :world)
  (send *arrow* :rotate (deg2rad -30) :z :world)

  (send *pr2* :larm :inverse-kinematics (send *arrow* :copy-worldcoords))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq *larm-grasp-coords* (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send (send *pr2* :larm :end-coords) :assoc *carrot*)
  ;; (send *ri* :stop-grasp :larm :wait t)

  (send *ri* :start-grasp :larm :wait t)
  
  (warn "please run (set-peel)~&")
  )

(defun set-peel ()
  (send *arrow* :newcoords (send *larm-peel-coords* :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics (send *arrow* :copy-worldcoords) :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics (send *arrow* :copy-worldcoords) :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
 
  (warn "please run (peel-test2) or (next-set)~&")
  )

(defun peel-test2 ()
  (peel-test)

  (warn "please run (finish-pose2)~&")
  )

(defun finish-pose2 ()
  (finish-pose)
  (warn "please run (put-carrot2)~&")  
  )

(defun put-carrot2 ()
  (send *pr2* :larm :end-coords :assoc *carrot*)
  
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send *larm-put-coords0* :copy-worldcoords))
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send *larm-put-coords* :copy-worldcoords))
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm :wait t)
  (send *pr2* :larm :end-coords :dissoc *carrot*)
  
  (send *arrow* :newcoords (send *larm-wait-coords* :copy-worldcoords))
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (next-grasp2)~&")
  )

(defun next-grasp2 ()
  (send *pr2* :larm :inverse-kinematics (send *larm-grasp-coords* :copy-worldcoords))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send (send *pr2* :larm :end-coords) :assoc *carrot*)
  ;; (send *ri* :stop-grasp :larm :wait t)
  
  (send *ri* :start-grasp :larm :wait t)
  (warn "please run (set-peel2)~&")  
  )

(defun set-peel2 ()
  (set-peel)
  
  )


(move-carrot)


(warn "please run (exec-all)~&")  

(defun exec-all ()

  (set-larm)
  ;; (cut-test3)
  ;; (move-carrot)
  (change-peeler)
  (peel-test)
  (finish-pose)
  (put-carrot)
  (next-grasp)
  (set-peel)
  )



(defun next-set ()
  (peel-test2)
  (finish-pose2)
  (put-carrot2)
  (next-grasp2)
  (set-peel2)
  )

(defun now-test ()

  (set-larm)
  ;; (change-peeler)
  (peel-test)
  (finish-pose)
  (put-carrot)
  (next-grasp)
  (set-peel)
  
  )
