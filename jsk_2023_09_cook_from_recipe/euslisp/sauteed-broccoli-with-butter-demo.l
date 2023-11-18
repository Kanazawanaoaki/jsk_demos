#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_tmp.l")


(ros::load-ros-manifest "roseus")
(ros::roseus "sauteed-broccoli")
(ros::advertise "/pr2_cook_imagebind/change_recog" std_msgs::string 1)


(setq *initial-head-neck-y* 0)
(setq *initial-head-neck-p* 50)

(setq *state-thre* 0.7) ;; 0.8

(setq *yes-flag* nil)
(setq *speak-jp* t)


;;; for broccoli programs

(defun state-cb (msg)
  (setq *hoge* msg)
  (setq data (send msg :data))
  (print data)
  (if (>= data *state-thre*)
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

(defun stop-ih (&key (left nil) (only-stop t))
  (send *pr2* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *pr2* :head-neck-p :joint-angle *initial-head-neck-p*)

  (if left
      (send *pr2* :rarm :angle-vector #f(-14.727 68.7101 -60.2136 -76.3185 109.312 -48.51 -7.17108))
    (send *pr2* :rarm :angle-vector #f(-37.9792 67.891 -75.6121 -80.9552 114.675 -44.3419 -2.95313)))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  (send *ri* :start-grasp :rarm :wait t)

  (if left
      (send *pr2* :rarm :angle-vector #f(-10.3805 65.2155 -51.4302 -73.631 122.477 -46.0296 -19.6429))
    (send *pr2* :rarm :angle-vector #f(-32.9823 60.3212 -73.0221 -74.5233 120.244 -39.7369 -5.03581)) ;; #f(-31.9892 63.9795 -66.939 -75.7959 118.513 -36.3796 -8.94601))
    )
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos #f(10 0 0))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (if left
      (send *pr2* :rarm :angle-vector #f(-14.727 68.7101 -60.2136 -76.3185 109.312 -48.51 -7.17108))
    (send *pr2* :rarm :angle-vector #f(-37.9792 67.891 -75.6121 -80.9552 114.675 -44.3419 -2.95313)))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (when only-stop
    (send *pr2* :rarm :angle-vector #f(-75.0 50.0 -110.0 -110.0 20.0 -10.0 -10.0))
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)
    )
  )

(defun start-ih (&key (left nil) (max-power nil))
  (stop-ih :left left :only-stop nil)

  ;; grasp knob
  (send *ri* :move-gripper :rarm 0.08)

  (let ((ik-target))
    (if left
        (setq ik-target (make-coords :pos (float-vector 642 -60 695) :rpy (float-vector -0.008 -0.028 3.108)))
      (setq ik-target (make-coords :pos (float-vector 636 -183 698) :rpy (float-vector -0.008 -0.028 3.108)))
      )
    ;; (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    (send *pr2* :rarm :inverse-kinematics
          (send ik-target :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation)
    )

  (send *ri* :start-grasp :rarm :wait t :gain 100)
  ;; rotate
  (rotate-knob :deg 30 :arm :rarm)
  (if max-power
      (progn
        (unix:sleep 1)
        (rotate-knob :deg 60 :arm :rarm)
        ))
  ;; release
  (send *ri* :stop-grasp :rarm :wait t)
  (if left
      (send *pr2* :rarm :angle-vector #f(-14.727 68.7101 -60.2136 -76.3185 109.312 -48.51 -7.17108))
    (send *pr2* :rarm :angle-vector #f(-37.9792 67.891 -75.6121 -80.9552 114.675 -44.3419 -2.95313)))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :angle-vector #f(-75.0 50.0 -110.0 -110.0 20.0 -10.0 -10.0))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun gaze-left-pot ()
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "offset_x" :int 855)
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "offset_y" :int 330)
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "width" :int 270)
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "height" :int 180)
  )

(defun gaze-right-pan ()
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "offset_x" :int 1240)
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "offset_y" :int 390)
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "width" :int 270)
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "height" :int 190)
  )

(defun imagebind-recog-change (&key (now-str "water"))
  (setq msg (instance std_msgs::string :init))
  (send msg :data now-str)
  (ros::ros-info "msg [~A]" (send msg :data))
  (ros::publish "/pr2_cook_imagebind/change_recog" msg)
  )

(defun start-imagebind-recog (&key (stop-flag nil))
  (let ((req (instance std_srvs::EmptyRequest :init))
        (res))
    (if stop-flag
        (setq res (ros::service-call "/stop_moving_average" req))
      (setq res (ros::service-call "/start_moving_average" req)))
    ))

(defun set-spatula-before ()
  ;; ヘラを右手に持たせてもらってセットする．
  (send *pr2* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *pr2* :head-neck-p :joint-angle *initial-head-neck-p*)

  (send *pr2* :rarm :angle-vector #f(-30.1271 52.4002 -21.5612 -97.3208 -174.632 -50.0581 183.851))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *ri* :speak-jp "右のグリッパを開きます" :wait t)
  (unix:sleep 1)
  (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :speak-jp "ヘラを握らせてください" :wait t)
  (unix:sleep 2)
  (send *ri* :start-grasp :rarm :wait t)

  (send *pr2* :rarm :angle-vector #f(-26.6595 53.6895 -21.6806 -69.5417 -160.055 -18.0071 168.228))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (send *ri* :stop-grasp :rarm :wait t)

  (send *pr2* :rarm :angle-vector #f(-30.1271 52.4002 -21.5612 -97.3208 -174.632 -50.0581 183.851))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (reset-manip-pose)
  )


(defun check-pan-place-before ()
  (send *ri* :stop-grasp :larm :wait t)
  (send *pr2* :larm :angle-vector #f(-2.16948 58.9145 58.0178 -79.2714 -86.4096 -59.9209 70.946))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :angle-vector #f(-1.17669 49.1576 57.3471 -69.9481 -90.1283 -56.4981 64.4919))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (send *ri* :start-grasp :larm :wait t)

  (send *ri* :speak-jp "チェックが終わったらokと言ってください")
  (ros::unsubscribe "/speech_to_text")
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'ok-voice-cb)
  (setq *yes-flag* nil)
  (until *yes-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  (ros::unsubscribe "/speech_to_text")

  (send *ri* :stop-grasp :larm :wait t)
  (send *pr2* :larm :angle-vector #f(-2.16948 58.9145 58.0178 -79.2714 -86.4096 -59.9209 70.946))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (reset-manip-pose)
  )

(defun check-pot-place-before ()
  ;; after grasp yudezaru
  (send *pr2* :larm :angle-vector #f(27.5715 22.0148 51.6599 -44.6906 40.8698 -83.3365 -15.6292))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :angle-vector #f(22.3415 18.6413 51.3751 -30.3821 39.7562 -83.6954 -23.382))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *ri* :speak-jp "チェックが終わったらokと言ってください")
  (ros::unsubscribe "/speech_to_text")
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'ok-voice-cb)
  (setq *yes-flag* nil)
  (until *yes-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  (ros::unsubscribe "/speech_to_text")

  ;; 鍋から遠ざける
  (send *pr2* :larm :angle-vector #f(27.5715 22.0148 51.6599 -44.6906 40.8698 -83.3365 -15.6292))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :angle-vector #f(45.532 15.6265 43.8688 -52.2305 36.9455 -101.153 -32.4685))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun 00-set-initial-demo-pose () ;; 左手にザルを持たせて，という状況
  (send *pr2* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *pr2* :head-neck-p :joint-angle *initial-head-neck-p*)

  (send *pr2* :larm :angle-vector #f(45.532 15.6265 43.8688 -52.2305 36.9455 -101.153 -32.4685))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :speak-jp "左のグリッパを開きます" :wait t)
  (unix:sleep 1)
  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "茹でざるを握らせてください" :wait t)
  (unix:sleep 2)
  (send *ri* :start-grasp :larm :wait t)
  (send *ri* :start-grasp :larm :wait t :gain 100)
  )

(defun set-demo-before ()
  (set-spatula-before)
  (check-pan-place-before)
  (00-set-initial-demo-pose)
  (check-pot-place-before)
  )

(defun 01-start-left-ih ()
  ;; 左側のコンロを右腕でつける
  (start-ih :left t :max-power t)
  )

(defun 02-boil-broccoli-after-boil ()
  ;; 沸騰するまで待つ
  (gaze-left-pot)
  (imagebind-recog-change :now-str "water")
  (start-imagebind-recog)

  (ros::unsubscribe "/pr2_cook_imagebind/recog_result/moving_average")
  (ros::unsubscribe "/speech_to_text")
  (ros::subscribe "/pr2_cook_imagebind/recog_result/moving_average" std_msgs::Float32 #'state-cb 1)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'ok-voice-cb)
  (setq *yes-flag* nil)
  (until *yes-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  (start-imagebind-recog :stop-flag t)
  (ros::unsubscribe "/pr2_cook_imagebind/recog_result/moving_average")
  (ros::unsubscribe "/speech_to_text")

  ;; 鍋にブロッコリーを掲げる
  (send *pr2* :larm :angle-vector #f(27.5715 22.0148 51.6599 -44.6906 40.8698 -83.3365 -15.6292))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :angle-vector #f(22.3415 18.6413 51.3751 -30.3821 39.7562 -83.6954 -23.382))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; 3分間 茹でる
  (unix:sleep 180)

  ;; 鍋から遠ざける
  (send *pr2* :larm :angle-vector #f(27.5715 22.0148 51.6599 -44.6906 40.8698 -83.3365 -15.6292))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  )

(defun 03-stop-left-ih ()
  ;; 左側のコンロの火を止める
  (stop-ih :left t)
  )

(defun 04-start-right-ih ()
  ;; 右側のコンロの火をつける
  (start-ih)
  )

(defun 05-transfer-boil-to-pan ()
  ;; バターが溶けたら
  (gaze-right-pan)
  (imagebind-recog-change :now-str "butter")
  (start-imagebind-recog)

  (ros::unsubscribe "/pr2_cook_imagebind/recog_result/moving_average")
  (ros::unsubscribe "/speech_to_text")
  (ros::subscribe "/pr2_cook_imagebind/recog_result/moving_average" std_msgs::Float32 #'state-cb 1)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'ok-voice-cb)
  (setq *yes-flag* nil)
  (until *yes-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  (start-imagebind-recog :stop-flag t)
  (ros::unsubscribe "/pr2_cook_imagebind/recog_result/moving_average")
  (ros::unsubscribe "/speech_to_text")

  ;; 注ぐ
  (load-cook-file :file_name "av-files/cook_larm-data_transfer-broccoli_20231119_01.l" :larm t)
  (cook-replay-once :larm t)

  ;; 鍋に茹でざるを置く
  (send *pr2* :larm :angle-vector #f(27.5715 22.0148 51.6599 -44.6906 40.8698 -83.3365 -15.6292))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :angle-vector #f(22.3415 18.6413 51.3751 -30.3821 39.7562 -83.6954 -23.382))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (send *ri* :stop-grasp :larm :wait t);; グリッパを離す

  ;; 避けながら待機姿勢に
  (send *pr2* :larm :angle-vector #f(29.6806 15.389 44.2822 -27.4292 48.3835 -102.856 -13.6897))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (reset-manip-pose)
  )

(defun 06-ready-for-stir-fry ()
  ;; 左手でフライパンを抑える
  (send *pr2* :larm :angle-vector #f(-2.16948 58.9145 58.0178 -79.2714 -86.4096 -59.9209 70.946))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (send *ri* :stop-grasp :larm :wait t)

  (send *pr2* :larm :angle-vector #f(-1.17669 49.1576 57.3471 -69.9481 -90.1283 -56.4981 64.4919))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (send *ri* :start-grasp :larm :wait t)

  ;; 右手でヘラ等を持つ
  (send *pr2* :rarm :angle-vector #f(-30.1271 52.4002 -21.5612 -97.3208 -174.632 -50.0581 183.851))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (send *ri* :stop-grasp :rarm :wait t)

  (send *pr2* :rarm :angle-vector #f(-26.6595 53.6895 -21.6806 -69.5417 -160.055 -18.0071 168.228))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (send *ri* :start-grasp :rarm :wait t)

  (send *pr2* :rarm :angle-vector #f(-24.1941 35.1112 -15.0104 -84.0824 -166.694 -54.7372 177.476))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  )

(defun 07-stir-fry-broccoli ()
  ;; stir fry broccoli
  (load-cook-file :file_name "av-files/cook_data_mix-broccoli_20231119_01.l")
  (cook-replay-once)
  )

(defun 08-end-cook-broccoli ()
  ;; ヘラをおく
  (send *pr2* :rarm :angle-vector #f(-26.6595 53.6895 -21.6806 -69.5417 -160.055 -18.0071 168.228))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :arms :wait t)

  (send *pr2* :rarm :angle-vector #f(-30.1271 52.4002 -21.5612 -97.3208 -174.632 -50.0581 183.851))
  (send *pr2* :larm :angle-vector #f(-2.16948 58.9145 58.0178 -79.2714 -86.4096 -59.9209 70.946))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (reset-manip-pose)

  ;; 右のコンロを消す
  (stop-ih)

  (reset-manip-pose)
  )

(warn "please run (set-demo-before) and (exec-demo) ~%")

(defun exec-demo ()
  (01-start-left-ih)
  (02-boil-broccoli-after-boil)
  (03-stop-left-ih)
  (04-start-right-ih)
  (05-transfer-boil-to-pan)
  (06-ready-for-stir-fry)
  (07-stir-fry-broccoli)
  (08-end-cook-broccoli)
  )

(defun tmp-exec ()
  (05-transfer-boil-to-pan)
  (06-ready-for-stir-fry)
  (07-stir-fry-broccoli)
  (08-end-cook-broccoli)
  )
