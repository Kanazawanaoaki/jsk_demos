#!/usr/bin/env roseus

(load "package://jsk_2022_10_egg_dishes/euslisp/pr2_cook_tmp.l")
(load "package://jsk_2022_10_egg_dishes/euslisp/wrench.l")

;; global variables
(setq *yes-query-butter* "Melted lquid butter")
(setq *no-query-butter* "Hard solid butter")
;; (setq *raw-thre-butter* 0.7607421875) ;;tmp
;; (setq *sma-thre-butter* 0.73505859375) ;;tmp
;; (setq *raw-thre-butter* 0.81) ;;tmp
;; (setq *sma-thre-butter* 0.81) ;;tmp
;; (setq *raw-thre-butter* 0.87) ;;tmp
;; (setq *sma-thre-butter* 0.87) ;;tmp
(setq *raw-thre-butter* 0.91) ;;tmp
(setq *sma-thre-butter* 0.91) ;;tmp

(setq *yes-query-sunny* "Cooked egg")
(setq *no-query-sunny* "Raw egg")
;; (setq *raw-thre-sunny* 0.93994140625) ;;tmp
;; (setq *sma-thre-sunny* 0.9404296875) ;;tmp
;; (setq *raw-thre-sunny* 0.87) ;;tmp
;; (setq *sma-thre-sunny* 0.87) ;;tmp
;; (setq *raw-thre-sunny* 0.90) ;;tmp
;; (setq *sma-thre-sunny* 0.90) ;;tmp
(setq *raw-thre-sunny* 0.95) ;;tmp
(setq *sma-thre-sunny* 0.95) ;;tmp

(setq *yes-flag* nil)
(setq *speak-jp* t)


