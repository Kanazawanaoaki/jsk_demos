#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_utils.l")

;; global variables
(setq *query-butter* "Melted lquid butter")
(setq *query-sunny* "Cooked egg")

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

(defun gaze_area_set_pan ()
  (described_gazing_area_detector-command :query-list (list "the content of the pot" "the content of the frying pan"))
  )

(defun lc_adj_state_recognition-start-butter ()
  (lc_adjusted_clip_state_recognition-command :model_file "melted_butter_content_model_2023_1010_1903.pkl" :target_state *query-butter*)
  )

(defun lc_adj_state_recognition-start-sunny ()
  (lc_adjusted_clip_state_recognition-command :model_file "cooked_sunny_content_model_2023_1010_1904.pkl" :target_state *query-sunny*)
  )

(defun clip-set-to-butter ()
  (clip-query-change :yes-query *yes-query-butter* :no-query *no-query-butter*)
  )

(defun clip-set-to-sunny ()
  (clip-query-change :yes-query *yes-query-sunny* :no-query *no-query-sunny*)
  )


(defun lc_state_recognition-start-butter ()
  (lc_state_recognition-command :yes-query *yes-query-butter* :no-query *no-query-butter* :raw-threshold *raw-thre-butter* :sma-threshold *sma-thre-butter*)
  )

(defun lc_state_recognition-start-sunny ()
  (lc_state_recognition-command :yes-query *yes-query-sunny* :no-query *no-query-sunny* :raw-threshold *raw-thre-sunny* :sma-threshold *sma-thre-sunny*)
  )


(defun set-before-pour ()
  (load-cook-pour-file :file_name "av-files/cook_pour_bowl_to_pan_data_20221027_01.l")
  (cook-pick-short-replay-test)
  )

(defun do-exec-pour (&key (already_set nil))
  (if *speak-jp* (send *ri* :speak-jp "バターが溶けたら卵をフライパンに注ぐ調理を行います")
    (send *ri* :speak-en "I do the cooking, when the butter is melted pour the eggs into the pan."))
  (lc_adj_state_recognition-start-butter)
  (setq *yes-query* "Yes")
  ;; subscribeしてバターが溶けていたら，pourを実行する
  (ros::subscribe "/adjusted_clip_state_recognizer/state" std_msgs::String #'state-cb 1)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'ok-voice-cb)
  ;; while なんちゃら
  (setq *yes-flag* nil)
  (until *yes-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  (pour-egg-to-pan :already_set already_set)

  (ros::unsubscribe "/adjusted_clip_state_recognizer/state")
  (ros::unsubscribe "/speech_to_text")
  )

(defun do-exec-stop ()
  (if *speak-jp* (send *ri* :speak-jp "卵に火が通ったら火を止める調理を行います")
    (send *ri* :speak-en "I do the cooking, when the eggs are cooked, turn off the fire."))
  (lc_adj_state_recognition-start-sunny)
  (setq *yes-query* "Yes")
  ;; subscribeして火が通っていたら，ihを消す
  (ros::subscribe "/adjusted_clip_state_recognizer/state" std_msgs::String #'state-cb 1)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'ok-voice-cb)
  ;; while なんちゃら
  (setq *yes-flag* nil)
  (until *yes-flag*
         (ros::spin-once)
         (ros::sleep)
         )

  (stop-ih)

  (ros::unsubscribe "/adjusted_clip_state_recognizer/state")
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
  ;; (clip-set-to-sunny)
  ;; (lc_state_recognition-start-sunny)
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
  (gaze_area_set_pan)
  (set-before-pour)
  )

(defun cook-sunny-demo () ;; before start you shold set-before-pour
  (do-exec-pour :already_set t)
  (do-exec-stop)
  (if *speak-jp* (send *ri* :speak-jp "目玉焼きの調理を完了しました")
    (send *ri* :speak-en "I have finished cooking the sunny-side up"))
  )
