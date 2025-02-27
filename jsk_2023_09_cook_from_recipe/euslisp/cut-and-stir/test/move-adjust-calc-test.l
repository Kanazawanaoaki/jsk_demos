#!/usr/bin/env roseus

(require :pr2-cook-utils "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/pr2_cut_food.l")

(require :kanazawa-roseus-utils "package://jsk_2023_09_cook_from_recipe/euslisp/kanazawa-roseus-utils.l")

(load "models/arrow-object.l")

(pr2-init)
(setq *arrow1* (arrow))
(setq *arrow2* (arrow))
(setq *arrow3* (arrow))

(objects (list *pr2* *arrow1* *arrow2* *arrow3*))

(setq *orig-rec-cds* (make-coords :pos #f(1383.108 144.926 1431.626) :rpy #f(0.843 1.55 -2.26)))
(setq *orig-rec-cds-2* (make-coords :pos #f(1397.201 143.851 1431.095) :rpy #f(2.956 1.47 -0.177)))

(setq *orig-frame-cds* (make-coords :pos #f(57.496 -23.784 1381.743) :rpy #f(-1.572 0.01 -1.536)))
(setq *orig-base-cds* (make-cascoords))

(setq *trans-frame-cds* (make-cascoords))
(send *trans-frame-cds* :newcoords (send *orig-frame-cds* :copy-worldcoords))
(setq *trans-base-cds* (make-cascoords))
(send *trans-base-cds* :newcoords (send *orig-base-cds* :copy-worldcoords))
(send *trans-base-cds* :assoc *trans-frame-cds*)
(send *trans-base-cds* :translate #f(300 -500 0) :world)
(send *trans-base-cds* :rotate (deg2rad 30) :z :world)
;; (send *trans-base-cds* :rotate (deg2rad -10) :x)

(setq *trans-rec-cds* (calc-rel-from-base-target *trans-base-cds* *orig-rec-cds*))

(send *arrow1* :newcoords (send *orig-rec-cds* :copy-worldcoords))
(send *arrow2* :newcoords (send *orig-frame-cds* :copy-worldcoords))
(send *arrow3* :newcoords (send *trans-frame-cds* :copy-worldcoords))

(calc-diffcds *trans-rec-cds* *orig-rec-cds* 0.1 0.1)
