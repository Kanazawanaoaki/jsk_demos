(defun bowl-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/cook-with-primitive/tool-use-codes-with-primitive.l")
  
  ;; set objects
  (send *spatula* :newcoords (send *spatula-coords-1* :copy-worldcoords)) ;; spatula on the cutting board
  (send *pot* :newcoords (send *pot-coords* :copy-worldcoords))
  
  (unless (boundp '*mcup*)
    (progn
      (load "package://jsk_2020_04_pr2_curry/euslisp/model/measuring-cup-73b2.l")
      (setq *mcup* (measuring-cup-73b2))
      ))
  (if (not (eql (send *mcup* :parent) nil))
      (send (send *mcup* :parent) :dissoc *mcup*))
  (send *mcup* :newcoords (send *mcup-coords* :copy-worldcoords))

  (unless (boundp '*rcup*)
    (progn
      (load "package://jsk_2020_04_pr2_curry/euslisp/model/red-cup.l")
      (setq *rcup* (red-cup))
      ))
  (if (not (eql (send *rcup* :parent) nil))
      (send (send *rcup* :parent) :dissoc *rcup*))
  (send *rcup* :newcoords (send *rcup-coords* :copy-worldcoords))
  
  (unless (boundp '*bowl-1*)
    (progn
      (load "package://jsk_2020_04_pr2_curry/euslisp/model/bowl-1.l")
      (setq *bowl-1* (bowl-1))
      ))
  (if (not (eql (send *bowl-1* :parent) nil))
      (send (send *bowl-1* :parent) :dissoc *bowl-1*))
  ;; (send *bowl-1* :newcoords (send *bowl-1-stove-coords* :copy-worldcoords))
  (send *bowl-1* :newcoords (send *bowl-1-kitchen-coords* :copy-worldcoords))
  
  ;; (unless (boundp '*bowl-2*)
  ;;   (progn
  ;;     (load "package://jsk_2020_04_pr2_curry/euslisp/model/bowl-2.l")
  ;;     (setq *bowl-2* (bowl-2))
  ;;     ))
  ;; (send *bowl-2* :newcoords (send *bowl-2-coords* :copy-worldcoords))
  
  ;; (unless (boundp '*bowl-3*)
  ;;   (progn
  ;;     (load "package://jsk_2020_04_pr2_curry/euslisp/model/bowl-3.l")
  ;;     (setq *bowl-3* (bowl-3))
  ;;     ))
  ;; (send *bowl-3* :newcoords (send *bowl-3-coords* :copy-worldcoords))
  
  ;; (unless (boundp '*bowl-4*)
  ;;   (progn
  ;;     (load "package://jsk_2020_04_pr2_curry/euslisp/model/bowl-4.l")
  ;;     (setq *bowl-4* (bowl-4))
  ;;     ))
  ;; (send *bowl-4* :newcoords (send *bowl-4-coords* :copy-worldcoords))
  
  
  (unless (boundp '*oil-dispenser*)
    (progn
      (load "package://jsk_2020_04_pr2_curry/euslisp/model/dispenser.l")
      (setq *oil-dispenser* (dispenser))
      ))
  (if (not (eql (send *oil-dispenser* :parent) nil))
      (send (send *oil-dispenser* :parent) :dissoc *oil-dispenser*))
  (send *oil-dispenser* :newcoords (send *oil-dispenser-coords* :copy-worldcoords))
  
  (objects (list *pr2* *scene* *spatula* *mcup* *rcup* *ladle* *pot* *bowl-1* *oil-dispenser*))
  (update-view)
  
  ;; def bowl grasp coords
  ;; (setq *bowl-1-grasp-coords* (make-coords :pos (float-vector 383 8425 30889) :rpy (float-vector 2.892 1.01 1.404))) 
  (setq *bowl-1-grasp-coords* (make-coords :pos (float-vector 379.901 8646.113 30889.23) :rpy (float-vector 2.699 0.835 -1.841)))

  (setq *bowl-1-change-rarm-coords* (make-coords :pos (float-vector 506.328 8618.878 31080.768) :rpy (float-vector -1.592 1.41 1.516)))
  (setq *bowl-1-change-larm-coords* (make-coords :pos (float-vector 482.945 8455.349 31079.694) :rpy (float-vector 1.626 1.32 1.482)))
  
  (setq *bowl-2-grasp-coords* (make-coords :pos (float-vector 344 8616 30880) :rpy (float-vector 3.016 0.995 1.718)))
  (setq *bowl-2-grasp-set-coords* (make-coords :pos (float-vector 558.94 8455.526 30890.992) :rpy (float-vector -2.649 1.102 1.301)))
  (setq *bowl-2-grasp-set-larm-coords* (make-coords :pos (float-vector 550.455 8389.4 30870.472) :rpy (float-vector 3.006 0.965 1.642)))
  
  (setq *bowl-3-grasp-coords* (make-coords :pos (float-vector 672 7632 30873) :rpy (float-vector -2.152 1.02 1.606)))
  (setq *bowl-4-grasp-coords* (make-coords :pos (float-vector 567 7824 30920) :rpy (float-vector -2.624 1.195 2.113)))
  
  ;; (move-to-kitchen-irt)
  (move-to-spot-irt *kitchen-spot*)
  )


(bowl-init)
