#!/usr/bin/env roseus

;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_tmp.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/wrench.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/move-to-adjust.l")

;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/pr2_cut_food.l")
;; (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/73b2-kitchen-coords.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/tool-use-in-kitchen-codes.l")

(setq *debug-flag* t)
(setq *s-time* 3)

;; load objects
(unless (boundp '*cutting-board*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/cutting-board.l")
    (setq *cutting-board* (cutting-board))
    ))

(unless (boundp '*bowl-1*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/bowl-1.l")
    (setq *bowl-1* (bowl-1))
    ))

(unless (boundp '*knife*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/knife-new-attention.l")
    (setq *knife* (knife))
    ))

(unless (boundp '*pot*)
  (progn
    (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/cooking-pot-73b2.l")
    (setq *pot* (cooking-pot))
    ))

(unless (boundp '*kitchen-plane*)
  (progn
    (setq *kitchen-plane* (make-cube 570 700 10))
    ))

(unless (boundp '*arrow*)
  (progn
    (load "models/arrow-object.l")
    (setq *arrow* (arrow))
    ))

(defun cutting-board-init (&key (reset-obj-cds t) (init-cds t))
  ;; init
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")

  ;; set global coords
  (when init-cds
    (73b2-kitchen-coords-init))

  ;; set objects
  (when reset-obj-cds
    (dissoc-object *cutting-board*)
    (send *cutting-board* :newcoords (send *cutting-board-coords* :copy-worldcoords))

    (dissoc-object *bowl-1*)
    (send *bowl-1* :newcoords (send *bowl-1-kitchen-coords* :copy-worldcoords))

    (dissoc-object *knife*)
    (send *knife* :newcoords (send *knife-coords* :copy-worldcoords))

    (dissoc-object *pot*)
    (send *pot* :newcoords (send *pot-coords* :copy-worldcoords))

    (send *kitchen-plane* :newcoords  (send *kitchen-plane-coords* :copy-worldcoords))

    ;; def global-coords
    ;; (setq *slide-rarm-coords* (make-coords :pos (float-vector 430.297 8421.198 30852.165) :rpy (float-vector -3.086 1.155 3.132))) ;; original
    ;; (setq *slide-rarm-coords* (make-coords :pos (float-vector 679.703 78.802 852.165) :rpy (float-vector 0.056 1.155 3.132))) ;; fix
    (setq *slide-rarm-coords-rel* (make-coords :pos (float-vector -129.703 1.145 12.165) :rpy (float-vector -3.085 1.155 3.132))) ;; fix rel

    ;; (setq *slide-larm-coords* (make-coords :pos (float-vector 735.864 8441.372 30866.716) :rpy (float-vector 2.244 -1.518 0.872))) ;; original
    ;; (setq *slide-larm-coords* (make-coords :pos (float-vector 374.136 58.628 866.716) :rpy (float-vector -0.898 -1.518 0.872))) ;; fix
    (setq *slide-larm-coords-rel* (make-coords :pos (float-vector 175.855 21.444 26.716) :rpy (float-vector 2.244 -1.518 0.872))) ;; fix rel

    ;; (setq *grasp-larm-coords* (make-coords :pos (float-vector 679.695 8281.493 30832.711) :rpy (float-vector 1.882 0.065 1.548))) ;; original
    ;; (setq *grasp-larm-coords* (make-coords :pos (float-vector 430.305 218.507 832.711) :rpy (float-vector -1.26 0.065 1.548))) ;; fix
    (setq *grasp-larm-coords-rel* (make-coords :pos (float-vector 19.748 -138.501 -7.289) :rpy (float-vector 1.882 0.065 1.548))) ;; fix rel
    )

  ;; (move-to-kitchen-irt)
  ;; (objects (list *pr2* *scene* *cutting-board* *knife* *pot* *bowl-1*))
  ;; (update-view)
  ;; ;; for original coords
  ;; (send *pr2* :move-to (send *kitchen-spot* :copy-worldcoords) :world)

  (objects (list *pr2* *kitchen-plane* *cutting-board* *knife* *pot* *bowl-1* *arrow*))

  )

(cutting-board-init)

(warn "If you use real robot, run (update-pos) ~%")
(warn "please run (slide-board-set) ~%")

;; add for sense
(setq *z-thre* 15)

(ros::roseus "board_rec_test" :anonymous t)
(setq *topic-name* "/left_endeffector/wrench")
(ros::load-ros-manifest "geometry_msgs")
(setq *cb-flag* nil)
(defun wrench-z-cb (msg)
  (when msg
    (let ((z nil))
      (setq z (send msg :wrench :force :z))
      (if (> z *z-thre*)
          (progn
            (setq *cb-flag* t)
            (format t "OK!! z: ~A ~%" z)
            )
        (format t "z: ~A ~%" z))
      )))

;; add for voice recognition
(ros::load-ros-manifest "speech_recognition_msgs")
(setq *data-flag* nil)
(defun voice-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :transcript))
    (setq *data-flag* t)
    (format t "data: ~A ~%" *data*)
    )
  )

(defun dialogue-func ()
  (ros::unsubscribe "/speech_to_text")
  (setq *data-flag* nil)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'voice-cb)
  (until *data-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  (send *ri* :speak-jp "ありがとうございます")
  (unix:sleep 1)
  )

(setq *ok-flag* nil)
(defun voice-ok-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :transcript))
    (if (equal *data* '("OK"))
        (progn
          (format t "了解しました！ ~%" *data*)
          (setq *ok-flag* t)
          )
      (format t "data: ~A ~%" *data*)
      )
    )
  )

(defun ok-wait ()
  (ros::unsubscribe "/speech_to_text")
  (setq *ok-flag* nil)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'voice-ok-cb)
  (until *ok-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  (send *ri* :speak-jp "ありがとうございます")
  (unix:sleep *w-time*)
  )

(defun ok-grasp-larm (&rest args &key (gain 0.01) &allow-other-keys)
  (ok-wait)
  (send *ri* :start-grasp :larm :wait t :gain gain)
  )

(defun receive-with-dialogue-larm (&rest args &key (gain 0.01) &allow-other-keys)
  ;; (send *ri* :speak-jp "包丁を渡す準備をして，合図をして下さい") ;; 喋らせている想定でスタート
  (setq *yes-flag* nil)
  (until *yes-flag*
         (send *ri* :stop-grasp :larm :wait t)
         (ok-grasp-larm :gain gain)
         (send *ri* :speak-jp "上手く掴めていますか？")
         (dialogue-func)
         (if (equal *data* '("はい"))
             (setq *yes-flag* t)
           (progn
             (send *ri* :speak-jp "グリッパを開きます.もう一度お願いします")
             (unix:sleep *w-time*)
             )
           )
         )

  (send *ri* :speak-jp "次の行動に移ります")
  (unix:sleep *w-time*)
  )


;; def util-funcs
(defun reset-rarm ()
  ;;少し上に
  ;; (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  ;; (send *arrow* :translate #f(0 0 100) :world)
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis nil
  ;;       :debug-view *debug-flag*)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  ;; (send *ri* :wait-interpolation)
  (pr2-rarm-up :num 100 :time 4000)

  ;; (setq *rav0* (float-vector -25.6468 7.87241 -48.2704 -85.3763 253.675 -77.8887 -147.102))
  ;; (send *pr2* :rarm :angle-vector *rav0*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 556.424 8603.557 31158.464) :rpy (float-vector -2.286 0.656 0.542))) ;; original
  (send *arrow* :newcoords (make-coords :pos (float-vector 553.576 -103.557 1158.464) :rpy (float-vector 0.856 0.656 0.542))) ;; fix
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (setq *rav1* (float-vector -20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  ;; (send *pr2* :rarm :angle-vector *rav1*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 628.029 8828.539 31050.217) :rpy (float-vector -3.14 0.18 -0.086))) ;; original
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 481.971 -328.539 1050.217) :rpy (float-vector 0.002 0.18 -0.086))) ;; fix
  (send *arrow* :newcoords (make-coords :pos (float-vector 571.971 -328.539 1025.217) :rpy (float-vector 0.002 0.18 -0.086))) ;; fix v2
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (setq *rav3* (float-vector -75.0 50.0 -110.0 -110.0 20.0 -10.0 -10.0))
  ;; (send *pr2* :rarm :angle-vector *rav3*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 800.191 8689.104 30866.677) :rpy (float-vector -2.341 -0.222 -0.482))) ;; original
  (send *arrow* :newcoords (make-coords :pos (float-vector 309.809 -189.104 866.677) :rpy (float-vector 0.801 -0.222 -0.482))) ;; fix
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; (setq *rav3* (float-vector -75.0 50.0 -110.0 -110.0 20.0 -10.0 -10.0))
  ;; (send *pr2* :rarm :angle-vector *rav3*)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  ;; (send *ri* :wait-interpolation)
  (reset-cook-pose :arm :rarm :time 3000)
  )

