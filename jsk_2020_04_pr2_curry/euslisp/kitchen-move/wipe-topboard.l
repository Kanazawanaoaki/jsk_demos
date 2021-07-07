(load "../model/my-room73b2-scene.l")
(setq *room* (room73b2))

(load "package://pr2eus/pr2-interface.l")
(pr2-init)


;;  ;; set まな板
;; (load "../model/cutting-board.l")
;; (setq *cutting-board* (cutting-board))
;; (send *cutting-board* :transform (make-coords :pos (float-vector 500.0 2000.0 825.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))

;; set ふきん
(setq *wipe* (make-cube 100 230 5))
(send *wipe* :set-color :white)
(send *wipe* :transform (make-coords :pos (float-vector 500.0 2150.0 825.0) :rot #2f((1.0 2.449294e-16 0.0) (-2.449294e-16 1.0 0.0) (0.0 0.0 1.0))))

;; set objects
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

(objects (list *room* *pr2* *wipe* *arrow*))
(send *irtviewer* :look-all
      (geo::make-bounding-box 
       (flatten (send-all (send *pr2* :bodies) :vertices))))

(defun set-pose ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


(warn "please run (set-rarm) or (now-devel)~%")

(defun set-rarm ()
  (set-pose)
  
  (send *arrow* :newcoords (send *wipe* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 180) :z :world)
  (send *arrow* :rotate (deg2rad -90) :y :world)

  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :inverse-kinematics
    *arrow*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -100) :world)
  (send *pr2* :inverse-kinematics
    *arrow*
    :rotation-axis t
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  (send (send *pr2* :rarm :end-coords) :assoc *wipe*)

  (warn "please run (wipe)~%")
  )

(defun wipe ()
  (dotimes (i 3)
    (send *arrow* :translate #f(-50 0 0) :world)
    (send *pr2* :inverse-kinematics
      *arrow*
      :rotation-axis t
      :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
    (send *ri* :wait-interpolation)
    )
  (warn "please run (more)~%")
  )

(defun more ()
  (dotimes (i 3)
    (send *arrow* :translate #f(-50 0 0) :world)
    (send *pr2* :inverse-kinematics
      *arrow*
      :rotation-axis nil
      :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
    (send *ri* :wait-interpolation)
    )
  )

(defun one-more ()
  (send *arrow* :translate #f(-50 0 0) :world)
  (send *pr2* :inverse-kinematics
    *arrow*
    :rotation-axis nil
    :debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


(defun finish ()
  (send (send *pr2* :rarm :end-coords) :dissoc *wipe*)

  (set-pose)  
  )


(defun now-devel ()
  (set-rarm)
  (wipe)
  (more)
  )

(defun test ()
  (set-rarm)
  (wipe)
  (more)
  (one-more)
  )

(defun exec-wipe ()
  (set-rarm)
  (wipe)
  (more)
  )


