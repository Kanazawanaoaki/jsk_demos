(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/spatula.l")
(setq *spatula* (spatula))
(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/old-spatula.l")
(setq *old-spatula* (spatula))

(setq *spatula-handle-cds* (make-cascoords :pos #f(-160 0 0) :rpy #f(0 0 -1.5171)))
(send *spatula* :assoc *spatula-handle-cds*)
(send *spatula* :translate #f(0 0 100) :world)

(setq *old-spatula-handle-cds* (make-cascoords :pos #f(0 0 0)))
(send *old-spatula-handle-cds* :rotate (deg2rad -90) :x)
(send *old-spatula* :assoc *old-spatula-handle-cds*)
(send *old-spatula* :translate #f(0 0 100) :world)
(send *old-spatula* :translate #f(0 -100 0) :world)

(objects (list *spatula* *old-spatula*))

(defun view-coords ()
  (objects (list *spatula*))
  (send (send *spatula* :attention-attention0) :draw-on :flush t)
  ;; (send (send *spatula* :handle-handle0) :draw-on :flush t)
  )

(defun view-handle-coords ()
  (objects (list *spatula* *old-spatula*))
  ;; (send (send *spatula* :attention-attention0) :draw-on :flush t)
  (send *spatula-handle-cds* :draw-on :flush t)
  ;; (send (send *spatula* :handle-handle0) :draw-on :flush t)
  )

(defun view-old-handle-coords ()
  (objects (list *spatula* *old-spatula*))
  ;; (send (send *spatula* :attention-attention0) :draw-on :flush t)
  (send *old-spatula-handle-cds* :draw-on :flush t)
  ;; (send (send *spatula* :handle-handle0) :draw-on :flush t)
  )

(warn "please run (view-coords) ~%")
