(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/cooking-pan-73b2.l")
(setq *pan* (cooking-pan))

(defun view-pan-coords ()
  (objects (list *pan*))
  (send (send *pan* :attention-attention0) :draw-on :flush t)
  (send (send *pan* :handle-handle0) :draw-on :flush t)
  )

(objects (list *pan*))

(warn "please run (view-pan-coords)~%")
