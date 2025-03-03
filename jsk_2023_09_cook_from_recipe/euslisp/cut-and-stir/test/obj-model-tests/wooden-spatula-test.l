(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/wooden-spatula.l")
(setq *wooden-spatula* (wooden-spatula))

(setq *wooden-spatula-handle-cds* (make-cascoords :pos #f(-140 0 0) :rpy #f(0 0 -1.5171)))
(send *wooden-spatula* :assoc *wooden-spatula-handle-cds*)

(send *wooden-spatula* :translate #f(0 0 100) :world)

(objects (list *wooden-spatula*))

(defun view-coords ()
  (objects (list *wooden-spatula*))
  (send (send *wooden-spatula* :attention-attention0) :draw-on :flush t)
  ;; (send (send *wooden-spatula* :handle-handle0) :draw-on :flush t)
  )

(defun view-handle-coords ()
  (objects (list *wooden-spatula*))
  ;; (send (send *spatula* :attention-attention0) :draw-on :flush t)
  (send *wooden-spatula-handle-cds* :draw-on :flush t)
  ;; (send (send *spatula* :handle-handle0) :draw-on :flush t)
  )

(warn "please run (view-coords) ~%")
