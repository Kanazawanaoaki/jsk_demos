(defun arrangement-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  
  ;; set objects
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/curry-dish.l")
  (setq *curry-dish* (curry-dish))
  (send *curry-dish* :newcoords (send *curry-dish-coords* :copy-worldcoords))
  
  ;; def global coords

  (move-to-arrange-irt)
  (objects (list *pr2* *scene* *spatula* *ladle* *pot* *curry-dish*))
  (update-view)
  )

(arrangement-init)


(defun scoop-up-curry-1 ()
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 391.83 8092.564 30820) :rpy (float-vector -1.135 0.805 -1.056)))
  (send *arrow* :newcoords (make-coords :pos (float-vector 426 8039 30834) :rpy (float-vector -0.74 0.613 -1.132)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
	:move-target (elt (send *ladle* :attention) 1)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -30) :world)
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
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 420 8065 30870) :rpy (float-vector -1.525 0.066 -0.424)))

  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 473.293 8060.197 30859.318) :rpy (float-vector -0.608 0.452 -0.756)))
  
  ;; (send *arrow* :translate #f(0 0 -20) :world)

  (send *arrow* :translate #f(40 60 0) :world)
  
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
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 446.773 8053.785 30870) :rpy (float-vector -1.525 0.066 -0.424)))
  (send *arrow* :newcoords (make-coords :pos (float-vector 479 8064 30870) :rpy (float-vector -1.296 0.242 -0.152)))
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
  
  (send *pr2* :rarm :move-end-pos #f(0 0 50) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (carry-curry-set) ~%")
  )

(defun carry-curry-set ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 489.77 8042.025 31004.991) :rpy (float-vector -1.621 0.06 0.033)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (warn "please run (carry-curry) ~%")
  )


(defun carry-curry ()
  (dotimes (i 2)
    (send *pr2* :rarm :move-end-pos #f(0 100 0) :world)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)
    )  
  (warn "please run (transfer-curry-set) ~%")
  )

(defun transfer-curry-set ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 504.422 8343.425 30917.724) :rpy (float-vector -1.367 0.118 -0.067)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
	:move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (transfer-curry) ~%")
  )

(defun transfer-curry ()
  (send *arrow* :newcoords (send (elt (send *ladle* :attention) 1) :copy-worldcoords))
  
  (dotimes (i 9)
    (send *arrow* :rotate (deg2rad 10) :y :world)
    (send *pr2* :rarm :inverse-kinematics
	  (send *arrow* :copy-worldcoords)
	  :move-target (elt (send *ladle* :attention) 1)
	  :rotation-axis t
	  :debug-view *debug-flag*)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)
    )
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

(defun now-arrange-curry ()
  (scoop-up-curry)
  (carry-curry-set)
  (carry-curry)
  (transfer-curry-set)
  (transfer-curry)
  )
