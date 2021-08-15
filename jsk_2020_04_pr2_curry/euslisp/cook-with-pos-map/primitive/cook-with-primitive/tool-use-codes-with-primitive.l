(defun tool-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/my-cook-primitive-funcs.l")
  
  ;; set tools
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/knife-new-attention.l")
  (setq *knife* (knife))
  (send *knife* :newcoords (send *knife-coords* :copy-worldcoords))

  (load "package://jsk_2020_04_pr2_curry/euslisp/model/peeler.l")
  (setq *peeler* (peeler))
  (send *peeler* :newcoords (send *peeler-coords* :copy-worldcoords))

  (load "package://jsk_2020_04_pr2_curry/euslisp/model/potato-peeler.l")
  (setq *potato-peeler* (peeler))
  (send *potato-peeler* :newcoords (send *potato-peeler-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/spatula.l")
  (setq *spatula* (spatula))
  (send *spatula* :newcoords (send *spatula-coords-1* :copy-worldcoords))

  (load "package://jsk_2020_04_pr2_curry/euslisp/model/ladle.l")
  (setq *ladle* (ladle))
  (send *ladle* :newcoords (send *ladle-coords-1* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/cooking-pot-73b2.l")
  (setq *pot* (cooking-pot))
  (send *pot* :newcoords (send *pot-coords* :copy-worldcoords))
  
  ;; set equipment
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/shelf-door.l")
  (setq *shelf-door* (shelf-door))
  (send *shelf-door* :newcoords (send *shelf-door-coords* :copy-worldcoords))

  (setq *shelf-look-coords* (send (send *shelf-door* :handle-handle0) :copy-worldcoords))

  ;; (move-to-kitchen-irt)
  (move-to-spot-irt *kitchen-spot*)
  (objects (list *pr2* *peeler* *knife* *potato-peeler* *scene* *spatula* *ladle* *shelf-door*))
  (update-view)

  )

(tool-init)

;; set codes
(warn "~%  If you use real robot, run (update-pos) ~%")
(warn "please run (now-set-tools) or (set-knife) ~%")

