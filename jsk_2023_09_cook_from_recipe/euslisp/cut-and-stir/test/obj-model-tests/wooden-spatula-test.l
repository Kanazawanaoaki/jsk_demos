(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/wooden-spatula.l")
(setq *wooden-spatula* (wooden-spatula))

(send *wooden-spatula* :translate #f(0 0 100) :world)

(objects (list *wooden-spatula*))

(defun view-coords ()
  (objects (list *wooden-spatula*))
  (send (send *wooden-spatula* :attention-attention0) :draw-on :flush t)
  ;; (send (send *wooden-spatula* :handle-handle0) :draw-on :flush t)
  )

(warn "please run (view-coords) ~%")
