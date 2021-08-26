(defun garbage-codes-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")
  
  ;; trashbox (garbage-can)
  (load "models/room73b2-trashbox0-object.l")
  (setq *trashbox0* (room73b2-trashbox0))
  (send *trashbox0* :newcoords (send *trashbox0-coords* :copy-worldcoords))
  
  
  (move-to-garbage-irt)
  (objects (list *pr2* *scene* *trashbox0*))
  (update-view)
  )

(garbage-codes-init)


(warn "please run (grasp-garbage-tmp) or (now-garbage-tmp)~%")

(defun grasp-garbage-tmp ()
  (send *ri* :stop-grasp :larm :wait t)

  ;; ゴミを掴む位置
  (send *arrow* :newcoords (make-coords :pos #f(2502.124 9056.192 30962.518) :rpy #f(-0.073 -0.079 3.141)))
  
  (send *arrow* :translate #f(-200 0 0))  
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(200 0 0))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :larm :wait t)

  (warn "please run (transfer-garbage) ~%")
  )

(defun transfer-garbage ()
  (send *pr2* :larm :move-end-pos #f(-100 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 0 100) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 100 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (throw-away-garbage) ~%")
  )

(defun throw-away-garbage ()
  (send *arrow* :newcoords (make-coords :pos #f(2465.47 9326.908 30962.518) :rpy #f(-0.073 -0.079 3.141)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm :wait t)

  (send *pr2* :larm :move-end-pos #f(-100 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun now-garbage-tmp ()
  (set-pose)
  (grasp-garbage-tmp)
  (transfer-garbage)
  (throw-away-garbage)
  (set-pose)
  )
