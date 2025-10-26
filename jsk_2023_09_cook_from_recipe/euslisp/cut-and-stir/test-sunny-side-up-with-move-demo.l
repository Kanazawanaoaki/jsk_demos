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

(defun 03-set-egg-opener (&key (egg-rec t) (rarm-gripper 0.076))
  ;; from egg-crack-demo.l
  (egg-crack-set-rarm :rarm-gripper rarm-gripper)
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

(defun 13-heat-oil (&key (state-rec t))
  (if state-rec
      (wait-cook-stove :object-name "oil" :state "thirty-seconds" :vessel "フライパン")
    (progn
      (print "wait for key pressed (not state-rec)")
      (do-until-key
       (unix:usleep 100000)
       )
      ))
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

(defun 17-cook-egg (&key (state-rec t))
  (if
      (wait-cook-stove :object-name "egg" :state "cooked-egg" :vessel "フライパン")
      (progn
        (print "wait for key pressed (not state-rec)")
        (do-until-key
         (unix:usleep 100000)
         )
        ))
  )

(defun 18-turn-off-stove ()
  (if *use-rec*
      (ih-stove-action :ih-action :stop :with-hand-rec t :use-cds-offset nil)
    (ih-stove-action :ih-action :start :with-hand-rec nil :use-cds-offset nil)
    )
  )

;; TODO add 盛りつけ

(defun after-serving ()
  ;; (now-finish-sunny-all :use-rec t :receive-from-human t)
  (now-finish-sunny-all :use-rec t :receive-from-human nil)
  )

(defun do-all-sunny (&key (egg-rec t) (use-stove t) (state-rec t) (after-serv t))

  ;; (01-move-to-counter)
  (sunny-side-up-init :spot "counter")

  (02-hold-egg-opener)
  (03-set-egg-opener :egg-rec egg-rec)
  (04-crack-egg-bowl)
  (05-place-egg-opener)
  (06-hold-bowl)

  (07-move-to-stove)

  (sunny-side-up-init :spot "stove")
  (08-place-bowl)

  (09-hold-oil)
  (10-pour-oil)
  (11-place-oil)
  (when use-stove
    (12-turn-on-stove)
    (13-heat-oil :state-rec state-rec)
    )
  (14-hold-bowl)
  (15-transfer-egg)
  (16-place-bowl)
  (when use-stove
    (17-cook-egg :state-rec state-rec)
    (18-turn-off-stove)
    )

  (when after-serv
    (after-serving)
    )
  )

(defun counter-sunny (&key (egg-rec nil))
  (02-hold-egg-opener)
  (03-set-egg-opener :egg-rec egg-rec)
  (04-crack-egg-bowl)
  (05-place-egg-opener)
  (06-hold-bowl)
  )

(defun stove-test (&key (use-stove t) (state-rec t) (after-serv t))
  (09-hold-oil)
  (10-pour-oil)
  (11-place-oil)
  (when use-stove
    (12-turn-on-stove)
    (13-heat-oil :state-rec state-rec)
    )
  (14-hold-bowl)
  (15-transfer-egg)
  (16-place-bowl)
  (when use-stove
    (17-cook-egg :state-rec state-rec)
    (18-turn-off-stove)
    )
  (when after-serv
    (after-serving)
    )
  )

(defun tmp-test (&key (egg-rec t))
  (02-hold-egg-opener)
  (03-set-egg-opener :egg-rec egg-rec)
  )


;; based egg
(defun tmp-grasp-cup ()
  (grasp-rec-object :object-name "green cup" :arm :rarm :use-model "fp" :use-calib-offset nil)
  )

(defun tmp-place-cup ()
  (grasp-object-primitive :pre-set-avs (list #f(-67.4806 22.6647 -67.2305 -103.326 320.791 -69.2717 32.752)
                                             #f(-43.0503 5.86039 -40.3291 -96.6655 234.657 -109.14 34.4596))
                          :grasp-coords (make-coords :pos #f(720.31 -394.36 898.012) :rpy #f(-0.023 0.751 -3.114))
                          :pre-set-val #f(-100 0 0)
                          :arm :rarm
                          :action-mode :place
                          :object-name "green cup")
  )

(defun tmp-pour-cup ()
  (pour-object-to-pan :from-object "green cup" :to-object "frying pan" :arm :rarm :spot-name "stove" :use-rec t)
  )

(defun tmp-grasp-lid ()
  (grasp-rec-object :object-name "pan lid" :arm :rarm :use-model "fp" :use-calib-offset nil :grasp-gain 1.0)
  )

(defun tmp-place-lid ()
  (grasp-object-primitive :pre-set-avs (list #f(-67.4806 22.6647 -67.2305 -103.326 320.791 -69.2717 32.752)
                                             #f(-47.5298 11.2017 -41.6889 -86.7864 238.525 -94.9484 22.8652))
                          :grasp-coords (make-coords :pos #f(837.558 111.919 890.809) :rpy #f(0.055 0.639 -3.112))
                          :pre-set-val #f(-150 0 0)
                          :arm :rarm
                          :action-mode :place
                          :object-name "pan lid")
  )

;; TODO


;; (defun tmp-close-lid ()
;;   )

;; (defun based-egg ()

;;   )
