#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/exec-cook-from-recipe-procedure.l")

(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/egg-crack-demo.l")

;; global variables
(setq *use-english* nil)
(setq *use-rec* t)

(defun sunny-side-up-init (&key (spot "counter")) ;; spotは counter stoveがある?
  (reset-view-list)
  (init-pr2)

  (pr2-cook-init :spot spot :type :sunny-side-up)
  )


(defun sunny-side-up-prepare (&key (spot "counter"))
  (sunny-side-up-init :spot spot)

  (cond
   ((equal spot "counter")

    (reset-cook-manip-pose :torso-lift 325)

    ;; gray bowl set
    (receive-and-set-gray-bowl :spot "counter")

    ;; set egg opener
    (receive-and-set-egg-opener :spot "counter")

    (reset-cook-manip-pose :torso-lift 325)
    )
   ((equal spot "stove")
    (reset-cook-manip-pose)

    ;; oil dispenser
    (receive-and-set-oil-dispenser)

    ;; frying pan
    (set-pot-on-stove :object-name "frying pan")

    (reset-cook-manip-pose)
    )
   (t
    (format t "spot ~A is not implemented now!!~%" spot)
    )
   ))


(defun 01-move-to-counter ()
  (move-to-spot "counter")

  ;; TODO Add to primitive?
  (reset-cook-manip-pose :torso-lift 325)
  )

(defun 02-hold-egg-opener ()
  (if *use-rec*
      (grasp-rec-object :object-name "egg opener" :arm :rarm :use-model "fp" :use-calib-offset nil)
    (pick-up-egg-opener :spot "counter" :arm :rarm :use-cds-offset nil)
    )

  ;; TODO Add to primitive
  (send *ri* :move-gripper :rarm 0.076)
  )

(defun 03-set-egg-opener (&key (egg-rec t))
  ;; from egg-crack-demo.l
  (egg-crack-set-rarm)
  (egg-crack-set-larm-grasp :use-rec egg-rec)
  (egg-crack-set-larm-carry)
  )

(defun 04-crack-egg-bowl ()
  ;; from egg-crack-demo.l
  (egg-crack-rarm :use-rec *use-rec*)
  )

(defun 05-place-egg-opener ()
  (place-egg-opener :spot "counter")
  )

(defun 06-hold-bowl ()
  (if *use-rec*
      (grasp-rec-object :object-name "gray bowl" :arm :rarm :spot "counter" :use-model "fp" :use-calib-offset nil)
    (pick-up-gray-bowl :spot "counter")
    )
  )

(defun 07-move-to-stove ()
  ;; TODO Add to primitive

  ;; TODO pose for move ()

  (move-to-spot "stove")
  )

(defun 08-hold-oil ()
  (if *use-rec*
      (grasp-rec-object :object-name "oil dispenser" :arm :larm :use-model "fp" :use-calib-offset nil)
    (pick-up-oil-dispenser)
    )
  )

(defun 09-pour-oil ()
  ;; TODO update
  ;; (pour-object-to-pan :from-object "あぶら" :to-object "フライパン" :arm :larm :spot-name "stove")
  ;; フライパンの認識を入れて，その座標を使って動くようにする. moveitを入れるか？

  )

(defun 10-place-oil ()
  (place-oil-dispenser)
  )

(defun 11-turn-on-stove ()
  (ih-stove-action :ih-action :start :with-hand-rec t :use-cds-offset nil)
  )

(defun 12-heat-

