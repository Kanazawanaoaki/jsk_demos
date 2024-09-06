(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/spatula.l")
(setq *spatula* (spatula))

(send *spatula* :translate #f(0 0 100) :world)

(objects (list *spatula*))

(defun view-coords ()
  (objects (list *spatula*))
  (send (send *spatula* :attention-attention0) :draw-on :flush t)
  ;; (send (send *spatula* :handle-handle0) :draw-on :flush t)
  )

(warn "please run (view-coords) ~%")
