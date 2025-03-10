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

(defun init-sunny (&key (spot stove))
  (reset-view-list)
  (init-pr2)
  (pr2-cook-init :spot spot :type :sunny-side-up)
  )

(defun prepare-sunny (&key (use-opener nil))
  (init-sunny :spot kitchen)

  ;; (receive-and-set-green-bowl :arm :rarm)
  ;; (receive-and-set-gray-bowl :spot "stove")

  ;; (set-pot-on-stove :object-name "frying pan")

  ;; TODO add spatula?

  (reset-cook-pose)
  )


(defun do-sunny-tmp ()
  (if *use-english*
      (speak-with-log "I start cooking sunny-side-up" :lang "en")
    (speak-with-log "目玉焼きの調理を開始します"))

  (init-sunny :spot kitchen)
  ;; (exec-cook-from-recipe "prompt_sunny-side-up_conv_planned.l") ;; sk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/planned/prompt_sunny-side-up_conv_planned.l

  ;; (hold salad-oil arm2 stove) (pour salad-oil frying-pan arm2 stove) (place salad-oil arm2 stove) (turn-on-stove frying-pan arm1) (heat salad-oil frying-pan thirty-seconds) (hold bowl arm2 stove) (transfer egg bowl frying-pan arm2 stove) (place bowl arm2 stove) (cook egg cooked-egg) (turn-off-stove middle frying-pan arm1)


  ;; TODO update

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



;; egg crack
(defun now-egg-crack-set-both (&key (use-rec nil) (left-first t))
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
        (grasp-rec-object :object-name "egg" :arm :larm :use-model "deva" :use-calib-offset nil :grasp-gain 0.007)
        )
    (progn
      ;; 待機姿勢
      (send *pr2* :larm :angle-vector #f(46.0802 4.45794 62.0517 -76.0447 24.8164 -67.3512 60.6811))
      (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
      (send *ri* :wait-interpolation)

      ;; 左手の卵を掴む位置
      ;; (send *pr2* :larm :angle-vector #f(25.4644 6.30462 81.3182 -27.1804 103.643 -87.3789 -5.18068)) ;; #<cascaded-coords #X55ebe5530d60 :larm-end-coords  723.236 403.655 857.552 / 1.244 1.515 -1.962>
      (send *pr2* :larm :angle-vector #f(25.736 4.73558 81.1203 -27.9526 103.117 -89.0249 -5.55466)) ;; #<cascaded-coords #X55ebe5530d60 :larm-end-coords  723.23 403.655 877.67 / 1.244 1.515 -1.962>
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
  ;; 卵をセットする左腕の位置
  ;; (send *pr2* :larm :angle-vector #f(4.42574 -7.14561 63.5217 -42.4095 110.235 -114.592 54.596)) ;; #<cascaded-coords #X55ebe5530d60 :larm-end-coords  686.977 64.883 1086.202 / 1.295 1.487 -0.291>
  (send *pr2* :larm :angle-vector #f(14.0062 -8.38952 70.2396 -71.6376 91.7893 -114.585 31.1574)) ;; #<cascaded-coords #X560d5c4b5860 :larm-end-coords  586.977 64.883 1086.322 / 1.295 1.487 -0.291>
  (send *pr2* :larm :move-end-pos (float-vector 0 0 50) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  ;; 卵をセットする
  ;; (send *pr2* :larm :move-end-pos (float-vector -10 -10 -100) :world)
  ;; (send *pr2* :larm :move-end-pos (float-vector -10 -10 -110) :world) ;; これをつかっていた

  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  ;; (send *arrow* :translate #f(0 0 -60) :world) ;;これを使っていた
  (send *arrow* :translate #f(10 -10 -60) :world) ;; 受け渡し方を変えたので
  (send *arrow* :rotate (deg2rad 30) :z)
  (send *pr2* :larm :inverse-kinematics *arrow*)

  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; 卵を離す
  ;; (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :move-gripper :larm 0.07 :wait t)
  (unix::sleep 1)

  ;; (pr2-arm-up :num 100 :time 2000 :arm :larm)
  (send *pr2* :larm :angle-vector #f(14.0062 -8.38952 70.2396 -71.6376 91.7893 -114.585 31.1574)) ;; #<cascaded-coords #X560d5c4b5860 :larm-end-coords  586.977 64.883 1086.322 / 1.295 1.487 -0.291>
  (send *pr2* :larm :move-end-pos (float-vector 0 0 50) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :angle-vector #f(46.0802 4.45794 62.0517 -76.0447 24.8164 -67.3512 60.6811))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (reset-cook-pose :arm :larm)
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

(defun now-egg-crack-all (&key (human-help nil) (use-rec t) (egg-rec nil))
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
