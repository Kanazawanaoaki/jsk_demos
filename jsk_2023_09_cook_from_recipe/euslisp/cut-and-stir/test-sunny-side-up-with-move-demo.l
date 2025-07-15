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

  ;; place gray bowl ;; TODO divide?
  (place-gray-bowl :spot "stove" :use-cds-offset t)
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
  (pour-object-to-pan :from-object "あぶら" :to-object "フライパン" :arm :larm :spot-name "stove" :use-rec t)
  )

(defun 10-place-oil ()
  (place-oil-dispenser)
  )

(defun 11-turn-on-stove ()
  (ih-stove-action :ih-action :start :with-hand-rec t :use-cds-offset nil)
  )

(defun 12-heat-oil ()
  ;; wait
  )

(defun 13-hold-bowl ()
  (if *use-rec*
      (grasp-rec-object :object-name "gray bowl" :arm :rarm :spot "stove" :use-model "fp" :use-calib-offset nil)
    (pick-up-gray-bowl :spot "stove")
    )
  )

(defun 14-transfer-egg ()
  ;; TODO update
  (if *use-rec*
      (pour-object-to-pan :from-object "gray bowl" :to-object "frying pan" :arm :rarm :spot-name "stove" :use-rec t)
    (pour-object-to-pan :from-object "gray bowl" :to-object "frying pan" :arm :rarm :spot-name "stove" :replay-ec t)
    )
  )

(defun 15-place-bowl ()
  (place-gray-bowl :spot "stove")
  )

(defun 16-cook-egg ()
  ;; TODO cook
  )

(defun 17-turn-off-stove ()
  (ih-stove-action :ih-action :stop :with-hand-rec t :use-cds-offset nil)
  )

;; (heat salad-oil frying-pan thirty-seconds)
;; (hold bowl arm2 stove)
;; (transfer egg bowl frying-pan arm2 stove)
;; (place bowl arm2 stove)
;; (cook egg cooked-egg)
;; (turn-off-stove middle frying-pan arm1)
