(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/whisk.l")
(setq *whisk* (whisk))

(send *whisk* :translate #f(0 0 100) :world)

(objects (list *whisk*))

(defun view-coords ()
  (objects (list *whisk*))
  (send (send *whisk* :attention-attention0) :draw-on :flush t)
  ;; (send (send *whisk* :handle-handle0) :draw-on :flush t)
  )

(warn "please run (view-coords) ~%")
