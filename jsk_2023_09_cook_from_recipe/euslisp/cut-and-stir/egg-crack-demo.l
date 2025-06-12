#!/usr/bin/env roseus
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_utils.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/wrench.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/move-to-adjust.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/pr2-cooking-actions.l") ;; TODO update
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/cooking-exec-pddl-utils.l")

;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/exec-cook-from-planed-recipe.l")

(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/exec-cook-from-recipe-procedure.l")


;; global variables
(setq *use-english* nil)

(defun egg-crack-init ()
  (reset-view-list)
  (init-pr2)

  (pr2-cook-init :spot "counter" :type :egg)
  )

(defun prepare-egg-crack (&key )
  (egg-crack-init)

  (receive-and-set-gray-bowl :spot "counter")
  (receive-and-set-egg-opener :spot "counter")

  ;; (place-objects-on-table :object-name "ボウル0" :arm :rarm :spot-name "stove" :set-flag t) ;; small-bowl
  ;; (place-objects-on-table :object-name "ボウル1" :arm :rarm :spot-name "stove" :set-flag t) ;; bowl
  ;; (set-pot-on-stove :object-name "フライパン") ;; frying-pan

  (reset-cook-manip-pose :torso-lift 325)
  )

;; egg cracker
(defun now-egg-crack-set-both (&key (use-rec nil) (left-first t)) ;; this is old.
  (if use-rec
      (progn
        ;; 左腕でegg openerを掴む
        (grasp-rec-object :object-name "egg opener" :arm :larm :use-model "fp" :use-calib-offset nil)
        )
    (progn
      (pick-up-egg-opener)
      )
    )

  (setq after-larm-grasp-cds (fp-rec-object :object-name "egg opener" :change-rec nil))
  (format t "after-larm-grasp-cds: ~A~%" after-larm-grasp-cds)

  (if left-first
      (progn
        ;; 受け渡す姿勢
        (send *pr2* :larm :angle-vector #f(21.3222 8.37911 41.9583 -91.0416 89.868 -111.036 8.85392))
        (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
        (send *ri* :wait-interpolation)

        ;; 右手をアプローチして
        (send *pr2* :rarm :angle-vector #f(-38.3278 -3.2288 -63.6414 -68.0071 -83.1809 -108.309 393.782))
        (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
        (send *ri* :wait-interpolation)
        (send *ri* :stop-grasp :rarm :wait t)

        (send *pr2* :rarm :angle-vector #f(-21.6654 -5.50636 -71.2073 -98.2083 -77.9226 -81.6828 353.614))
        (send *pr2* :rarm :move-end-pos #f(0 0 100) :world)
        (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
        (send *ri* :wait-interpolation)

        (send *pr2* :rarm :move-end-pos #f(0 0 -110) :world)
        (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
        (send *ri* :wait-interpolation)
        )
    (progn
      ;; 右腕を位置にセットする
      (egg-crack-rarm-set-motion)
      (send *ri* :stop-grasp :rarm :wait t)

      ;; 左腕で右手にエッグオープナーを握らせる
      (setq cook-from-now-file-name "../av-files/cook-from-now-larm-set-egg-opener-20250217-data-01.l")
      (load-cook-from-now-file :file_name cook-from-now-file-name :larm t)
      (cook-from-now-replay-once :larm t :initial-av nil)
      ))

  (setq rarm-opener-grasp-cds (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *ri* :move-gripper :rarm 0.07 :wait t)
  (unix::sleep 1)

  (send *ri* :stop-grasp :larm :wait t)

  (send *pr2* :larm :move-end-pos #f(0 100 100) :world) ;; #f(0 100 50)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :angle-vector #f(38.3564 13.2212 62.8877 -95.6121 117.6 -104.476 -45.8748))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (reset-cook-pose :arm :larm)

  (if left-first
      (progn
        ;; egg opener セットの位置
        (send *pr2* :rarm :angle-vector #f(-15.7712 9.99542 -60.6957 -77.3209 -95.7696 -102.646 329.115)) ;; 149.115 ;; #<cascaded-coords #X560d5c4c6b18 :rarm-end-coords  584.37 -32.86 988.016 / 1.714 1.271 0.148>
        (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
        (send *ri* :wait-interpolation)
        ))

  (setq after-rarm-grasp-cds (fp-rec-object :object-name "egg opener" :change-rec nil))
  (format t "after-rarm-grasp-cds: ~A~%" after-rarm-grasp-cds)
  )

(defun egg-crack-rarm-set-motion ()
  ;; 待機姿勢 from green bowl
  ;; (send *pr2* :rarm :angle-vector #f(-38.3278 -3.2288 -63.6414 -68.0071 -83.1809 -108.309 393.782))
  (send *pr2* :rarm :angle-vector #f(-38.3278 -3.2288 -63.6414 -68.0071 -83.1809 -108.309 393.782));; 393.782
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; egg opener セットの位置
  (send *pr2* :rarm :angle-vector #f(-15.7712 9.99542 -60.6957 -77.3209 -95.7696 -102.646 329.115)) ;; 149.115 ;; #<cascaded-coords #X560d5c4c6b18 :rarm-end-coords  584.37 -32.86 988.016 / 1.714 1.271 0.148>
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  )

(defun egg-crack-rarm-receive ()
  (egg-crack-rarm-set-motion)

  (send *ri* :move-gripper :rarm 0.07 :wait t)
  (if *use-english*
      (send *ri* :speak-en (format nil "Please set ~A and say OK." "egg opener"))
    (send *ri* :speak-jp (format nil "~AをセットしてOKと言ってください" "egg opener"))
    )
  (ok-wait)
  )

(defun egg-crack-larm-grasp (&key (use-rec t))
  (if use-rec
      (progn
        (grasp-rec-object :object-name "egg" :arm :larm :spot "counter" :use-model "deva" :use-calib-offset nil :grasp-gain 0.007);; TODO :holdを使った方が良いのか?
        )
    (progn
      (pr2-arm-up :num 100 :arm :larm)

      ;; 待機姿勢 その1
      (send *pr2* :larm :angle-vector #f(69.5177 10.1531 65.7727 -121.259 -337.106 -52.2361 325.722))
      (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
      (send *ri* :wait-interpolation)

      ;; 待機姿勢 その2
      (send *pr2* :larm :angle-vector #f(51.785 18.9729 44.1366 -106.419 -315.656 -64.3521 392.927))
      (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
      (send *ri* :wait-interpolation)

      (send *ri* :stop-grasp :larm :wait t)

      ;; 左手の卵を掴む位置
      ;; (send *pr2* :larm :angle-vector #f(25.736 4.73558 81.1203 -27.9526 103.117 -89.0249 -5.55466)) ;; #<cascaded-coords #X55ebe5530d60 :larm-end-coords  723.23 403.655 877.67 / 1.244 1.515 -1.962>
      (send *pr2* :larm :angle-vector #f(33.6442 -3.71883 98.6645 -76.4595 -272.873 -85.2094 319.612)) ;; #<cascaded-coords #X56254e5ebed8 :larm-end-coords  601.016 263.23 919.799 / 1.606 1.502 -1.499>
      (send *pr2* :larm :move-end-pos (float-vector 0 0 80) :world)
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
      ))
  )

(defun egg-crack-larm-carry ()
  ;; 卵をセットする左腕の位置のセット
  (send *pr2* :larm :angle-vector #f(15.3939 -19.6022 69.071 -77.1977 -280.164 -114.3 385.567)) ;; #<cascaded-coords #X56254e5ebed8 :larm-end-coords  530.592 48.542 1199.673 / 0.496 1.477 -1.04>
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)


  (send *pr2* :larm :angle-vector #f(9.36656 -14.3426 69.7038 -77.0606 -279.207 -114.016 386.287)) ;; #<cascaded-coords #X56254e5ebed8 :larm-end-coords  522.706 -9.709 1157.612 / 1.266 1.539 -0.163>
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  ;; 卵をセットする
  ;; (send *pr2* :larm :move-end-pos (float-vector -10 -10 -100) :world)
  ;; (send *pr2* :larm :move-end-pos (float-vector -10 -10 -110) :world) ;; これをつかっていた

  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))

  ;; (send *arrow* :translate #f(10 -10 -60) :world)
  (send *arrow* :translate #f(0 0 -30) :world)

  (send *arrow* :rotate (deg2rad 30) :z)
  (send *pr2* :larm :inverse-kinematics *arrow*)

  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; 卵を離す
  ;; (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :move-gripper :larm 0.07 :wait t)
  (unix::sleep 1)

  ;; (pr2-arm-up :num 100 :time 2000 :arm :larm)
  (send *pr2* :larm :angle-vector #f(15.3939 -19.6022 69.071 -77.1977 -280.164 -114.3 385.567)) ;; #<cascaded-coords #X56254e5ebed8 :larm-end-coords  530.592 48.542 1199.673 / 0.496 1.477 -1.04>
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :angle-vector #f(50.7163 28.9461 50.58 -99.7113 -311.614 -69.6231 406.581))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; (reset-cook-pose :arm :larm)
  ;; (reset-cook-manip-pose :torso-lift 325)
  (reset-cook-manip-pose :arm :larm :torso-lift 325)
  )

(defun egg-crack-rarm (&key (return-pose nil))
  ;; 卵を割る右手の位置
  (send *pr2* :rarm :angle-vector #f(-36.4907 1.11455 -61.744 -29.561 -114.175 -83.8649 349.336));; 169.336
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos (float-vector 40 0 -60) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; 卵を割る
  (send *ri* :start-grasp :rarm :gain 1.0 :wait t)
  (unix::sleep 2)

  (send *ri* :move-gripper :rarm 0.07)

  (send *pr2* :rarm :move-end-pos (float-vector -40 0 60) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (pr2-arm-up :num 50 :time 2000 :arm :rarm)

  (if return-pose
      (progn
        ;; 待機姿勢 from green bowl
        ;; (send *pr2* :rarm :angle-vector #f(-38.3278 -3.2288 -63.6414 -68.0071 -83.1809 -108.309 393.782))
        (send *pr2* :rarm :angle-vector #f(-38.3278 -3.2288 -63.6414 -68.0071 -83.1809 -108.309 393.782));; 393.782
        (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
        (send *ri* :wait-interpolation)

        ;; egg opener セットの位置
        (send *pr2* :rarm :angle-vector #f(-15.7712 9.99542 -60.6957 -77.3209 -95.7696 -102.646 329.115)) ;; 149.115 ;; #<cascaded-coords #X560d5c4c6b18 :rarm-end-coords  584.37 -32.86 988.016 / 1.714 1.271 0.148>
        (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
        (send *ri* :wait-interpolation)
        )
    (progn
      ;; 渡す姿勢
      (send *pr2* :rarm :angle-vector #f(-44.0483 4.94362 -15.3096 -9.5872 -156.086 -73.7338 138.434))
      (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
      (send *ri* :wait-interpolation)

      (if *use-english*
          (send *ri* :speak-en (format nil "Please receive ~A and say OK." "egg opener"))
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
      ))
  )

(defun egg-crack-return-to-left ()
  ;; (egg-crack-rarm :return-pose t) の後に実行

  ;; from egg-crack-larm-grasp
  (send *pr2* :larm :angle-vector #f(46.0802 4.45794 62.0517 -76.0447 24.8164 -67.3512 -119.3189)) ;;orig 60.6811
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; from egg-crack-larm-carry
  ;; (send *pr2* :larm :angle-vector #f(14.0062 -8.38952 70.2396 -71.6376 91.7893 -114.585 -148.8426)) ;;orig 31.1574 ;; #<cascaded-coords #X560d5c4b5860 :larm-end-coords  586.977 64.883 1086.322 / 1.295 1.487 -0.291>
  (send *pr2* :larm :angle-vector #f(14.0062 -8.38952 70.2396 -71.6376 91.7893 -114.585 31.1574)) ;; #<cascaded-coords #X560d5c4b5860 :larm-end-coords  586.977 64.883 1086.322 / 1.295 1.487 -0.291> 右がアプローチする時の持ち方のために回転を修正
  (send *pr2* :larm :move-end-pos (float-vector 0 0 50) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm :wait t)

  ;; 左の受け取る姿勢
  ;; (send *pr2* :larm :angle-vector #f(14.2111 21.2526 34.3601 -87.8648 101.518 -114.362 -149.226)) ;; 右への受け渡しの姿勢．初期の持ち方とは大分変わってしまう．．．
  ;; (send *pr2* :larm :angle-vector #f(12.7046 -10.8142 84.8851 -78.3595 86.7942 -114.586 -154.147)) ;; 右に大分よせた，初期の持ち方に揃えようとした座標
  (send *pr2* :larm :angle-vector #f(21.4087 -0.209674 71.5661 -66.3259 78.9959 -87.0069 43.3392)) ;; 右がアプローチする受け渡しに変更したので
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  ;; 受け渡し
  (send *ri* :start-grasp :larm :wait t :gain 0.1)
  (send *ri* :stop-grasp :rarm :wait t)

  ;; 右手を退避
  (send *pr2* :rarm :move-end-pos #f(0 -100 50) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :angle-vector #f(-38.3278 -3.2288 -63.6414 -68.0071 -83.1809 -108.309 393.782));; 393.782
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (reset-cook-pose :arm :rarm)
  )




(defun current-set-transfer-butter ()
  ;; 注ぎの待機姿勢
  (send *pr2* :larm :angle-vector #f(13.4701 -4.47495 59.3413 -41.1902 -242.208 -99.7355 250.576))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 注ぐ位置 フライパンの位置から計算されるべきかも
  (send *pr2* :larm :angle-vector #f(-2.55706 3.44493 55.9327 -28.1094 -199.81 -33.6095 358.652))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


(defun current-transfer-butter-with-spatula ()
  ;; after grasp spatula

  (send *ri* :start-grasp :rarm :wait t)

  (setq cook-from-now-file-name "../av-files/cook-from-now-transfer-butter-to-pan-20250227-data-01.l")
  (load-cook-from-now-file :file_name cook-from-now-file-name :larm nil)
  (cook-from-now-replay-once :larm nil :initial-av nil :time 100) ;; default time is 150

  )

(defun current-place-green-bowl ()
  ;; 注ぎの待機姿勢
  (send *pr2* :larm :angle-vector #f(13.4701 -4.47495 59.3413 -41.1902 -242.208 -99.7355 250.576))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :angle-vector #f(35.207 15.7998 63.9443 -51.2849 -240.945 -84.4143 257.371))
  (send *pr2* :larm :move-end-pos #f(-100 0 0) :local)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(100 0 0) :local)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm :wait t)

  (send *pr2* :larm :move-end-pos #f(-100 0 0) :local)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :angle-vector #f(33.63 2.1508 57.5497 -93.8038 -255.515 -114.586 220.634))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun now-transfer-butter-with-spatula ()
  (grasp-rec-object :object-name "spatula" :arm :rarm :use-model "fp" :use-calib-offset nil)

  (grasp-rec-object :object-name "green bowl" :arm :larm :use-model "fp" :use-calib-offset nil)

  (current-set-transfer-butter)
  (current-transfer-butter-with-spatula)

  (place-spatula)

  (current-place-green-bowl)

  (reset-cook-pose)
  )

(defun do-sunny-tmp ()
  (if *use-english*
      (speak-with-log "I start cooking sunny-side-up" :lang "en")
    (speak-with-log "目玉焼きの調理を開始します"))
  (reset-view-list)
  (init-pr2)
  (pr2-cook-init :spot "stove" :type :butter-sunny-side-up)
  ;; (exec-cook-from-recipe "egg-recipes-prompt_butter-sunny_converted_conv_planned.l")


  ;; (hold small-bowl arm2 stove)
  ;; (transfer butter small-bowl frying-pan arm2 stove)
  ;; (place small-bowl arm2 stove)
  (now-transfer-butter-with-spatula)

  (turn-on-stove frying-pan arm1)
  (heat butter frying-pan melt)
  (grasp-rec-object :object-name "gray bowl" :arm :rarm :use-model "fp" :use-calib-offset nil) ;;(hold bowl arm2 stove)
  (transfer egg bowl frying-pan arm2 stove)
  (place bowl arm2 stove)
  (cook egg cooked-egg)
  (turn-off-stove middle frying-pan arm1)

  ;; (speak-with-log "目玉焼きの調理を行いました")
  )



;; use  egg-cracker
(defun now-egg-crack-all (&key (use-rec t) (egg-rec nil)) ;; use this one !!
  ;; 右腕でegg openerを掴む
  (grasp-rec-object :object-name "egg opener" :arm :rarm :use-model "fp" :use-calib-offset nil)

  (send *ri* :move-gripper :rarm 0.076)

  ;; 卵セットの位置 右腕
  (send *pr2* :rarm :angle-vector #f(-27.2041 20.6283 -48.1463 -89.9882 277.543 -88.0405 -29.2401))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  ;; egg set
  (egg-crack-larm-grasp :use-rec egg-rec)
  (egg-crack-larm-carry)


  )


(defun now-egg-crack-old (&key (human-help nil) (use-rec t) (egg-rec nil))
  (if *use-english*
      (speak-with-log "I start cooking sunny-side-up" :lang "en") ;; TODO
    (speak-with-log "卵を割る動作に挑戦します"))

  (if human-help
      (egg-crack-rarm-receive)
    (now-egg-crack-set-both :use-rec use-rec)
    )

  (egg-crack-larm-grasp :use-rec egg-rec)
  (egg-crack-larm-carry)

  ;; ボウルの方を見る
  ;; (pr2-move-head :head-p 50 :head-y -30) ;; not test yet
  (send *pr2* :head-neck-y :joint-angle -30)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (if human-help
      (progn
        (egg-crack-rarm) ;; human receive tool

        ;; (pr2-move-head :head-p 50 :head-y 0) ;; not test yet
        (send *pr2* :head-neck-y :joint-angle 0)
        (send *ri* :angle-vector (send *pr2* :angle-vector))
        (send *ri* :wait-interpolation)
        )
    (progn
      (egg-crack-rarm :return-pose t)
      ;; () TODO return to left
      ;; TODO put-egg-opener with left

      ;; (pr2-move-head :head-p 50 :head-y 0) ;; not test yet
      (send *pr2* :head-neck-y :joint-angle 0)
      (send *ri* :angle-vector (send *pr2* :angle-vector))
      (send *ri* :wait-interpolation)

      (setq after-crack-egg-cds (fp-rec-object :object-name "egg opener" :change-rec nil))
      (format t "after-crack-egg-cds: ~A~%" after-crack-egg-cds)

      (egg-crack-return-to-left)
      (put-egg-opener)
      (reset-cook-pose :arm :larm)
      ))
  )
