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


;; egg cracker
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

;; use  egg-cracker
(defun now-egg-crack-all (&key (use-rec t) (egg-rec nil)) ;; use this one !!
  ;; 右腕でegg openerを掴む
  (if use-rec
      (grasp-rec-object :object-name "egg opener" :arm :rarm :use-model "fp" :use-calib-offset nil)
    (pick-up-egg-opener :spot "counter" :arm :rarm :use-cds-offset nil)
    )

  (send *ri* :move-gripper :rarm 0.076)

  ;; 卵セットの位置 右腕
  ;; (send *pr2* :rarm :angle-vector #f(-27.2041 20.6283 -48.1463 -89.9882 277.543 -88.0405 -29.2401));; 20250611
  (send *pr2* :rarm :angle-vector #f(-27.0663 21.5492 -47.7329 -93.6462 274.136 -93.0092 -27.5173));; 20250621 calib
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  ;; egg set
  (egg-crack-larm-grasp :use-rec egg-rec)
  (egg-crack-larm-carry)

  (egg-crack-rarm :use-rec use-rec)

  (place-egg-opener :spot "counter")

  ;; grasp gray bowl
  )

