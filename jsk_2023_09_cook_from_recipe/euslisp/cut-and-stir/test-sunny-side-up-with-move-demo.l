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
    (receive-and-set-gray-bowl :spot "counter" :use-cds-offset t)

    ;; set egg opener
    (receive-and-set-egg-opener :spot "counter" :use-cds-offset t)

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
  (place-egg-opener :spot "counter" :use-cds-offset nil)
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
  (reset-move-pose)

  (move-to-spot "stove")

  ;; pose after move
  (reset-move-pose :head-p 50 :torso 300)
  )

(defun 08-place-bowl ()
  ;; place gray bowl ;; TODO divide?
  (place-gray-bowl :spot "stove" :use-cds-offset t)
  )

(defun 09-hold-oil ()
  (if *use-rec*
      (grasp-rec-object :object-name "oil dispenser" :arm :larm :use-model "fp" :use-calib-offset nil)
    (pick-up-oil-dispenser)
    )
  )

(defun 10-pour-oil ()
  (if *use-rec*
      (pour-object-to-pan :from-object "あぶら" :to-object "フライパン" :arm :larm :spot-name "stove" :use-rec t)
    (pour-object-to-pan :from-object "あぶら" :to-object "フライパン" :arm :larm :spot-name "stove" :use-rec nil :replay-ec t)
    )
  )

(defun 11-place-oil ()
  (place-oil-dispenser :use-cds-offset t)
  (reset-cook-manip-pose)
  )

(defun 12-turn-on-stove ()
  (if *use-rec*
      (ih-stove-action :ih-action :start :with-hand-rec t :use-cds-offset nil)
    (ih-stove-action :ih-action :start :with-hand-rec nil :use-cds-offset nil)
    )
  )

(defun 13-heat-oil ()
  ;; wait
  (wait-cook-stove :object-name "oil" :state "thirty-seconds" :vessel "フライパン")
  )

(defun 14-hold-bowl ()
  (if *use-rec*
      (grasp-rec-object :object-name "gray bowl" :arm :rarm :spot "stove" :use-model "fp" :use-calib-offset nil)
    (pick-up-gray-bowl :spot "stove")
    )
  )

(defun 15-transfer-egg ()
  (if *use-rec*
      (pour-object-to-pan :from-object "gray bowl" :to-object "frying pan" :arm :rarm :spot-name "stove" :use-rec t)
    (pour-object-to-pan :from-object "gray bowl" :to-object "frying pan" :arm :rarm :spot-name "stove" :replay-ec t)
    )
  )

(defun 16-place-bowl ()
  (place-gray-bowl :spot "stove" :use-cds-offset t)
  )

(defun 17-cook-egg ()
  (wait-cook-stove :object-name "egg" :state "cooked-egg" :vessel "フライパン")
  )

(defun 18-turn-off-stove ()
  (if *use-rec*
      (ih-stove-action :ih-action :stop :with-hand-rec t :use-cds-offset nil)
    (ih-stove-action :ih-action :start :with-hand-rec nil :use-cds-offset nil)
    )
  )

;; TODO add 盛りつけ

(defun after-serving ()
  (now-finish-sunny-all :use-rec t :receive-from-human t)
  )

(defun do-all-sunny ()
  (sunny-side-up-init :spot "counter")

  (01-move-to-counter)

  (02-hold-egg-opener)
  (03-set-egg-opener)
  (04-crack-egg-bowl)
  (05-place-egg-opener)
  (06-hold-bowl)

  (07-move-to-stove)
  (08-place-bowl)

  (09-hold-oil)
  (10-pour-oil)
  (11-place-oil)
  (12-turn-on-stove)
  (13-heat-oil)
  (14-hold-bowl)
  (15-transfer-egg)
  (16-place-bowl)
  (17-cook-egg)
  (18-turn-off-stove)
  )

(defun counter-sunny (&key (egg-rec nil))
  (02-hold-egg-opener)
  (03-set-egg-opener :egg-rec egg-rec)
  (04-crack-egg-bowl)
  (05-place-egg-opener)
  (06-hold-bowl)
  )

(defun stove-test ()
  (09-hold-oil)
  (10-pour-oil)
  (11-place-oil)
  ;; (12-turn-on-stove)
  ;; (13-heat-oil)
  (14-hold-bowl)
  (15-transfer-egg)
  (16-place-bowl)
  ;; (17-cook-egg)
  ;; (18-turn-off-stove)
  )
