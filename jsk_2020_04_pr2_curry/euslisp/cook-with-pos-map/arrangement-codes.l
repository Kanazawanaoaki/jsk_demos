(defun arrangement-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  
  ;; set objects

  ;; TODO set curry-dish model
  
  
  ;; def global coords

  ;; (setq *dish-pour-codes* (make-coords :pos (float-vector )))
  
  (move-to-kitchen-irt)
  (objects (list *pr2* *scene* *spatula* *ladle* *pot*))
  (update-view)
  )

(arrangement-init)


(defun scoop-up-curry-1 ()
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 391.83 8092.564 30840) :rpy (float-vector -1.135 0.805 -1.056)))
  (send *arrow* :newcoords (make-coords :pos (float-vector 391.83 8092.564 30820) :rpy (float-vector -1.135 0.805 -1.056)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
	:move-target (elt (send *ladle* :attention) 1)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun scoop-up-curry-2 ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 420 8065 30870) :rpy (float-vector -1.525 0.066 -0.424)))
  (send *pr2* :rarm :inverse-kinematics  
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun scoop-up-curry-3 ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 446.773 8053.785 30870) :rpy (float-vector -1.525 0.066 -0.424)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun scoop-up-curry ()
  (scoop-up-curry-1)
  (scoop-up-curry-2)
  (scoop-up-curry-3)

  (dotimes (i 3)
    (send *pr2* :rarm :move-end-pos #f(0 0 50) :world)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)
    )

  )

(defun transfer-curry ()
  (send *pr2* :rarm :move-end-pos #f(0 100 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  )


(defun tmp-set ()
  (update-pos)
  (set-ladle)
  )

(defun now-test ()
  (set-pose)
  (set-ladle)
  (grasp-pot-from-below)
  (look-at-pot)
  (mix-with-ladle-set)

  ;; (scoop-up-curry)
  
  ;; (mix-with-ladle)
  ;; (wait-pose-ladle)
  ;; (avoid-rarm-ladle)
  ;; (release-pot-from-below)
  )

