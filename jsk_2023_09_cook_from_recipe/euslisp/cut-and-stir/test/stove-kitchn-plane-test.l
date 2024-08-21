(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/stove-kitchen-plane.l")
(setq *stove-kitchen-plane* (stove-kitchen-plane))
;; (send *bowl-1* :translate #f(-500 0 0))

;; (setq *cube* (make-cube 230 10 105))
;; (send *cube* :translate #f(0 200 52.5))

;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/gray-bowl.l")
;; (setq *gray-bowl* (gray-bowl))

(objects (list *stove-kitchen-plane*))
