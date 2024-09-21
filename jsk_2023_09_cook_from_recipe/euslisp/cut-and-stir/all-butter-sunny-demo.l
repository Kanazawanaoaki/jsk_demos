#!/usr/bin/env roseus

;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_utils.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/wrench.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/move-to-adjust.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/pr2-cooking-actions.l") ;; TODO update
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/cooking-exec-pddl-utils.l")

;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/exec-cook-from-planed-recipe.l")

(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/exec-cook-from-recipe-procedure.l")


;; global variables

(defun prepare-sunny ()
  (reset-view-list)
  (init-pr2)
  (pr2-cook-init :spot "kitchen" :type :butter-sunny-side-up)

  (receive-and-set-green-bowl :arm :rarm)
  (receive-and-set-gray-bowl :spot "stove")
  (receive-and-set-frying-pan)
  ;; (place-objects-on-table :object-name "ボウル0" :arm :rarm :spot-name "stove" :set-flag t) ;; small-bowl
  ;; (place-objects-on-table :object-name "ボウル1" :arm :rarm :spot-name "stove" :set-flag t) ;; bowl
  ;; (set-pot-on-stove :object-name "フライパン") ;; frying-pan

  )

(defun do-sunny ()
  (speak-with-log "目玉焼きの調理を開始します")
  (reset-view-list)
  (init-pr2)
  (pr2-cook-init :spot "kitchen" :type :butter-sunny-side-up)
  (exec-cook-from-recipe "egg-recipes-prompt_butter-sunny_converted_conv_planned.l")
  ;; (setq *plan-list* '((hold small-bowl arm2 stove) (transfer butter small-bowl frying-pan arm2 stove) (place small-bowl arm2 stove) (turn-on-stove frying-pan arm1) (heat butter frying-pan melt) (hold bowl arm2 stove) (transfer egg bowl frying-pan arm2 stove) (place bowl arm2 stove) (cook egg cooked-egg) (turn-off-stove middle frying-pan arm1)))

  ;; (speak-with-log "目玉焼きの調理を行いました")
  )

(defun receive-spatula-for-sunny ()
  (send *pr2* :rarm :angle-vector #f(-41.0354 31.325 -34.2869 -99.4442 -158.179 -54.5975 103.313))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :speak-jp (format nil "~AをセットしてOKと言ってください" "spatula"))
  (ok-wait)
  (send *ri* :start-grasp :rarm :wait t)

  )

(defun grasp-frying-pan ()
  ;; (place-objects-on-table :object-name "フライパン" :arm :larm :spot-name "stove" :grasp-flag t :grasp-gain 0.1)
  (pick-up-frying-pan)
  )

(defun put-frying-pan ()
  ;; (place-objects-on-table :object-name "フライパン" :arm :larm :spot-name "stove")
  (place-frying-pan)
  )

(defun put-spatula-on-table ()
  ;; (place-objects-on-table :object-name "ヘラ" :arm :rarm :spot-name "stove")
  (place-spatula)
  )


(defun trasnfer-sunny-from-pan ()
  ;; (setq cook-from-now-file-name "../../av-files/cook-from-now-transfer-sunny-from-pan-20240909-data.l")

  ;; 20240909 chapmpion
  ;; (setq cook-from-now-file-name "../../av-files/cook-from-now-transfer-sunny-from-pan-20240909-data-02.l")
  ;; (load-cook-from-now-file :file_name cook-from-now-file-name :larm nil)
  ;; (cook-from-now-replay-once :larm nil :initial-av t)

  (setq cook-from-now-file-name "../../av-files/cook-from-now-transfer-sunny-from-pan-20240909-data-02.l")
  (load-cook-from-now-file :file_name cook-from-now-file-name :larm nil)
  (cook-from-now-replay-once :larm nil :initial-av nil :time 100) ;; default time is 150
  )

(defun now-finish-sunny-all ()
  (speak-with-log "目玉焼きの盛り付けに挑戦します")

  (grasp-frying-pan)
  (receive-spatula-for-sunny)
  (trasnfer-sunny-from-pan)
  (put-frying-pan)
  (put-spatula-on-table)

  (speak-with-log "目玉焼きの調理を行いました")
  )

(defun exec-sunny-all ()
  (do-sunny)
  (now-finish-sunny-all)
  )
