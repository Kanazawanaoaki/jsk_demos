#!/usr/bin/env roseus
65;6003;1c
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_utils.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/wrench.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/move-to-adjust.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/pr2-cooking-actions.l") ;; TODO update
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/cooking-exec-pddl-utils.l")

;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/exec-cook-from-planed-recipe.l")

(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/exec-cook-from-recipe-procedure.l")


;; global variables
(setq *use-english* nil)


(defun prepare-sunny ()
  (reset-view-list)
  (init-pr2)
  (pr2-cook-init :spot "stove" :type :butter-sunny-side-up)

  (receive-and-set-green-bowl :arm :rarm)
  (receive-and-set-gray-bowl :spot "stove")
  ;; (receive-and-set-frying-pan)
  (set-pot-on-stove :object-name "frying pan")

  ;; TODO add spatula?

  ;; (place-objects-on-table :object-name "ボウル0" :arm :rarm :spot-name "stove" :set-flag t) ;; small-bowl
  ;; (place-objects-on-table :object-name "ボウル1" :arm :rarm :spot-name "stove" :set-flag t) ;; bowl
  ;; (set-pot-on-stove :object-name "フライパン") ;; frying-pan

  (reset-cook-pose)
  )

(defun do-sunny ()
  (if *use-english*
      (speak-with-log "I start cooking sunny-side-up" :lang "en")
    (speak-with-log "目玉焼きの調理を開始します"))
  (reset-view-list)
  (init-pr2)
  (pr2-cook-init :spot "stove" :type :butter-sunny-side-up)
  (exec-cook-from-recipe "egg-recipes-prompt_butter-sunny_converted_conv_planned.l")
  ;; (setq *plan-list* '((hold small-bowl arm2 stove) (transfer butter small-bowl frying-pan arm2 stove) (place small-bowl arm2 stove) (turn-on-stove frying-pan arm1) (heat butter frying-pan melt) (hold bowl arm2 stove) (transfer egg bowl frying-pan arm2 stove) (place bowl arm2 stove) (cook egg cooked-egg) (turn-off-stove middle frying-pan arm1)))

  ;; (speak-with-log "目玉焼きの調理を行いました")
  )

(defun do-sunny-step ()
  (if *use-english*
      (speak-with-log "I start cooking sunny-side-up" :lang "en")
    (speak-with-log "目玉焼きの調理を開始します"))
  (reset-view-list)
  (init-pr2)
  (pr2-cook-init :spot "stove" :type :butter-sunny-side-up)
  ;; (exec-cook-from-recipe "egg-recipes-prompt_butter-sunny_converted_conv_planned.l")

  (setq *plan-list* '((hold small-bowl arm2 stove) (transfer butter small-bowl frying-pan arm2 stove) (place small-bowl arm2 stove) (turn-on-stove frying-pan arm1) (heat butter frying-pan melt) (hold bowl arm2 stove) (transfer egg bowl frying-pan arm2 stove) (place bowl arm2 stove) (cook egg cooked-egg) (turn-off-stove middle frying-pan arm1)))

  (if (null *plan-list*)
      (format t "now plan-list is nill please exec (load-planned-file)!! ~%")
    (progn
      (dolist (plan *plan-list*)
        (format t "now action is ~A ~%" plan)
        (eval plan)
        (do-until-key
         (format t "wait for key pressed, after exec ~A ~%" plan)
         (unix:usleep 100000)
         )
        )
      ))


  ;; (speak-with-log "目玉焼きの調理を行いました")
  )

(defun receive-spatula-for-sunny ()
  (send *pr2* :rarm :angle-vector #f(-41.0354 31.325 -34.2869 -99.4442 -158.179 -54.5975 103.313))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm :wait t)
  (if *use-english*
      (send *ri* :speak-en (format nil "Please set ~A and say OK." "spatula"))
    (send *ri* :speak-jp (format nil "~AをセットしてOKと言ってください" "spatula"))
    )
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


(defun transfer-sunny-from-pan () ;; TODO update
  ;; (setq cook-from-now-file-name "../../av-files/cook-from-now-transfer-sunny-from-pan-20240909-data.l")

  ;; 20240909 chapmpion
  ;; (setq cook-from-now-file-name "../../av-files/cook-from-now-transfer-sunny-from-pan-20240909-data-02.l")
  ;; (load-cook-from-now-file :file_name cook-from-now-file-name :larm nil)
  ;; (cook-from-now-replay-once :larm nil :initial-av t)

  (setq cook-from-now-file-name "../av-files/cook-from-now-transfer-sunny-from-pan-20240909-data-02.l")
  (load-cook-from-now-file :file_name cook-from-now-file-name :larm nil)
  (cook-from-now-replay-once :larm nil :initial-av nil :time 100) ;; default time is 150
  )

(defun now-finish-sunny-all ()
  (if *use-english*
      (speak-with-log "I start cooking sunny-side-up" :lang "en") ;;TODO
    (speak-with-log "目玉焼きの盛り付けに挑戦します"))

  (grasp-frying-pan)
  (receive-spatula-for-sunny)
  (transfer-sunny-from-pan)
  (put-frying-pan)
  (put-spatula-on-table)

  (if *use-english*
      (speak-with-log "I cooked sunny-side up!" :lang "en") ;; TODO
    (speak-with-log "目玉焼きの盛り付けに挑戦しました"))
  (if *use-english*
      (speak-with-log "Please enjoy the meal." :lang "en")
    (speak-with-log "どうぞめしあがってください"))
  (reset-cook-pose)
  )


;; egg cracker

(defun egg-crack-rarm-set ()
  ;; 待機姿勢 from green bowl
  (send *pr2* :rarm :angle-vector #f(-38.3278 -3.2288 -63.6414 -68.0071 -83.1809 -108.309 393.782))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; egg opener セットの位置
  (send *pr2* :rarm :angle-vector #f(-8.1748 5.21505 -58.7948 -48.9126 -99.9733 -100.896 129.251))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *ri* :move-gripper :rarm 0.07)
  (if *use-english*
      (send *ri* :speak-en (format nil "Please set ~A and say OK." "egg opener"))
    (send *ri* :speak-jp (format nil "~AをセットしてOKと言ってください" "egg opener"))
    )
  (ok-wait)
  )

(defun egg-crack-larm-grasp ()
  ;; 待機姿勢
  (send *pr2* :larm :angle-vector #f(46.0802 4.45794 62.0517 -76.0447 24.8164 -67.3512 60.6811))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; 左手の卵を掴む位置
  (send *pr2* :larm :angle-vector #f(25.4644 6.30462 81.3182 -27.1804 103.643 -87.3789 -5.18068)) ;; #<cascaded-coords #X55ebe5530d60 :larm-end-coords  723.236 403.655 857.552 / 1.244 1.515 -1.962>
  (send *pr2* :larm :move-end-pos (float-vector 0 0 100) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos (float-vector 0 0 -80) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; 掴んでみる
  (send *ri* :start-grasp :larm :gain 0.007 :wait t)
  (unix::sleep 1)

  ;; 持ち上げる
  (pr2-arm-up :num 100 :time 2000 :arm :larm)
  )

(defun egg-crack-larm-carry ()
  ;; 卵をセットする左腕の位置
  (send *pr2* :larm :angle-vector #f(4.42574 -7.14561 63.5217 -42.4095 110.235 -114.592 54.596)) ;; #<cascaded-coords #X55ebe5530d60 :larm-end-coords  686.977 64.883 1086.202 / 1.295 1.487 -0.291>
  (send *pr2* :larm :move-end-pos (float-vector 0 0 100) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  ;; (send *pr2* :larm :move-end-pos (float-vector -10 -10 -100) :world)
  (send *pr2* :larm :move-end-pos (float-vector -10 -10 -110) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; 卵を離す
  (send *ri* :stop-grasp :larm :wait t)
  (unix::sleep 1)

  (pr2-arm-up :num 100 :time 2000 :arm :larm)

  (send *pr2* :larm :angle-vector #f(46.0802 4.45794 62.0517 -76.0447 24.8164 -67.3512 60.6811))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (reset-cook-pose :arm :larm)
  )

(defun egg-crack-rarm ()
  ;; 卵を割る右手の位置
  (send *pr2* :rarm :angle-vector #f(-36.4907 1.11455 -61.744 -29.561 -114.175 -83.8649 169.336))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos (float-vector 50 0 -100) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; 卵を割る
  (send *ri* :start-grasp :rarm :gain 1.0 :wait t)
  (unix::sleep 2)

  (send *ri* :move-gripper :rarm 0.07)

  (send *pr2* :rarm :move-end-pos (float-vector -50 0 100) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (pr2-arm-up :num 100 :time 2000 :arm :rarm)

  ;; 渡す姿勢
  (send *pr2* :rarm :angle-vector #f(-44.0483 4.94362 -15.3096 -9.5872 -156.086 -73.7338 138.434))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (if *use-english*
      (send *ri* :speak-en (format nil "Please recieve ~A and say OK." "egg opener"))
    (send *ri* :speak-jp (format nil "~Aを回収してOKと言ってください" "egg opener"))
    )
  (ok-wait)
  (send *ri* :stop-grasp :rarm :wait t)

  (pr2-arm-up :num 100 :time 2000 :arm :rarm)

  ;; 待機姿勢 from green bowl
  (send *pr2* :rarm :angle-vector #f(-38.3278 -3.2288 -63.6414 -68.0071 -83.1809 -108.309 393.782))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (reset-cook-pose :arm :rarm)
  )


;; set-to-cracker
(defun now-egg-crack-all ()
  (if *use-english*
      (speak-with-log "I start cooking sunny-side-up" :lang "en") ;; TODO
    (speak-with-log "卵を割る動作に挑戦します"))

  (egg-crack-rarm-set)
  (egg-crack-larm-grasp)
  (egg-crack-larm-carry)
  (egg-crack-rarm)
  )

(defun exec-sunny-all ()
  (do-sunny)
  (now-finish-sunny-all)
  )

(defun tmp-exec-all ()
  (now-egg-crack-all)
  (do-sunny)
  (now-finish-sunny-all)
  )
