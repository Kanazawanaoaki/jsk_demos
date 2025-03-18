#!/usr/bin/env roseus

(require :pr2-cooking-actions-funcs "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/pr2-cooking-actions-funcs.l")


(setq move-suc-flag (move-to-spot "stove"))
(if move-suc-flag
    (progn
      (reset-cook-pose)
      (ih-stove-action :with-hand-rec t)
      (ih-stove-action :with-hand-rec t :ih-action :stop)
      ))
