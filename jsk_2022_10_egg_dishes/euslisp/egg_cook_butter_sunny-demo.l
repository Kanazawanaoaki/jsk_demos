#!/usr/bin/env roseus

(load "package://jsk_2022_10_egg_dishes/euslisp/pr2_cook_tmp.l")

;; global variables
(setq *yes-query-butter* "Melted lquid butter")
(setq *no-query-butter* "Hard solid butter")
;; (setq *raw-thre-butter* 0.7607421875) ;;tmp
;; (setq *sma-thre-butter* 0.73505859375) ;;tmp
;; (setq *raw-thre-butter* 0.81) ;;tmp
;; (setq *sma-thre-butter* 0.81) ;;tmp
(setq *raw-thre-butter* 0.87) ;;tmp
(setq *sma-thre-butter* 0.87) ;;tmp

(setq *yes-query-sunny* "Cooked egg")
(setq *no-query-sunny* "Raw egg")
;; (setq *raw-thre-sunny* 0.93994140625) ;;tmp
;; (setq *sma-thre-sunny* 0.9404296875) ;;tmp
;; (setq *raw-thre-sunny* 0.87) ;;tmp
;; (setq *sma-thre-sunny* 0.87) ;;tmp
(setq *raw-thre-sunny* 0.90) ;;tmp
(setq *sma-thre-sunny* 0.90) ;;tmp

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

(defun clip-set-to-butter ()
  (clip-query-change :yes-query *yes-query-butter* :no-query *no-query-butter*)
  )

(defun clip-set-to-sunny ()
  (clip-query-change :yes-query *yes-query-sunny* :no-query *no-query-sunny*)
  )

(defun stvlm-start-butter ()
  (stvlm-command :yes-query *yes-query-butter* :no-query *no-query-butter* :raw-threshold *raw-thre-butter* :sma-threshold *sma-thre-butter*)
  )

(defun stvlm-start-sunny ()
  (stvlm-command :yes-query *yes-query-sunny* :no-query *no-query-sunny* :raw-threshold *raw-thre-sunny* :sma-threshold *sma-thre-sunny*)
  )


(defun set-before-pour ()
  (load-cook-pour-file :file_name "av-files/cook_pour_bowl_to_pan_data_20221027_01.l")
  (cook-pick-short-replay-test)
  )

(defun do-exec-pour (&key (already_set nil))
  (if *speak-jp* (send *ri* :speak-jp "バターが溶けたら卵をフライパンに注ぐ調理を行います")
    (send *ri* :speak-en "I do the cooking, when the butter is melted pour the eggs into the pan."))
  (stvlm-start-butter)
  (setq *yes-query* *yes-query-butter*)
  ;; subscribeしてバターが溶けていたら，pourを実行する
  (ros::subscribe "/inference_probability_sma/state" std_msgs::String #'state-cb 1)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'ok-voice-cb)
  ;; while なんちゃら
  (setq *yes-flag* nil)
  (until *yes-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  (pour-egg-to-pan :already_set already_set)

  (ros::unsubscribe "/inference_probability_sma/state")
  (ros::unsubscribe "/speech_to_text")
  )

(defun do-exec-stop ()
  (if *speak-jp* (send *ri* :speak-jp "卵に火が通ったら火を止める調理を行います")
    (send *ri* :speak-en "I do the cooking, when the eggs are cooked, turn off the fire."))
  (stvlm-start-sunny)
  (setq *yes-query* *yes-query-sunny*)
  ;; subscribeして火が通っていたら，ihを消す
  (ros::subscribe "/inference_probability_sma/state" std_msgs::String #'state-cb 1)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'ok-voice-cb)
  ;; while なんちゃら
  (setq *yes-flag* nil)
  (until *yes-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  (stop-ih)

  (ros::unsubscribe "/inference_probability_sma/state")
  (ros::unsubscribe "/speech_to_text")
  )

(defun do-exec-tmp ()
  ;; subscribeして沸騰していたら，pourを実行するプログラムを書く
  (ros::subscribe "/inference_probability_sma/state" std_msgs::String #'state-cb 1)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'ok-voice-cb)
  ;; while なんちゃら
  (setq *yes-flag* nil)
  (until *yes-flag*
         (print 1)
         (ros::spin-once)
         (ros::sleep)
         )
  (print 2)
  ;; (pour-egg-to-pot)

  (ros::unsubscribe "/inference_probability_sma/state")
  )

(defun pour-egg-to-pan (&key (already_set nil))
  (load-cook-pour-file :file_name "av-files/cook_pour_bowl_to_pan_data_20221027_01.l")
  (if already_set
      (cook-pour-short-replay-test)
    (cook-pick-and-pour-short-replay-test)
    )
  (clip-set-to-sunny)
  (stvlm-start-sunny)
  (reset-manip-pose :time 2000)
  )

(defun pour-egg-to-pot ()
  (load-cook-pour-file :file_name "av-files/cook_pour_bowl_to_pot_data_20221027_02.l")
  (cook-pick-and-pour-short-replay-test)
  (reset-manip-pose)
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

(defun cook-sunny-demo () ;; before start you shold set-before-pour
  (do-exec-pour :already_set t)
  (do-exec-stop)
  (if *speak-jp* (send *ri* :speak-jp "目玉焼きの調理を完了しました")
    (send *ri* :speak-en "I have finished cooking the sunny-side up"))
  )