(defun check-pot-place-before ()
  (send *ri* :stop-grasp :larm :wait t)

  (reset-manip-pose)

  (send *robot* :larm :angle-vector #f(18.2499 59.1407 82.752 -95.0231 -78.2344 -64.0696 75.1862))
  (send *ri* :angle-vector (send *robot* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  (send *robot* :larm :angle-vector #f(10.0796 51.754 65.176 -84.298 -78.5327 -57.4061 69.7143))
  (send *ri* :angle-vector (send *robot* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
  )

(defun check-pot-place-after ()
  (send *ri* :stop-grasp :larm :wait t)

  (send *robot* :larm :angle-vector #f(18.2499 59.1407 82.752 -95.0231 -78.2344 -64.0696 75.1862))
  (send *ri* :angle-vector (send *robot* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  (reset-manip-pose)
  )


(defun state-cb (msg)
  (print msg)
  (setq *hoge* msg)
  (setq data (send msg :data))
  (if (equal data *yes-query*)
      (progn
        (setq *yes-flag* t)
        (if *speak-jp* (send *ri* :speak-jp "状態変化を認識しました")
          (send *ri* :speak-en "I recognized the state change."))
        ))
  )

(defun ok-voice-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *voice-data* (send *msg* :transcript))
    (setq *voice-data-flag* t)
    (format t "voice-data: ~A ~%" *voice-data*)
    (if (equal *voice-data* '("OK"))
        (progn
          (if *speak-jp* (send *ri* :speak-jp "ありがとうございます")
            (send *ri* :speak-en "Thank you!"))
          (format t "了解しました！ ~%" *voice-data*)
          (setq *yes-flag* t)
          ))
    )
  )

(defun set-before-pour ()
  (load-cook-pour-file :file_name "av-files/cook_pour_bowl_to_pan_data_20221027_01.l")
  (cook-pick-short-replay-test)
  )

(defun pour-egg-to-pan (&key (already_set nil) (set-after t))
  (load-cook-pour-file :file_name "av-files/cook_pour_bowl_to_pan_data_20221027_01.l")
  (if already_set
      (cook-pour-short-replay-test)
    (cook-pick-and-pour-short-replay-test)
    )
  (if set-after
      (progn
        (clip-set-to-sunny)
        (stvlm-start-sunny)
        ))
  (reset-manip-pose :time 2000)
  )

(defun pour-egg-to-pot ()
  (load-cook-pour-file :file_name "av-files/cook_pour_bowl_to_pot_data_20221027_02.l")
  (cook-pick-and-pour-short-replay-test)
  (reset-manip-pose)
  )

(defun pour-butter-to-pan ()
  ;; (load-cook-pour-file :file_name "av-files/cook_pour_butter_bowl_to_pan_data_20230603_01.l")
  (load-cook-pour-file :file_name "av-files/cook_pour_butter_bowl_to_pan_data_20230603_02.l")
  (cook-pick-and-pour-short-replay-test)
  (reset-manip-pose :time 2000)
  )

(defun stop-ih ()
  ;; (load-cook-file :file_name "av-files/cook_data_stop-ih_20221027_02.l")
  (load-cook-file :file_name "av-files/cook_data_stop-ih_20230405_01.l")
  (send *ri* :start-grasp :rarm :wait t)
  (cook-replay-once)
  (reset-manip-pose)
  )

(defun set-demo ()
  (clip-set-to-butter)
  (set-before-pour)
  )

(defun pour (ing tool)
  (format t "pour ~A to ~A ~%" ing tool)
  (cond
   ((and (equal ing "egg") (equal tool "frying pan"))
    (pour-egg-to-pan :set-after nil)
    )
   ((and (equal ing "egg") (equal tool "pot"))
    (pour-egg-to-pot)
    )
   ((and (equal ing "butter") (equal tool "frying pan"))
    (pour-butter-to-pan)
    )
   (t
    (print "Sorry. this ing and tool pattern is not defined"))
   )
  )

(defun move-until-touch (&rest args &key (arm :rarm))
  (let (av avs tms)
    (dotimes (i 15)
      (send *pr2* arm :move-end-pos #f(10 0 0) :world)
      (setq av (send *pr2* :angle-vector))
      (setq avs (append avs (list av)))
      (setq tms (append tms (list 400)))
      )
    (send *ri* :angle-vector-sequence avs tms))

  (cancel-motion-when-touch :arm arm :direction :x :threshold -15)
  )

(defun rotate-knob (&rest args &key (deg 30) (arm :larm) &allow-other-keys)
  ;; rotate
  (let (av avs tms (ik-target (send (send *pr2* arm :end-coords) :copy-worldcoords)))
    (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    (send *pr2* :head-neck-y :joint-angle *initial-head-neck-y*)
    (send *pr2* :head-neck-p :joint-angle *initial-head-neck-p*)

    (if (> deg 0)
      (progn
        (dotimes (i (/ deg 10))
          (send ik-target :rotate (deg2rad 10) :x)
          (send *pr2* arm :inverse-kinematics
                (send ik-target :copy-worldcoords)
                :rotation-axis t
                :debug-view nil)
          (setq av (send *pr2* :angle-vector))
          (setq avs (append avs (list av)))
          (setq tms (append tms (list 200)))
          ))
      (dotimes (i (/ (* deg -1) 10))
        (send ik-target :rotate (deg2rad -10) :x)
        (send *pr2* arm :inverse-kinematics
              (send ik-target :copy-worldcoords)
              :rotation-axis t
              :debug-view nil)
        (setq av (send *pr2* :angle-vector))
        (setq avs (append avs (list av)))
        (setq tms (append tms (list 200)))
        )
      )
    (send *ri* :angle-vector-sequence avs tms)
    (send *ri* :wait-interpolation)
    )
  )

(defun fire-on (tool)
  (format t "on ~A  ~%" tool)
  (load-cook-file :file_name "av-files/cook_data_stop-ih_20230405_01.l")
  (send *ri* :start-grasp :rarm :wait t)
  (cook-replay-once)

  ;; grasp knob
  (send *ri* :move-gripper :rarm 0.08)

  (let ((ik-target (make-coords :pos (float-vector 540 -50 700) :rpy (float-vector -0.008 -0.028 3.108))))
    (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    (send *pr2* :rarm :inverse-kinematics
          (send ik-target :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation)

    ;; (move-until-touch)
    ;; (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    ;; (send ik-target :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    ;; (send ik-target :translate #f(-10 0 0) :world)
    ;; (send *pr2* :rarm :inverse-kinematics
    ;;       (send ik-target :copy-worldcoords)
    ;;       :rotation-axis t
    ;;       :debug-view nil)
    ;; (send *ri* :angle-vector (send *pr2* :angle-vector))
    ;; (send *ri* :wait-interpolation)
    )

  (send *ri* :start-grasp :rarm :wait t :gain 100)
  ;; rotate
  (rotate-knob :deg 30 :arm :rarm)
  ;; release
  (send *ri* :stop-grasp :rarm :wait t)
  (set-initial-av)
  (reset-manip-pose)
  )

(defun fire-off (tool)
  (format t "off ~A ~%" tool)
  (stop-ih)
  )

(defun START-CONDITION (condition action)
  (format t "start ~A action if ~A condition ~%" action condition)

  (cond
   ((equal condition "melted liquid butter")
    (setq *yes-query* *yes-query-butter*)
    (setq *no-query* *no-query-butter*)
    (setq *raw-thre* *raw-thre-butter*)
    (setq *sma-thre* *sma-thre-butter*)
    )
   ((equal condition "cooked egg")
    (setq *yes-query* *yes-query-sunny*)
    (setq *no-query* *no-query-sunny*)
    (setq *raw-thre* *raw-thre-sunny*)
    (setq *sma-thre* *sma-thre-sunny*)
    )
   )
  ;; set
  (clip-query-change :yes-query *yes-query* :no-query *no-query*)
  (stvlm-command :yes-query *yes-query* :no-query *no-query* :raw-threshold *raw-thre* :sma-threshold *sma-thre*)

  ;; subscribeして条件を満たしていたら，actionを実行する．
  (ros::subscribe "/inference_probability_sma/state" std_msgs::String #'state-cb 1)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'ok-voice-cb)
  ;; while なんちゃらとかのほうが良い？マクロの問題？
  (setq *yes-flag* nil)
  (until *yes-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  (eval action)

  (ros::unsubscribe "/inference_probability_sma/state")
  (ros::unsubscribe "/speech_to_text")
  )

(defun cook-demo-from-recipe ()
  ;; TODO args recipe-name などいれたい
  (load "package://jsk_2022_10_egg_dishes/recipes/converted/lisp-converted-butter-sunny-side-up_converted.txt")
  )

(format t "~%")