(defun reset-larm ()
  ;; 左手を少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view nil)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 少し上にして水平に
  ;; (setq *lav1* (float-vector 16.6498 -20.1996 123.812 -51.9785 -42.6397 -65.2851 -0.059116))
  ;; (send *pr2* :larm :angle-vector *lav1*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 509.999 8489.998 31189.999) :rpy (float-vector 1.571 0.0 1.349))) ;;original
  (send *arrow* :newcoords (make-coords :pos (float-vector 600.001 10.002 1189.999) :rpy (float-vector -1.571 0.0 1.349))) ;;fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手前にする
  ;; (setq *lav2* (float-vector 41.8129 -20.2467 85.9536 -82.3235 -13.8272 -47.9804 -0.0))
  ;; (send *pr2* :larm :angle-vector *lav2*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 660.0 8390.0 31290.0) :rpy (float-vector 1.571 0.0 1.722))) ;; original
  (send *arrow* :newcoords (make-coords :pos (float-vector 450.0 110.0 1290.0) :rpy (float-vector -1.571 0.0 1.722))) ;; fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (setq *lav3* (float-vector 75.8217 52.0712 108.49 -109.796 -2.86542 -9.47056 -0.0))
  ;; (send *pr2* :larm :angle-vector *lav3*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 800.188 8310.893 30866.671) :rpy (float-vector 2.341 -0.222 0.589)));;original
  (send *arrow* :newcoords (make-coords :pos (float-vector 309.812 189.107 866.671) :rpy (float-vector -0.801 -0.222 0.589))) ;;fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)

  (setq *lav4* (float-vector 75.0 50.0 110.0 -110.0 -20.0 -10.0 -10.0))
  (send *pr2* :larm :angle-vector *lav4*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )


