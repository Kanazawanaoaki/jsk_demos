#!/usr/bin/env roseus

;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_tmp.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/wrench.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/move-to-adjust.l")

;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/pr2_cut_food.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/tool-use-in-kitchen-codes.l")

(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/pr2-kitchen_knife_interface_for-integ.l")

(setq *debug-flag* t)
(setq *s-time* 3)


;; load objects
(unless (boundp '*cutting-board*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/cutting-board.l")
    (setq *cutting-board* (cutting-board))
    ))

(unless (boundp '*knife*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/knife-new-attention.l")
    (setq *knife* (knife))
    ))

(unless (boundp '*arrow*)
  (progn
    (load "models/arrow-object.l")
    (setq *arrow* (arrow))
    ))

(defun food-cut-init ()
  ;; init
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")

  ;; set objects coords, copy from https://github.com/Kanazawanaoaki/jsk_demos/blob/kanazawa-ow/jsk_2020_04_pr2_curry/euslisp/model/my-eng2-coords.l
  ;; (setq *kitchen-spot* (make-coords :pos (float-vector 1110 8500 30000) :rpy (float-vector pi 0 0))) ;; original

  ;; (setq *cutting-board-coords* (make-coords :pos (float-vector 560 8420 30840) :rpy (float-vector 0 0 0))) ;; original
  (setq *cutting-board-coords* (make-coords :pos (float-vector 550.0 80.0 840.0) :rpy (float-vector -3.142 0.0 0.0))) ;; fix

  ;; (setq *knife-coords* (make-coords :pos (float-vector 600 8715 30857) :rpy (float-vector 3.14 0.073 1.498))) ;; original
  (setq *knife-coords* (make-coords :pos (float-vector 510.0 -215.0 857.0) :rpy (float-vector -0.002 0.073 1.498))) ;; fix

  ;; set objects
  (if (not (eql (send *cutting-board* :parent) nil))
      (send (send *cutting-board* :parent) :dissoc *cutting-board*))
  (send *cutting-board* :newcoords (send *cutting-board-coords* :copy-worldcoords))

  (if (not (eql (send *knife* :parent) nil))
      (send (send *knife* :parent) :dissoc *knife*))
  (send *knife* :newcoords (send *knife-coords* :copy-worldcoords))

  ;; init pkki instance
  (unless (boundp '*pkki*)
    (progn
      (setq *pkki* (instance pr2-kitchen_knife-interface :init))
      ))

  ;; def global-coords

  ;; (move-to-kitchen-irt)
  ;; (objects (list *pr2* *scene* *cutting-board* *knife* *pot* *bowl-1*))
  ;; (update-view)
  ;; ;; for original coords
  ;; (send *pr2* :move-to (send *kitchen-spot* :copy-worldcoords) :world)

  (objects (list *pr2* *cutting-board* *knife* *arrow*))

  )

(food-cut-init)

;; (warn "If you use real robot, run (update-pos) ~%")
;; (warn "please run (slide-board-set) ~%")

(warn "~%")
;; (warn "(setq *pkki* (instance pr2-kitchen_knife-interface :init))~%")
(warn "(send *pkki* :init-cut-pose)~%")
(warn "(send *pkki* :grasp-object)~%")
(warn "~%")
(warn "(send *pkki* :test-execute-cut :rule-base)~%")
(warn "(send *pkki* :test-execute-cut :random1)~%")
(warn "(send *pkki* :test-execute-cut :nn)~%")
(warn "(send *pkki* :test-execute-cut :nn :y 10)~%")

