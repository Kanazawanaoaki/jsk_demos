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
  (send *arrow* :newcoords (make-coords :pos (float-vector 417.495 8067.248 30861.184) :rpy (float-vector 1.772 1.446 1.068)))
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
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 437.495 8087.248 30861.184) :rpy (float-vector 0.788 0.633 0.136)))

  (send *arrow* :newcoords (make-coords :pos (float-vector 417.495 8067.248 30861.184) :rpy (float-vector 1.772 1.446 1.068)))
  (send *arrow* :rotate (deg2rad -30) :y)

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
  (send *arrow* :newcoords (make-coords :pos (float-vector 457.495 8107.248 30901.184) :rpy (float-vector  0.701 -0.06 0.109)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
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