;; def funcs
(defun pre-board-set-rarm ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 250) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis nil
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;少し前に
  ;; (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :rarm :end-coords) :copy-worldcoords) :worldpos)))
  ;; ;; v0
  ;; (send *arrow* :translate (float-vector -200 50 50) :world)
  ;; (send *arrow* :rotate (deg2rad -90) :z :world)
  ;; (send *arrow* :rotate (deg2rad 90) :x)
  ;; (send *arrow* :rotate (deg2rad 60) :x :world)
  ;; ;; v1
  ;; (send *arrow* :translate (float-vector 200 -50 50) :world)
  ;; (send *arrow* :rotate (deg2rad 90) :z)
  ;; v2
  (send *arrow* :newcoords (make-coords :pos (float-vector 553.576 -103.557 1158.464) :rpy (float-vector 0.856 0.656 0.542))) ;; fix
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


(defun slide-board-set ()
  ;; slide時の左腕待機座標
  (setq *slide-larm-coords* (calc-coords-from-rel *cutting-board* *slide-larm-coords-rel*))
  (send *arrow* :newcoords (send *slide-larm-coords* :copy-worldcoords))

  (send *ri* :start-grasp :larm :wait t)

  ;; (send *arrow* :translate #f(50 0 0) :world)
  (send *arrow* :translate #f(0 0 50) :local)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (send *arrow* :translate #f(-50 0 0) :world)
  (send *arrow* :translate #f(0 0 -50) :local)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  ;; 右腕のセット
  (pre-board-set-rarm)

  (send *ri* :start-grasp :rarm :wait t)

  ;; slideを始める右腕の位置
  (setq *slide-rarm-coords* (calc-coords-from-rel *cutting-board* *slide-rarm-coords-rel*))
  (send *arrow* :newcoords (send *slide-rarm-coords* :copy-worldcoords))
  ;; (send *arrow* :translate #f(-10 0 100) :world) ;;original
  (send *arrow* :translate #f(10 0 100) :world) ;; fix
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (send *arrow* :translate #f(10 0 -100) :world) ;;original
  (send *arrow* :translate #f(-10 0 -100) :world) ;; fix
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; assoc
  (send (send *pr2* :rarm :end-coords) :assoc *cutting-board*)

  (warn "please run (slide-board) ~%")
  )

(defun slide-board ()
  (setq avs (list))
  (setq tms (list))

  (setq rel-board-move-coords (make-coords :pos (float-vector -4.033 -0.649 9.128) :rpy (float-vector 6.939e-18 0.0 0.0)))

  (dotimes (i 10)
    ;; (send *pr2* :rarm :move-end-pos #f(10 0 0) :world) ;;original
    (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    (send *arrow* :transform (send rel-board-move-coords :copy-worldcoords))
    (send *pr2* :rarm :inverse-kinematics
          (send *arrow* :copy-worldcoords)
          :rotation-axis t
          :debug-view *debug-flag*)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )

  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)

  (send (send *pr2* :rarm :end-coords) :dissoc *cutting-board*)

  (warn "please run (after-slide) ~%")
  )

(defun after-slide ()
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(-10 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (reset-rarm)

  ;; (send *pr2* :larm :move-end-pos #f(50 0 0) :world) ;; original
  (send *pr2* :larm :move-end-pos #f(-50 0 0) :world) ;; fix
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; (send *pr2* :larm :move-end-pos #f(0 -200 0) :world) ;; original
  (send *pr2* :larm :move-end-pos #f(0 200 0) :world) ;; fix
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (warn "please run (grasp-board) ~%")
  )

(defun grasp-board ()
  ;; 掴む位置
  (setq *grasp-larm-coords* (calc-coords-from-rel *cutting-board* *grasp-larm-coords-rel*))
  (send *arrow* :newcoords (send *grasp-larm-coords* :copy-worldcoords))

  ;; (send *arrow* :translate #f(35 -100 0) :world) ;; original
  (send *arrow* :translate #f(-35 100 0) :world) ;; tmp fix

  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm :wait t)

  ;; (send *arrow* :translate #f(-35 100 0) :world) ;; original
  (send *arrow* :translate #f(35 -100 0) :world) ;; tmp fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :larm :wait t)

  (warn "please run (lift-board) ~%")
  )

(defun slide-board-model-set ()
  ;; slide時の左腕待機座標
  (send *arrow* :newcoords (send *slide-larm-coords* :copy-worldcoords))

  (send *ri* :start-grasp :larm :wait t)

  (send *arrow* :translate #f(50 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(-50 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 250) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis nil
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;少し前に
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :rarm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate (float-vector -200 50 50) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)
  (send *arrow* :rotate (deg2rad 90) :x)
  (send *arrow* :rotate (deg2rad 60) :x :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :rarm :wait t)

  ;; slideを始める位置
  (send *arrow* :newcoords (make-coords :pos (send (send (send *cutting-board* :attention-attention0) :copy-worldcoords) :worldpos) :rpy (float-vector -3.086 1.155 3.132)))
  (send *arrow* :translate #f(-10 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(10 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; assoc
  (send (send *pr2* :rarm :end-coords) :assoc *cutting-board*)

  (warn "please run (slide-board) ~%")
  )

(defun grasp-board-model ()
  ;; 掴む位置
  (send *arrow* :newcoords (send (send *cutting-board* :handle-handle0) :copy-worldcoords))

  (send *arrow* :translate #f(35 -100 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm :wait t)

  (send *arrow* :translate #f(-35 100 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :larm :wait t)
  ;; (send *pr2* :larm :end-coords :assoc *cutting-board*)

  (warn "please run (lift-board) ~%")
  )


(defun recieve-cutting-board-with-dialogue ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 250) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis nil
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; まな板を置く位置
  (if (not (eql (send *cutting-board* :parent) nil))
      (send (send *cutting-board* :parent) :dissoc *cutting-board*))
  (send *cutting-board* :newcoords (send *cutting-board-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *cutting-board* :handle-handle0) :copy-worldcoords))
  ;; (send *arrow* :translate (float-vector 100 50 200) :world) ;; orignial
  (send *arrow* :translate (float-vector -100 -50 200) :world) ;; fix

  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :speak-jp "まな板を渡す準備をして，合図をして下さい")
  (receive-with-dialogue-larm :gain 30)

  (warn "please run (put-cutting-board) ~%")
  )

(defun recieve-cutting-board ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 250) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis nil
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; まな板を置く位置
  (if (not (eql (send *cutting-board* :parent) nil))
      (send (send *cutting-board* :parent) :dissoc *cutting-board*))
  (send *cutting-board* :newcoords (send *cutting-board-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *cutting-board* :handle-handle0) :copy-worldcoords))
  ;; (send *arrow* :translate (float-vector 100 50 200) :world) ;; orignial
  (send *arrow* :translate (float-vector -100 -50 200) :world) ;; fix

  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "まな板を握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :larm :wait t)
  (send *ri* :start-grasp :larm :gain 30 :wait t)

  (warn "please run (put-cutting-board) ~%")
  )

(defun put-cutting-board ()
  ;; まな板を置く位置
  (if (not (eql (send *cutting-board* :parent) nil))
      (send (send *cutting-board* :parent) :dissoc *cutting-board*))
  (send *cutting-board* :newcoords (send *cutting-board-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *cutting-board* :handle-handle0) :copy-worldcoords))
  ;; (send *arrow* :translate (float-vector 100 50 200) :world)
  ;; (send *arrow* :translate (float-vector 50 50 200) :world) ;; orignial
  (send *arrow* :translate (float-vector -50 -50 200) :world) ;; fix

  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 下げる
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *arrow* :translate (float-vector 0 0 -115) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; y方向にスライドさせる
  ;; (send *arrow* :translate (float-vector 0 -50 0) :world) ;;original
  (send *arrow* :translate (float-vector 0 50 0) :world) ;;fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm :wait t)

  ;; 左手を離して準備をする
  ;; (send *arrow* :translate #f(50 -100 0) :world) ;;original
  (send *arrow* :translate #f(-50 100 0) :world) ;; fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (push-board-set) ~%")
  )

(defun push-board-set ()
  ;; 右腕のセット
  (pre-board-set-rarm)

  (send *ri* :start-grasp :rarm :wait t)

  ;; slideを止める右腕の位置
  ;; (send *arrow* :newcoords (make-coords :pos #f(458.91 8400.878 30861.651) :rpy #f(-3.086 1.155 3.132))) ;; original
  (send *arrow* :newcoords (make-coords :pos #f(651.09 99.122 861.651) :rpy #f(0.056 1.155 3.132))) ;; fix
  ;; (send *arrow* :translate #f(-10 0 100) :world) ;;original
  (send *arrow* :translate #f(10 0 100) :world) ;; fix
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (send *arrow* :translate #f(10 0 -100) :world) ;;original
  (send *arrow* :translate #f(-10 0 -100) :world) ;; fix
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :larm :wait t)

  ;; まな板をセットする
  (if (not (eql (send *cutting-board* :parent) nil))
      (send (send *cutting-board* :parent) :dissoc *cutting-board*))
  (send *cutting-board* :newcoords (send *cutting-board-coords* :copy-worldcoords))
  (send *cutting-board* :translate (float-vector 100 0 0))
  ;; (send *arrow* :newcoords (make-coords :pos (send (send (send *cutting-board* :attention-attention1) :copy-worldcoords) :worldpos) :rpy (float-vector 2.979 -0.869 0.177))) ;; original
  (send *arrow* :newcoords (make-coords :pos (send (send (send *cutting-board* :attention-attention1) :copy-worldcoords) :worldpos) :rpy (float-vector -0.163 -0.869 0.177))) ;; fix

  ;; (send *arrow* :translate #f(50 -200 0) :world) ;; original
  (send *arrow* :translate #f(-50 200 0) :world) ;; fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (send *arrow* :translate #f(0 200 0) :world) ;; original
  (send *arrow* :translate #f(0 -200 0) :world) ;; fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; (send *arrow* :translate #f(-50 0 0) :world) ;; original
  (send *arrow* :translate #f(50 0 0) :world) ;; fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :end-coords :assoc *cutting-board*)
  (warn "please run (push-board-1) ~%")
  )

(defun push-board-1 ()
  ;; 天板に左腕が当たるまで押し続ける．

  (setq avs (list))
  (setq tms (list))

  (dotimes (i 10)
    ;; (send *pr2* :larm :move-end-pos #f(-10 0 0) :world) ;; original
    (send *pr2* :larm :move-end-pos #f(10 0 0) :world) ;; fix
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )

  (send *ri* :angle-vector-sequence avs tms)

  (ros::unsubscribe "/left_endeffector/wrench")
  (setq *topic-name* "/left_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/left_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-z-cb)

  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
            (ros::spin-once)
            (if *cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      (warn "cancel!!! ~%")
      )
    )

  (ros::unsubscribe "/left_endeffector/wrench")

  (send *pr2* :larm :end-coords :dissoc *cutting-board*)
  (warn "please run (after-push-board-1) or (push-board-2-set) ~%")
  )

(defun push-board-1-fix ()
  ;; 天板に左腕が当たるまで押し続ける．

  (setq avs (list))
  (setq tms (list))

  (setq rel-board-push-larm-coords (make-coords :pos (float-vector 6.37 0.271 -7.704) :rpy (float-vector 0.0 0.0 0.0)))

  (dotimes (i 10)
    ;; (send *pr2* :larm :move-end-pos #f(-10 0 0) :world) ;; original
    ;; (send *pr2* :larm :move-end-pos #f(10 0 0) :world) ;; fix
    (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send *arrow* :transform (send rel-board-push-larm-coords :copy-worldcoords))
    (send *pr2* :larm :inverse-kinematics
          (send *arrow* :copy-worldcoords)
          :rotation-axis t
          :debug-view *debug-flag*)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )

  (send *ri* :angle-vector-sequence avs tms)

  ;; (ros::unsubscribe "/left_endeffector/wrench")
  ;; (setq *topic-name* "/left_endeffector/wrench")
  ;; (setq *cb-flag* nil)
  ;; (ros::subscribe "/left_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-z-cb)

  ;; (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
  ;;   (when (progn
  ;;           (ros::spin-once)
  ;;           (if *cb-flag* t)
  ;;           )
  ;;     (send *ri* :cancel-angle-vector)
  ;;     (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  ;;     (warn "cancel!!! ~%")
  ;;     )
  ;;   )

  ;; (ros::unsubscribe "/left_endeffector/wrench")
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :end-coords :dissoc *cutting-board*)
  (warn "please run (after-push-board-1) or (push-board-2-set) ~%")
  )

(defun push-board-2-set ()
  ;; その時の位置に上からアプローチをする．

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (setq tmp-coords (send *pr2* :larm :end-coords))
  )

(defun push-board-2 ()
  ;; 上からスライドさせて目標まで移動する．
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (setq avs (list))
  (setq tms (list))

  (dotimes (i 10)
    (send *pr2* :larm :move-end-pos #f(-10 0 0) :world)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )

  (send *ri* :angle-vector-sequence avs tms)

  )


(defun after-push-board ()
  
  )

(defun after-push-board-1 ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  ;; (send *arrow* :translate #f(100 0 0) :world) ;; original
  (send *arrow* :translate #f(-100 0 0) :world) ;; fix

  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq *lav4* (float-vector 75.0 50.0 110.0 -110.0 -20.0 -10.0 -10.0))
  (send *pr2* :larm :angle-vector *lav4*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (warn "please run (reset-rarm) ~%")
  )

(defun lift-board ()
  (send *pr2* :larm :move-end-pos #f(0 0 100) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 0 100) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (warn "please run (transfer-to-pot-set) ~%")
  )


(defun transfer-to-pot-set ()
  (send *pr2* :larm :move-end-pos #f(0 0 100) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 -100 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (dotimes (i 2)
    (send *arrow* :rotate (deg2rad 10) :z :world)
    (send *pr2* :larm :inverse-kinematics
          (send *arrow* :copy-worldcoords)
          :rotation-axis t
          :debug-view *debug-flag*)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
    (send *ri* :wait-interpolation)
    )

  (setq *tmp* (send *pr2* :larm :angle-vector))

  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 602.379 8152.78 31274.974) :rpy (float-vector 2.795 -0.12 1.542)))
  ;; (send *pr2* :larm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 633.158 8012.426 31180.818) :rpy (float-vector 2.748 0.077 1.774)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (warn "please run (transfer-to-pot) ~%")
  )

(defun transfer-to-pot ()
  ;; ;; (send *arrow* :newcoords (make-coords :pos (float-vector 743.982 7943.09 31092.558) :rpy (float-vector  -3.005 0.145 1.655)))
  ;; ;; (send *arrow* :newcoords (make-coords :pos (float-vector 737.109 7985.153 31099.402) :rpy (float-vector 3.004 0.222 1.621)))
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 755.645 7945.73 31127.555) :rpy (float-vector 3.038 0.241 1.757)))
  ;; (send *pr2* :larm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  ;; (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (send *pot* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150))
  (send *arrow* :rotate (deg2rad -30) :z)
  ;; (send *arrow* :rotate (deg2rad 30) :y)
  (send *arrow* :rotate (deg2rad 20) :y)

  (send *arrow* :translate #f(-10 0 0))

  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (send *cutting-board* :attention-attention2)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )


(defun set-board-model ()
  (if (not (eql (send *cutting-board* :parent) nil))
      (send (send *cutting-board* :parent) :dissoc *cutting-board*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *cutting-board* :handle-handle0) :copy-worldcoords))
    (send local-cds :assoc *cutting-board*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *cutting-board*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *cutting-board*)
  )

(defun tmp-grasp ()
  ;; 掴む位置
  (setq *grasp-larm-coords* (calc-coords-from-rel *cutting-board* *grasp-larm-coords-rel*))
  (send *arrow* :newcoords (send *grasp-larm-coords* :copy-worldcoords))

  ;; (send *arrow* :translate #f(35 -100 0) :world) ;; original
  (send *arrow* :translate #f(-35 100 0) :world) ;; tmp fix

  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm :wait t)

  ;; (send *arrow* :translate #f(-35 100 0) :world) ;; original
  (send *arrow* :translate #f(35 -100 0) :world) ;; tmp fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :larm :wait t)
  (send *ri* :start-grasp :larm :gain 30 :wait t)

  (set-board-model)

  ;; (send *arrow* :rotate (deg2rad 10) :x :world) ;; original
  (send *arrow* :rotate (deg2rad -10) :x :world) ;; fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (lift-board) ~%")
  )


(defun after-transfer-board ()
  ;; まな板を置く位置
  (if (not (eql (send *cutting-board* :parent) nil))
      (send (send *cutting-board* :parent) :dissoc *cutting-board*))
  (send *cutting-board* :newcoords (send *cutting-board-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *cutting-board* :handle-handle0) :copy-worldcoords))
  (send *arrow* :translate (float-vector 100 50 200) :world)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun after-transfer-board-pot ()
  (send *pr2* :larm :move-end-pos #f(-60 100 50) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(-60 100 60) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (after-transfer-board)
  )

;; knife codes
(defun knife-slide-transfer-set ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 593.408 8513.682 31202.493) :rpy (float-vector -2.624 -0.054 -0.026)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (make-coords :pos (float-vector 635.773 8244.413 31202.306) :rpy (float-vector -2.079 -0.062 -1.446)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (knife-slide-transfer) ~%")
  )

(defun knife-slide-transfer ()
  (setq slide-length 220)
  (setq adj -10)

  (send *arrow* :newcoords (send (send *cutting-board* :attention-attention2) :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 90) :z)
  (send *arrow* :translate (float-vector 0 slide-length adj))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :link-list (list
                    (send *pr2* :rarm))
        :move-target (car (send *knife* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq avs (list))
  (setq tms (list))

  (dotimes (i (+ (/ slide-length 10) 1))
    (send *arrow* :translate #f(0 -10 -3))
    (send *pr2* :rarm :inverse-kinematics
          (send *arrow* :copy-worldcoords)
          :link-list (list
                      (send *pr2* :rarm))
          :move-target (car (send *knife* :attention))
          :rotation-axis t
          :debug-view *debug-flag*)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )

  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)

  (warn "please run (avoid-rarm-knife) ~%")
  )


(defun avoid-rarm-knife ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 635.773 8244.413 31202.306) :rpy (float-vector -2.079 -0.062 -1.446)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (make-coords :pos (float-vector 593.408 8513.682 31202.493) :rpy (float-vector -2.624 -0.054 -0.026)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq *rav0* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav0*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun set-knife-model ()
  (if (not (eql (send *knife* :parent) nil))
      (send (send *knife* :parent) :dissoc *knife*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send *knife* :copy-worldcoords))
    (send local-cds :translate #f(-12 0 0))
    (send local-cds :rotate (deg2rad -90) :x)
    (send local-cds :assoc *knife*)
    (send local-cds :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *knife*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :rarm :end-coords) :assoc *knife*)
  )



(defun now-board-old ()
  (slide-board-set)
  (slide-board)
  (after-slide)
  (grasp-board)
  ;; (tmp-grasp)
  (lift-board)
  )

(defun now-board ()
  (slide-board-set)
  (slide-board)
  (after-slide)
  ;; (grasp-board)
  (tmp-grasp)
  (lift-board)
  )


(defun now-tmp ()
  (set-pose)
  ;; (slide-board-set)
  (slide-board-model-set)
  (slide-board)
  (after-slide)
  (grasp-borad-model)
  )

(defun now-set-board ()
  (recieve-cutting-board)
  (put-cutting-board)
  (push-board-set)
  (push-board-1) ;; (push-board-1-fix)
  (after-push-board-1)
  (reset-rarm)
  )

(defun now-set-board-with-dialogue ()
  (recieve-cutting-board-with-dialogue)
  (put-cutting-board)
  (push-board-set)
  (push-board-1)
  (after-push-board-1)
  (reset-rarm)
  )

(defun only-set-board ()
  (put-cutting-board)
  (push-board-set)
  (push-board-1)
  (after-push-board-1)
  (reset-rarm)
  )

(defun now-cutting-board-transfer-set ()
  (now-board)
  (transfer-to-pot-set)
  (transfer-to-pot)
  )

(defun now-cutting-board-transfer ()
  (knife-slide-transfer-set)
  (knife-slide-transfer)
  (avoid-rarm-knife)
  )

(defun now-cutting-board-transfer-after ()
  (after-transfer-board-pot)
  (only-set-board)
  )

(defun now-cutting-board-transfer-all ()
  (now-cutting-board-transfer-set)
  (grasp-knife)
  (now-cutting-board-transfer)
  (put-knife)
  (reset-rarm)
  (now-cutting-board-transfer-after)
  )

(defun now-cutting-board-transfer-all-with-fail-detection ()
  (now-cutting-board-transfer-set)
  (grasp-knife-with-fail-detection)
  (now-cutting-board-transfer)
  (put-knife)
  (reset-rarm)
  (now-cutting-board-transfer-after)
  )

(defun now-cutting-board-transfer-bowl-1-all-with-fail-detection ()
  (now-board)

  (grasp-knife-with-fail-detection)
  (send *ri* :start-grasp :rarm :wait t :gain 1.00);;強く握る
  (wait-for-bowl-1-rarm)

  (transfer-to-bowl-1-set)
  (transfer-to-bowl-1)

  (knife-slide-transfer-set-bowl-1)
  (knife-slide-transfer)

  (pr2-rarm-up 60)
  (knife-slide-transfer-set-bowl-1)
  (wait-for-bowl-1-rarm)
  (after-transfer-board)
  (put-knife)
  (reset-rarm)

  (only-set-board)
  )

(defun now-cutting-board-transfer-bowl-1-fix ()
  (wait-for-bowl-1-rarm)

  (transfer-to-bowl-1-set)
  (transfer-to-bowl-1)

  (knife-slide-transfer-set-bowl-1)
  (knife-slide-transfer)
  )

(defun now-cutting-board-transfer-bowl-1-all-fix ()
  (now-board)

  ;; (grasp-knife-with-fail-detection) ;; TODO fix
  (grasp-rec-object :object-name "knife" :arm :rarm) ;; TODO
  (send *ri* :start-grasp :rarm :wait t :gain 1.00) ;;強く握る

  (now-cutting-board-transfer-bowl-1-fix)

  (pr2-rarm-up 60)
  (knife-slide-transfer-set-bowl-1)
  (wait-for-bowl-1-rarm)
  (after-transfer-board)
  (put-knife) ;; TODO fix
  (reset-rarm)

  (only-set-board)
  )


(defun now-cutting-board-transfer-pot-all-with-fail-detection ()
  (now-cutting-board-transfer-set)
  (grasp-knife-with-fail-detection)
  (send *ri* :start-grasp :rarm :wait t :gain 1.00);;強く握る
  (now-cutting-board-transfer)
  (put-knife)
  (reset-rarm)
  (now-cutting-board-transfer-after)
  )

(defun wait-for-bowl-1-rarm ()
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 618.498 9129.367 31114.439) :rpy (float-vector 3.063 0.052 -0.106))) ;; original
  (send *arrow* :newcoords (make-coords :pos (float-vector 491.502 -629.367 1114.439) :rpy (float-vector -0.079 0.052 -0.106))) ;; fix
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun knife-slide-transfer-set-bowl-1 ()
  ;; 必要なら座標を作って書く必要がある!
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 509.792 8837.244 31240.433) :rpy (float-vector -2.534 -0.077 -1.369))) ;; original
  (send *arrow* :newcoords (make-coords :pos (float-vector 600.208 -337.244 1240.433) :rpy (float-vector 0.608 -0.077 -1.369))) ;; fix

  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (knife-slide-transfer) ~%")
  )

(defun transfer-to-bowl-1-set ()
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 482.438 8422.731 31090) :rpy (float-vector 2.39 -0.155 1.501))) ;; original
  (send *arrow* :newcoords (make-coords :pos (float-vector 627.562 77.269 1090.0) :rpy (float-vector -0.752 -0.155 1.501))) ;; fix
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun transfer-to-bowl-1 () ;; TODO fix
  (send *arrow* :newcoords (send (send *bowl-1* :attention-attention1) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *arrow* :rotate (deg2rad 135) :z)
  (send *arrow* :rotate (deg2rad -10) :y)
  (send *arrow* :translate #f(-20 0 0))

  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        ;; :link-list (list
        ;;             (send *pr2* :link-list (send *pr2* :larm :end-coords :parent)))
        :link-list (list
                    (send *pr2* :larm))
        :move-target (send *cutting-board* :attention-attention2)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

