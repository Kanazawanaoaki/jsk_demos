(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/stove-kitchen-plane.l")
(setq *stove-kitchen-plane* (stove-kitchen-plane))
;; (send *bowl-1* :translate #f(-500 0 0))

;; (setq *cube* (make-cube 230 10 105))
;; (send *cube* :translate #f(0 200 52.5))

;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/gray-bowl.l")
;; (setq *gray-bowl* (gray-bowl))

(objects (list *stove-kitchen-plane*))


(defun view-plane-coords ()
  (send (send *stove-kitchen-plane* :attention-attention0) :draw-on :flush t)
  (send (send *stove-kitchen-plane* :attention-attention1) :draw-on :flush t)
  (send (send *stove-kitchen-plane* :attention-attention2) :draw-on :flush t)
  (send (send *stove-kitchen-plane* :attention-attention3) :draw-on :flush t)
  )

(defun view-stove-coords ()
  (send (send *stove-kitchen-plane* :attention-attention4) :draw-on :flush t)
  (send (send *stove-kitchen-plane* :attention-attention5) :draw-on :flush t)
  (send (send *stove-kitchen-plane* :attention-attention6) :draw-on :flush t)
  (send (send *stove-kitchen-plane* :attention-attention7) :draw-on :flush t)
  )

(defun view-ih-coords ()
  (send (send *stove-kitchen-plane* :attention-attention8) :draw-on :flush t)
  (send (send *stove-kitchen-plane* :attention-attention9) :draw-on :flush t)
  )
