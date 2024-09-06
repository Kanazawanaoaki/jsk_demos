(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/spoon.l")
(setq *spoon* (spoon))

(send *spoon* :translate #f(0 0 100) :world)

(objects (list *spoon*))

(defun view-coords ()
  (objects (list *spoon*))
  (send (send *spoon* :attention-attention0) :draw-on :flush t)
  ;; (send (send *spoon* :handle-handle0) :draw-on :flush t)
  )

(warn "please run (view-coords) ~%")
