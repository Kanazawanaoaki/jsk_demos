(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/cooking-pot-73b2.l")
(setq *pot* (cooking-pot))

(objects (list *pot*))

(defun view-pot-coords ()
  (objects (list *pot*))
  (send (send *pot* :attention-attention0) :draw-on :flush t)
  (send (send *pot* :handle-handle0) :draw-on :flush t)
  )

(defun view-water ()
  (setq *water* (send *pot* :water))
  (send *water* :set-color :Blue)
  (objects *water*)
  )
