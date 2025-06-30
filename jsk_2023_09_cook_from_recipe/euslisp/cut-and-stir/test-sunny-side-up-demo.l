#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/exec-cook-from-recipe-procedure.l")

(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/egg-crack-demo.l")

;; global variables
(setq *use-english* nil)

(defun sunny-side-up-init (&key (spot "counter")) ;; spotは counter stoveがある?
  (reset-view-list)
  (init-pr2)

  (pr2-cook-init :spot spot :type :sunny-side-up)
  )



