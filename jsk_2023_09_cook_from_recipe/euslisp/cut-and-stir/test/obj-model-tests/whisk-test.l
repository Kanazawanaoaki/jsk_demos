(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/whisk.l")
(setq *whisk* (whisk))

(setq *whisk-handle-cds* (make-cascoords :pos #f(-120 0 0) :rpy #f(0 0 -1.5171)))
(send *whisk* :assoc *whisk-handle-cds*)

(send *whisk* :translate #f(0 0 100) :world)

(objects (list *whisk*))

(defun view-coords ()
  (objects (list *whisk*))
  (send (send *whisk* :attention-attention0) :draw-on :flush t)
  ;; (send (send *whisk* :handle-handle0) :draw-on :flush t)
  )

(defun view-handle-coords ()
  (objects (list *whisk*))
  ;; (send (send *spatula* :attention-attention0) :draw-on :flush t)
  (send *whisk-handle-cds* :draw-on :flush t)
  ;; (send (send *spatula* :handle-handle0) :draw-on :flush t)
  )

(warn "please run (view-coords) ~%")
