(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/wood-spatula.l")
(setq *wood-spatula* (wood-spatula))

(objects (list *wood-spatula*))

(defun view-coords ()
  (objects (list *wood-spatula*))
  (send (send *wood-spatula* :attention-attention0) :draw-on :flush t)
  ;; (send (send *wood-spatula* :handle-handle0) :draw-on :flush t)
  )

(warn "please run (view-coords) ~%")
