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

(defun butter-sunny-init ()
  (reset-view-list)
  (init-pr2)

  (pr2-cook-init :spot "stove" :type :butter-sunny-side-up)
  )


;; egg cracker
(defun egg-crack-set-rarm (&key (rarm-gripper 0.076))
  (send *ri* :move-gripper :rarm rarm-gripper)

  ;; 卵セットの位置 右腕
  ;; (send *pr2* :rarm :angle-vector #f(-27.2041 20.6283 -48.1463 -89.9882 277.543 -88.0405 -29.2401));; 20250611
  (send *pr2* :rarm :angle-vector #f(-27.0663 21.5492 -47.7329 -93.6462 274.136 -93.0092 -27.5173));; 20250621 calib
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
  )

(defun egg-crack-set-larm-grasp (&key (use-rec t))
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

(defun egg-crack-set-larm-carry ()
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
  ;; (send *arrow* :rotate (deg2rad 30) :z)

  ;; (send *arrow* :translate #f(0 0 -30) :world);; original 20250922
  ;; (send *arrow* :rotate (deg2rad 30) :z);; original 20250922
  (send *arrow* :translate #f(20 0 -30) :world);; adjusted 20250922
  (send *arrow* :rotate (deg2rad 20) :z);; adjusted 20250922

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
  (reset-cook-manip-pose :arm :larm)
  )


(defun egg-crack-rarm (&key (use-rec t)) ;; TODO update
  (let ((object-rec-coord)
        (target-cds)
        (target-angle-vector))

    (if use-rec
        (progn
          (setq object-rec-coord (fp-rec-object :object-name "gray bowl" :change-rec t :multi-rec nil :fix-rot t))
          (setq target-cds (calc-target-from-base-rel object-rec-coord (make-coords :pos #f(-84.953 -83.556 92.875) :rpy #f(0.922 0.88 -3.039))))
          (send *pr2* :rarm :inverse-kinematics target-cds)
          )
      (progn
        (send *pr2* :rarm :angle-vector #f(-18.3307 24.1617 -46.6212 -83.9579 239.981 -86.2007 -1.15531))
        ))

  ;; 卵を割る右手の位置
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  ;; 卵を割る
  (send *ri* :start-grasp :rarm :gain 1.0 :wait t)
  (unix::sleep 2)

  (send *ri* :move-gripper :rarm 0.076)

  (pr2-arm-up :num 50 :time 2000 :arm :rarm)
  ))

;; sunny-transfer
(defun receive-spatula-for-sunny ()
  ;; (send *pr2* :rarm :angle-vector #f(-41.0354 31.325 -34.2869 -99.4442 -158.179 -54.5975 103.313))
  (send *pr2* :rarm :angle-vector #f(-56.5734 1.57093 -80.4669 -96.4171 189.91 -41.5902 161.763))
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


(defun transfer-sunny-from-pan () ;; TODO update
  (send *ri* :start-grasp :rarm :gain 0.1 :wait t)

  ;; ;; original
  ;; (setq cook-from-now-file-name "../av-files/cook-from-now-transfer-sunny-from-pan-20250213-data-01.l")
  ;; (load-cook-from-now-file :file_name cook-from-now-file-name :larm nil)
  ;; (cook-from-now-replay-once :larm nil :initial-av nil :time 100) ;; default time is 150

  ;; 予備の中間姿勢 for reset-cook-manip-pose
  (send *pr2* :rarm :angle-vector #f(-39.2174 35.4308 -43.6536 -96.6987 273.035 -48.5317 56.7665))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; devid
  ;; すくう動作
  (setq cook-from-now-file-name "../av-files/cook-from-now-transfer-sunny-from-pan-20250213-data-01-01.l")
  (load-cook-from-now-file :file_name cook-from-now-file-name :larm nil)
  ;; (cook-from-now-replay-once :larm nil :initial-av nil :time 100) ;; default time is 150
  (cook-from-now-replay-rec-once :larm nil :initial-av nil :time 100) ;; default time is 150 ;; reset-cook-manip-pose

  ;; 運ぶ動作
  ;; (setq cook-from-now-file-name "../av-files/cook-from-now-transfer-sunny-from-pan-20250213-data-01-02.l")
  ;; (load-cook-from-now-file :file_name cook-from-now-file-name :larm nil)
  ;; (cook-from-now-replay-once :larm nil :initial-av nil :time 100) ;; default time is 150

  ;; (send *pr2* :rarm :angle-vector #f(-29.4794 32.8183 -41.1178 -57.6387 -54.1418 -80.9058 15.6591)) ;;すくい終わりの関節角度
  (send *pr2* :rarm :angle-vector #f(-36.1141 20.8842 -74.221 -56.2957 337.26 -69.8264 1.45092)) ;;すくい終わりの関節角度 ;; reset-cook-manip-pose
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  ;; (send *pr2* :rarm :angle-vector #f(-51.7294 30.3803 -36.5974 -50.0075 -62.2124 -56.8969 7.41022)) ;;盛り付けはじめの関節角度
  (send *pr2* :rarm :angle-vector #f(-58.5146 19.2027 -73.3976 -48.6711 340.151 -45.5897 -8.97471)) ;;盛り付けはじめの関節角度 ;; reset-cook-manip-pose
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  ;; 盛り付け動作
  (pr2-move-head :head-p 50 :head-y -25) ;; not test yet
  ;; (send *pr2* :head-neck-y :joint-angle -25)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector))
  ;; (send *ri* :wait-interpolation)

  (setq cook-from-now-file-name "../av-files/cook-from-now-transfer-sunny-from-pan-20250213-data-01-03.l")
  (load-cook-from-now-file :file_name cook-from-now-file-name :larm nil)
  (setq *initial-head-neck-y* -25)
  ;; (cook-from-now-replay-once :larm nil :initial-av nil :time 100) ;; default time is 150
  (cook-from-now-replay-rec-once :larm nil :initial-av nil :time 100) ;; default time is 150 ;; reset-cook-manip-pose

  (setq *initial-head-neck-y* 0)
  (pr2-move-head :head-p 50 :head-y 0)
  ;; (send *pr2* :head-neck-y :joint-angle 0)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector))
  ;; (send *ri* :wait-interpolation)
  )


;; do demo codes
;; do egg-cracker
(defun now-egg-crack-all (&key (use-rec t) (egg-rec nil)) ;; use this one !!
  ;; 右腕でegg openerを掴む
  (if use-rec
      (grasp-rec-object :object-name "egg opener" :arm :rarm :use-model "fp" :use-calib-offset nil)
    (pick-up-egg-opener :spot "counter" :arm :rarm :use-cds-offset nil)
    )

  ;; egg set
  (egg-crack-set-rarm)
  (egg-crack-set-larm-grasp :use-rec egg-rec)
  (egg-crack-set-larm-carry)

  (egg-crack-rarm :use-rec use-rec)

  (place-egg-opener :spot "counter")

  ;; grasp gray bowl
  (if use-rec
      (grasp-rec-object :object-name "gray bowl" :arm :rarm :spot "counter" :use-model "fp" :use-calib-offset nil)
    (pick-up-gray-bowl :spot "counter" :use-cds-offset t)
    )
  )

;; do transfer sunny
(defun now-finish-sunny-all (&key (use-rec nil) (receive-from-human t))
  (if *use-english*
      (speak-with-log "I start cooking sunny-side-up" :lang "en") ;;TODO
    (speak-with-log "目玉焼きの盛り付けに挑戦します"))

  ;; フライパンを掴む
  (if use-rec
      (grasp-rec-object :object-name "frying pan" :arm :larm :use-model "fp" :use-calib-offset nil)
    (pick-up-frying-pan)
    )
  ;; ヘラを掴む
  (if receive-from-human
      (receive-spatula-for-sunny)
    (progn
      (if use-rec
          (grasp-rec-object :object-name "spatula" :arm :rarm :use-model "fp" :use-calib-offset nil)
        (pick-up-spatula)
        ))
    )

  (transfer-sunny-from-pan) ;; TODO test and update
  (place-frying-pan)
  (place-spatula)

  (if *use-english*
      (speak-with-log "I cooked sunny-side up!" :lang "en") ;; TODO
    (speak-with-log "目玉焼きの盛り付けに挑戦しました"))
  (if *use-english*
      (speak-with-log "Please enjoy the meal." :lang "en")
    (speak-with-log "どうぞめしあがってください"))
  ;; (reset-cook-pose)
  (reset-cook-manip-pose)
  )

