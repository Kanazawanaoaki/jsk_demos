(require :pr2-interface "package://pr2eus/pr2-interface.l")
(require :pr2-cook-tmp "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_tmp.l")

(setq *initial-head-neck-y* 0.0)
(setq *initial-head-neck-p* 50.0)

(setq *yes-flag* nil)
(setq *speak-jp* t)

(setq *ih-left-target* (make-coords :pos #f(645 -55 696.789) :rpy #f(-0.089 0.092 1.448)))
;; (setq *ih-left-target* (make-coords :pos #f(640 -45 696.789) :rpy #f(-0.089 0.092 1.448)))
(setq *diff-left-ih* (make-coords :pos #f(-2.744 25.87 168.634) :rpy #f(2.227 1.403 0.485)))
;; (setq *ih-right-target* (make-coords :pos #f(645.029 -183.873 696.789) :rpy #f(-0.089 0.092 1.448)))
;; (setq *ih-right-target* (make-coords :pos #f(635 -173 696.789) :rpy #f(-0.089 0.092 1.448)))
(setq *ih-right-target* (make-coords :pos #f(645.029 -178.873 696.789) :rpy #f(-0.089 0.092 1.448)))
(setq *diff-right-ih* (make-coords :pos #f(-10.312 154.361 175.035) :rpy #f(2.227 1.403 0.485)))
(setq *ih-rec-norm-thre* 100)

(defun stir-fry-cook-stove (&key (object-name "egg-mixture") (vessel "フライパン") (tool "ヘラ") (state "soft-scrambled-egg") (spot "stove"))
  (let ((pre-set-avs (list))
        cook-from-now-file-name
        now-msg
        model_file
        target_state
        )

    ;; フライパンを抑える
    (hold-pot-on-stove :arm :larm :object-name vessel :grasp-flag t)

    (cond
     ((and
       (string= object-name "broccoli")
       (string= vessel "フライパン")
       (string= tool "ヘラ")
       (string= state "twenty-seconds")
       (string= spot "stove")
       )
      ;; (setq cook-from-now-file-name "../../av-files/cook-from-now-stir-fry-in-pan-20240221-data.l")
      (setq cook-from-now-file-name "../../av-files/cook-from-now-stir-fry-in-pan-20240310-data.l")
      (load-cook-from-now-file :file_name cook-from-now-file-name :larm nil)
      (cook-from-now-replay-once :larm nil :initial-av t)
      )
     ((and
       (string= object-name "egg-mixture")
       (string= vessel "フライパン")
       (string= tool "ヘラ")
       (string= state "soft-scrambled-egg")
       (string= spot "stove")
       )
      (setq pre-set-avs (list #f(-23.3076 50.4461 -21.9938 -121.268 -173.134 -64.7071 191.807)))
      ;; (setq cook-from-now-file-name "av-files/cook-from-now-stirfry-with-spatula-and-pan-rarm-20231212-data.l")

      ;; 物体把持初期姿勢
      (send *pr2* :rarm :angle-vector (elt (reverse pre-set-avs) 0))
      (send *ri* :angle-vector (send *pr2* :angle-vector))
      (send *ri* :wait-interpolation)
      (send *ri* :start-grasp :rarm :wait t :gain 100)

      (setq cook-from-now-file-name "../../av-files/cook-from-now-stir-fry-in-pan-20240221-data.l")
      (setq model_file "2023-12-12_cook_sunny_datas_model_2023_1212_2131.pkl") ;; TODO
      (setq target_state "soft-scrambled-egg")
      ;; 状態を認識しながら実行
      (described_gazing_area_detector-command :query-list (list "the content of the pot" "the content of the frying pan"))
      (lc_adjusted_clip_state_recognition-command :model_file model_file :target_state target_state)

      (setq *yes-flag* nil)
      (until *yes-flag*
             (load-cook-from-now-file :file_name cook-from-now-file-name :larm nil)
             (cook-from-now-replay-once :larm nil :initial-av t)
             ;; 認識
             (setq now-msg (one-shot-subscribe "/adjusted_clip_state_recognizer/value" std_msgs::Float32))
             (format t "now data is ~A ~%" (send now-msg :data))
             (if (= (send now-msg :data) 1)
                 (setq *yes-flag* t)
               )
             ;; ;; tmp
             ;; (format t "please type y if you want to finish !! ~%")
             ;; (setq w (read-line))
             ;; (if (equal w "y")
             ;;     (setq *yes-flag* t)
             ;;   )
             )
      )
     )

    ;; フライパンから手を離す
    (release-pot-on-stove :arm :larm)
    )
  )


(defun gaze-left-pot ()
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "offset_x" :int 850) ;; 855
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "offset_y" :int 300) ;; 330
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "width" :int 270)
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "height" :int 180)
  )

(defun gaze-right-pan ()
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "offset_x" :int 1240) ;; 1240
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "offset_y" :int 350) ;; 390
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "width" :int 270)
  (ros::set-dynamic-reconfigure-param
   "/rect_added_image_publisher" "height" :int 190)
  )

(defun wait-cook-stove (&key (object-name "egg") (state "heat-through") (vessel "フライパン"))
  (cond
   ;; state が時間指定ならその時間待つ
   ((string= state "thirty-seconds") ;; TODO ここは賢く処理をしたい
    (unix:sleep 30)
    (return-from wait-cook-stove t)
    )
   ((string= state "three-minutes") ;; TODO ここは賢く処理をしたい
    (unix:sleep 180)
    (return-from wait-cook-stove t)
    )
   ;; それ以外なら状態変化をみる．
   (t
    (let (model_file
          target_state)
      (cond
       ((and ;; 目玉焼き
         (or (string= state "heat-through") (string= state "cooked-egg"))
         (string= object-name "egg")
         (string= vessel "フライパン")
         )
        ;; (setq model_file "cooked_sunny_content_model_2023_1010_1904.pkl") ;; TODO
        (setq model_file "2023-12-12_cook_sunny_datas_model_2023_1212_2131.pkl")
        (setq target_state "egg is cooked")
        (gaze-right-pan)
        )
       ((and ;; butter melt
         (or (string= state "melt") (string= state "melted"))
         (string= object-name "butter")
         (string= vessel "フライパン")
         )
        (setq model_file "2023-12-12_cook_sunny_datas_model_2023_1212_2131.pkl") ;; TODO
        (setq target_state "butter is melt")
        (gaze-right-pan)
        )
       ((and ;; boil
         (or (string= state "boiled-water") (string= state "boiled"))
         (string= object-name "water")
         (string= vessel "鍋")
         )
        (setq model_file "2023-12-12_cook_sunny_datas_model_2023_1212_2131.pkl") ;; TODO
        (setq target_state "water is boiled")
        (gaze-left-pot)
        )
       (t
        (format t "object-name ~A, state ~A, vessel ~A is not defined !!!~%" object-name state vessel)
        (return-from wait-cook-stove nil)
        )
       )

      ;; ;; 鍋やフライパンの領域を注視
      ;; (described_gazing_area_detector-command :query-list (list "the content of the pot" "the content of the frying pan"))

      ;; 状態認識器をセット
      (lc_adjusted_clip_state_recognition-command :model_file model_file :target_state target_state)

      (setq *yes-query* "Yes")
      ;; subscribeして状態が変化していたら終了
      (ros::unsubscribe "/adjusted_clip_state_recognizer/state")
      (ros::unsubscribe "/speech_to_text")
      (ros::subscribe "/adjusted_clip_state_recognizer/state" std_msgs::String #'state-cb 1)
      (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'ok-voice-cb)
      ;; while 状態変化を認識するまで
      (setq *yes-flag* nil)
      (until *yes-flag*
             (ros::spin-once)
             (ros::sleep)
             )
      (ros::unsubscribe "/adjusted_clip_state_recognizer/state")
      (ros::unsubscribe "/speech_to_text")
      )
    )
   ))


(defun pour-object-to-pan (&key (from-object "ボウル1") (to-object "フライパン") (arm :rarm) (spot-name "stove"))
  (let ((pre-set-avs (list))
        cook-from-now-file-name
        )
    (cond
     ((and (string= from-object "ボウル1") (string= to-object "フライパン") (string= spot-name "stove") (equal arm :rarm))
      (setq pre-set-avs (list #f(-61.1287 29.236 -64.3672 -121.542 -107.621 -114.592 103.041) #f(-45.3343 3.47451 -56.4107 -109.672 -99.5375 -114.592 104.776)))
      ;; (setq cook-from-now-file-name "av-files/cook-from-now-pour-bowl1-to-pan-20231212-data.l")
      (setq cook-from-now-file-name "../../av-files/cook-from-now-pour-bowl1-to-pan-20240221-data.l")
      )
     ((and (string= from-object "ボウル0") (string= to-object "フライパン") (string= spot-name "stove") (equal arm :rarm))
      (setq pre-set-avs (list #f(-28.2146 0.07681 -56.1994 -95.3798 -127.421 -97.0024 137.794)
                              #f(-21.4171 10.8467 -51.9823 -76.3682 -134.766 -103.742 117.398)))
      ;; (setq cook-from-now-file-name "av-files/cook-from-now-pour-bowl0-to-pan-20231212-data.l")
      (setq cook-from-now-file-name "../../av-files/cook-from-now-pour-bowl0-to-pan-20240221-data.l")
      )
     ((and (string= from-object "あぶら") (string= to-object "フライパン") (string= spot-name "stove")) ;; larmだったが結局両腕使うので
      (setq pre-set-avs (list #f(52.4453 35.9984 40.0064 -117.485 -211.029 -72.009 -15.0076)))

      ;; 物体把持初期姿勢
      (send *pr2* arm :angle-vector (elt (reverse pre-set-avs) 0))
      (send *ri* :angle-vector (send *pr2* :angle-vector))
      (send *ri* :wait-interpolation)

      (load-cook-from-now-file :file_name "av-files/cook-from-now-pour-oil-to-pan-larm-20231212-data.l" :larm t)
      (cook-from-now-replay-once :larm t :initial-av nil)

      (send *ri* :stop-grasp :rarm :wait t)
      (load-cook-from-now-file :file_name "av-files/cook-from-now-pour-oil-to-pan-rarm-20231212-data.l" :larm t)
      (cook-from-now-replay-once :larm nil :initial-av nil)

      (send *ri* :start-grasp :rarm :wait t)

      (send *ri* :start-grasp :larm :wait t :gain 1.0)
      (unix:sleep 2)
      (send *ri* :stop-grasp :larm :wait t)
      (unix:sleep 2)
      (send *ri* :start-grasp :larm :wait t)

      (send *ri* :stop-grasp :rarm :wait t)

      (load-cook-from-now-file :file_name "av-files/cook-from-now-pour-oil-to-pan-rarm-20231212-data.l" :larm t)
      (cook-from-now-replay-once :larm nil :initial-av nil :reverse t)

      (load-cook-from-now-file :file_name "av-files/cook-from-now-pour-oil-to-pan-larm-20231212-data.l" :larm t)
      (cook-from-now-replay-once :larm t :initial-av nil :reverse t)

      (reset-manip-pose :arm :rarm)
      (return-from pour-object-to-pan nil)
      )
     ((and (string= from-object "ブロッコリー") (string= to-object "鍋") (string= spot-name "stove") (equal arm :larm))
      (send *pr2* :larm :angle-vector #f(27.5715 22.0148 51.6599 -44.6906 40.8698 -83.3365 -15.6292))
      (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
      (send *ri* :wait-interpolation)

      (send *pr2* :larm :angle-vector #f(22.3415 18.6413 51.3751 -30.3821 39.7562 -83.6954 -23.382))
      (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
      (send *ri* :wait-interpolation)

      (send *ri* :stop-grasp :larm :wait t)

      (return-from pour-object-to-pan nil)
      )
     ((and (string= from-object "pot") (string= to-object "frying-pan") (string= spot-name "stove") (equal arm :larm)) ;; for broccoli
      ;; (setq pre-set-avs (list #f(-61.1287 29.236 -64.3672 -121.542 -107.621 -114.592 103.041) #f(-45.3343 3.47451 -56.4107 -109.672 -99.5375 -114.592 104.776)))
      ;; (setq cook-from-now-file-name "av-files/cook-from-now-pour-bowl1-to-pan-20240221-data.l")
      ;; (load-cook-file :file_name "av-files/cook_larm-data_transfer-broccoli_20231119_01.l" :larm t)
      (send *ri* :start-grasp :larm :wait t :gain 100)

      (load-cook-file :file_name "../../av-files/cook_larm-data_transfer-broccoli_20231119_01.l" :larm t)
      ;; (cook-replay-once :larm t)
      (cook-from-now-replay-once :larm t :initial-av nil)
      (return-from pour-object-to-pan nil)
      )
     (t
      (format t "from-object ~A, to-object ~A, spot-name ~A, arm ~A is not defined !!!~%" from-object to-object spot-name arm)
      (return-from pour-object-to-pan nil)
      )
     )

    ;; 物体把持初期姿勢
    (send *pr2* arm :angle-vector (elt (reverse pre-set-avs) 0))
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation)

    (cond
     ((equal arm :rarm)
      (load-cook-from-now-file :file_name cook-from-now-file-name :larm nil)
      (cook-from-now-replay-once :larm nil :initial-av t)
      )
     ((equal arm :larm)
      (load-cook-from-now-file :file_name cook-from-now-file-name :larm t)
      (cook-from-now-replay-once :larm t :initial-av t)
      )
     )
    )
  )

(defun place-objects-on-table (&key (object-name "ボウル1") (arm :rarm) (set-flag nil) (grasp-flag nil) (only-grasp nil) (spot-name "stove"))
  (let ((pre-set-avs (list))
        (pre-set-val (float-vector 0 0 0))
        (set-target-coords (make-coords))
        ik-target-adj
        )
    (cond
     ((and (string= object-name "水カップ") (string= spot-name "stove") (equal arm :larm))
      (setq pre-set-avs (list #f(70.9521 29.615 43.5896 -114.914 61.752 -62.5943 -235.149)
                              #f(32.6227 35.6785 32.7297 -121.542 78.2412 -69.168 -246.245)
                              ))
      (setq pre-set-val #f(-100 100 100))
      (setq set-target-coords (make-coords :pos #f(657.002 322.99 908.764) :rpy #f(-0.909 0.158 -1.428)))
      )
     ((and (string= object-name "ボウル1") (string= spot-name "stove") (equal arm :rarm))
      ;; (setq pre-set-avs (list #f(-61.1287 29.236 -64.3672 -121.542 -107.621 -114.592 103.041) #f(-45.3343 3.47451 -56.4107 -109.672 -99.5375 -114.592 104.776)))
      ;; (setq pre-set-val #f(-50 0 50))
      ;; ;; (setq set-target-coords (make-coords :pos #f(600.991 -365.044 878.981) :rpy #f(-0.496 1.352 -2.114)))
      ;; (setq set-target-coords (make-coords :pos #f(584.41 -365.828 878.981) :rpy #f(-0.491 1.352 -2.114)))
      (setq pre-set-avs (list #f(-61.1287 29.236 -64.3672 -121.542 -107.621 -114.592 103.041)
                              #f(-17.2701 6.61532 -15.8472 -46.5569 -153.821 -114.592 99.202)
                              ))
      (setq pre-set-val #f(-50 0 50))
      ;; (setq set-target-coords (make-coords :pos #f(600.991 -365.044 878.981) :rpy #f(-0.496 1.352 -2.114)))
      (setq set-target-coords (make-coords :pos #f(690.181 -527.149 870.629) :rpy #f(0.478 1.218 -0.929)))
      )
     ((and (string= object-name "ボウル1") (string= spot-name "kitchen") (equal arm :rarm))
      (setq pre-set-avs (list #f(-61.1287 29.236 -64.3672 -121.542 -107.621 -114.592 103.041) #f(-45.3343 3.47451 -56.4107 -109.672 -99.5375 -114.592 104.776)))
      (setq pre-set-val #f(-50 0 50))
      (setq set-target-coords (make-coords :pos #f(617.685 -12.392 881.276) :rpy #f(-0.649 1.31 -2.337)))
      )
     ((and (string= object-name "ボウル0") (string= spot-name "stove") (equal arm :rarm))
      ;; (setq pre-set-avs (list #f(-28.2146 0.07681 -56.1994 -95.3798 -127.421 -97.0024 137.794)
      ;;                         #f(-21.4171 10.8467 -51.9823 -76.3682 -134.766 -103.742 117.398)))
      ;; (setq pre-set-val #f(0 0 100))
      ;; (setq set-target-coords (make-coords :pos #f(760.846 -230.582 846.976) :rpy #f(-0.353 1.158 -1.828)))
      ;; (setq set-target-coords (make-coords :pos #f(743.532 -230.499 846.976) :rpy #f(-0.348 1.158 -1.828)))
      (setq pre-set-avs (list #f(-28.2146 0.07681 -56.1994 -95.3798 -127.421 -97.0024 137.794)
                              #f(-27.4926 -3.15125 -53.829 -47.5523 -117.203 -99.9358 106.977)))
      (setq pre-set-val #f(-100 0 100))
      (setq set-target-coords (make-coords :pos #f(682.232 -349.307 852.929) :rpy #f(0.115 1.25 -1.37)))
      )
     ((and (string= object-name "あぶら") (string= spot-name "stove") (equal arm :larm)) ;; larm
      (setq pre-set-avs (list #f(52.4453 35.9984 40.0064 -117.485 -211.029 -72.009 -15.0076)))
      (setq pre-set-val #f(0 0 100))
      ;; (setq set-target-coords (make-coords :pos #f(737.741 557.918 924.705) :rpy #f(0.093 0.064 -3.107)))
      (setq set-target-coords (make-coords :pos #f(716.145 557.863 924.705) :rpy #f(0.098 0.064 -3.107)))
      )
     ((and (string= object-name "ヘラ") (string= spot-name "stove") (equal arm :rarm))
      ;; (setq pre-set-avs (list #f(-23.3076 50.4461 -21.9938 -121.268 -173.134 -64.7071 191.807)))
      ;; (setq pre-set-val #f(0 0 100))
      ;; ;; (setq set-target-coords (make-coords :pos #f(617.101 -150.106 835.171) :rpy #f(0.013 0.078 0.012)))
      ;; (setq set-target-coords (make-coords :pos #f(599.352 -150.805 835.171) :rpy #f(0.018 0.078 0.012)))
      (setq pre-set-avs (list #f(-23.3076 50.4461 -21.9938 -121.268 -173.134 -64.7071 191.807)
                              #f(-28.4758 35.8375 -5.72244 -94.6913 -151.172 -58.3521 170.369)))
      (setq pre-set-val #f(-50 0 100))
      ;; (setq set-target-coords (make-coords :pos #f(717.808 -678.451 846.167) :rpy #f(0.028 -0.041 -0.026)))
      (setq set-target-coords (make-coords :pos #f(717.808 -578.451 846.167) :rpy #f(0.028 -0.041 -0.026)))
      )
     ((and (string= object-name "牛乳") (string= spot-name "kitchen") (equal arm :rarm))
      (setq pre-set-avs (list #f(-34.9504 28.0727 -59.2681 -115.345 -185.596 -76.2334 232.008)))
      (setq pre-set-val #f(-50 0 50))
      (setq set-target-coords (make-coords :pos #f(631.733 -223.286 848.024) :rpy #f(-0.003 0.101 0.016)))
      )
     ((and (string= object-name "泡立て器") (string= spot-name "kitchen") (equal arm :rarm))
      (setq pre-set-avs (list #f(-34.9504 28.0727 -59.2681 -115.345 -185.596 -76.2334 232.008) #f(-13.7455 24.0885 -33.0006 -88.4288 -183.832 -57.8883 212.053)))
      (setq pre-set-val #f(-50 0 50))
      (setq set-target-coords (make-coords :pos #f(917.983 -199.795 1106.18) :rpy #f(-0.097 0.043 -0.007)))
      )
     ((and (string= object-name "水道") (string= spot-name "sink") (equal arm :rarm))
      (setq pre-set-avs (list #f(-69.5413 40.539 -71.9287 -121.542 -117.442 -38.3354 119.76)
                              #f(-23.4739 26.3763 -32.7985 -108.469 -160.605 -82.8258 124.035)))
      (setq pre-set-val #f(-100 -100 100))
      (setq set-target-coords (make-coords :pos #f(850 -28.163 1030) :rpy #f(0.608 0.062 -1.398))) ;; 909.733 -28.163 997.723
      )
     ((and (string= object-name "フライパン") (string= spot-name "stove") (equal arm :larm))
      (setq pre-set-avs (list #f(26.9083 69.9996 85.5955 -101.551 -80.4156 -66.7142 -94.6102)
                              ))
      (setq pre-set-val #f(-100 0 -100))
      (setq set-target-coords (make-coords :pos #f(657.029 -101.483 899.763) :rpy #f(0.056 -0.405 3.04)))
      )
     ((and (string= object-name "鍋") (string= spot-name "stove") (equal arm :larm))
      (setq pre-set-avs (list #f(26.9083 69.9996 85.5955 -101.551 -80.4156 -66.7142 -94.6102)
                              ))
      (setq pre-set-val #f(-100 0 -100))
      (setq set-target-coords (make-coords :pos #f(699.076 178.059 947.711) :rpy #f(0.012 -0.62 3.14)))
      )
     ((and (string= object-name "pot") (string= spot-name "stove") (equal arm :larm)) ;; larm ;; it is for broccoli in pot
      (setq pre-set-avs (list #f(69.679 -8.03115 70.5921 -121.326 -3.71055 -32.8935 -5.88907)
                              #f(45.532 15.6265 43.8688 -52.2305 36.9455 -101.153 -32.4685)
                              ))
      (setq pre-set-val #f(-50 50 50))
      (setq set-target-coords (inv-offset-cds (make-coords :pos #f(730.575 185.784 978.508) :rpy #f(-1.478 -0.045 1.181)) *stove-offset-cds*))
      )
     ((and (string= object-name "ブロッコリー") (string= spot-name "stove") (equal arm :larm)) ;; larm
      (setq pre-set-avs (list #f(69.679 -8.03115 70.5921 -121.326 -3.71055 -32.8935 -5.88907)
                              #f(45.532 15.6265 43.8688 -52.2305 36.9455 -101.153 -32.4685)
                              ))
      (setq pre-set-val #f(-50 50 50))
      ;; (setq set-target-coords (make-coords :pos #f(615.967 367.301 914.519) :rpy #f(-1.371 0.162 1.508)))
      ;; (setq set-target-coords (make-coords :pos #f(660 367.301 914.519) :rpy #f(-1.371 0.162 1.508)))
      (setq set-target-coords (make-coords :pos #f(700 367.301 914.519) :rpy #f(-1.371 0.162 1.508)))
      )
     (t
      (format t "object-name ~A, spot-name ~A, arm ~A is not defined !!!~%" object-name spot-name arm)
      (return-from place-objects-on-table nil)
      )
     )

    (if grasp-flag
        (progn
          (dolist (pre-set-av pre-set-avs)
            (send *pr2* arm :angle-vector pre-set-av)
            (send *ri* :angle-vector (send *pr2* :angle-vector))
            (send *ri* :wait-interpolation)
            ))
      (progn
        (send *pr2* arm :angle-vector (elt (reverse pre-set-avs) 0))
        (send *ri* :angle-vector (send *pr2* :angle-vector))
        (send *ri* :wait-interpolation)
        )
      )

    (setq set-coords (send set-target-coords :copy-worldcoords))

    (if set-flag
        (progn
          ;; 物体を握らせて貰う
          (send *ri* :stop-grasp arm :wait t)
          (send *ri* :speak-jp (format nil "~AをセットしてOKと言ってください" object-name))
          (ok-wait)
          (send *ri* :start-grasp arm :wait t)
          ))
    (if grasp-flag
        (progn
          ;; 物体を握るために手を開く
          (send *ri* :stop-grasp arm :wait t)
          ))

    (send set-coords :translate pre-set-val :world)
    (setq ik-target-adj (adjust-cds-with-spot set-coords spot-name))
    (send *pr2* arm :inverse-kinematics
          (send ik-target-adj :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation)

    (send set-coords :translate (scale -1 pre-set-val) :world)
    (setq ik-target-adj (adjust-cds-with-spot set-coords spot-name))
    (send *pr2* arm :inverse-kinematics
          (send ik-target-adj :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation)

    (if grasp-flag
        (progn
          ;; 物体を握る
          (send *ri* :start-grasp arm :wait t)
          )
      (send *ri* :stop-grasp arm :wait t) ;; 物体を置く
      )

    (when (not only-grasp)

      (send set-coords :translate pre-set-val :world)
      (setq ik-target-adj (adjust-cds-with-spot set-coords spot-name))
      (send *pr2* arm :inverse-kinematics
            (send ik-target-adj :copy-worldcoords)
            :rotation-axis t
            :debug-view nil)
      (send *ri* :angle-vector (send *pr2* :angle-vector))
      (send *ri* :wait-interpolation)

      (if grasp-flag
          (progn
            (send *pr2* arm :angle-vector (elt (reverse pre-set-avs) 0))
            (send *ri* :angle-vector (send *pr2* :angle-vector))
            (send *ri* :wait-interpolation)
            )
        (progn
          (dolist (pre-set-av (reverse pre-set-avs))
            (send *pr2* arm :angle-vector pre-set-av)
            (send *ri* :angle-vector (send *pr2* :angle-vector))
            (send *ri* :wait-interpolation)
            )
          (reset-manip-pose :arm arm))
        )
      )
    ))

(defun hold-pot-on-stove (&key (arm :larm) (object-name "鍋") (grasp-flag t) (spot-name "stove"))
  (if (equal arm :larm)
      (progn
        (reset-manip-pose :arm :larm :time 2000)

        (cond
         ((and (or (string= object-name "鍋") (string= object-name "フライパン")) (string= spot-name "stove"))
          (send *pr2* :larm :angle-vector #f(26.9083 69.9996 85.5955 -101.551 -80.4156 -66.7142 -94.6102))
          )
         ((and (string= object-name "ボウル1") (string= spot-name "kitchen"))
          (send *pr2* :larm :angle-vector #f(21.2745 28.3257 29.2936 -100.141 82.9343 -86.2251 -68.1853))
          )
         (t
          (format t "object-name ~A, spot-name ~A is not defined !!!~%" object-name spot-name)
          (return-from hold-pot-on-stove nil)
          )
         )
        (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
        (send *ri* :wait-interpolation)

        (send *ri* :stop-grasp :larm :wait t)

        (let (ik-target
              ik-target-adj)
          (cond
           ((and (string= object-name "鍋") (string= spot-name "stove"))
            ;; (send *pr2* :larm :angle-vector #f(15.0755 56.5882 65.6859 -96.6074 -98.943 -62.4489 -88.545))
            ;; (setq ik-target (make-coords :pos #f(557.801 41.391 945.716) :rpy #f(0.185 -0.498 3.038)))
            (setq ik-target (make-coords :pos #f(699.076 178.059 947.711) :rpy #f(0.012 -0.62 3.14)))
            (setq ik-target-adj (adjust-cds-with-spot ik-target "stove"))
            )
           ((and (string= object-name "フライパン") (string= spot-name "stove"))
            ;; (send *pr2* :larm :angle-vector #f(18.8234 64.1057 72.9717 -100.133 -92.8479 -64.159 -87.0742))
            ;; (setq ik-target (make-coords :pos #f(502.073 32.755 904.802) :rpy #f(0.159 -0.479 3.088)))
            (setq ik-target (make-coords :pos #f(657.029 -101.483 899.763) :rpy #f(0.056 -0.405 3.04)))
            (setq ik-target-adj (adjust-cds-with-spot ik-target "stove"))
            )
           ((and (string= object-name "ボウル1") (string= spot-name "kitchen"))
            (setq ik-target (make-coords :pos #f(709.04 108.836 886.591) :rpy #f(-1.331 1.235 1.725)))
            (setq ik-target-adj (adjust-cds-with-spot ik-target "kitchen"))
            )
           (t
            (format t "object-name ~A, spot-name ~A is not defined !!!~%" object-name spot-name)
            (return-from hold-pot-on-stove nil)
            )
           )
          (send *pr2* :larm :inverse-kinematics
                (send ik-target-adj :copy-worldcoords)
                :rotation-axis t
                :debug-view nil)
          (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
          (send *ri* :wait-interpolation)

          (if grasp-flag
              (send *ri* :start-grasp :larm :wait t)
            )
          )
        )
    )
  )

(defun release-pot-on-stove (&key (arm :larm))
  (if (equal arm :larm)
      (progn
        (send *ri* :stop-grasp :larm :wait t)

        (send *pr2* :larm :move-end-pos #f(-100 0 0))
        (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
        (send *ri* :wait-interpolation)

        (send *pr2* :larm :angle-vector #f(26.9083 69.9996 85.5955 -101.551 -80.4156 -66.7142 -94.6102))
        (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
        (send *ri* :wait-interpolation)

        (reset-manip-pose :arm :larm :time 2000)
        )
    )
  )

(defun set-pot-on-stove (&key (arm :larm) (object-name "鍋"))
  (hold-pot-on-stove :arm arm :object-name object-name)

  (send *ri* :speak-jp (format nil "~AをセットしてOKと言ってください" object-name))
  (ok-wait)

  (release-pot-on-stove :arm arm)
  )

(defun set-pot-for-broccoli (&key (arm :larm) (object-name "鍋"))
  (hold broccoli arm2 stove)
  (pour broccoli pot arm2 stove)
  (place broccoli arm2 stove)
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


(defun start-ih (&key (left nil) (max-power nil) (only-rotate nil) (with-rec t))
  (if only-rotate
      (progn
        (reset-manip-pose :arm :rarm :time 2000)

        ;; (send *pr2* :rarm :angle-vector #f(-37.49 74.2613 -98.4166 -92.2371 105.499 -61.216 -179.863)) ;; for old stove
        (send *pr2* :rarm :angle-vector #f(-37.9792 67.891 -75.6121 -80.9552 114.675 -44.3419 -2.95313))
        (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
        (send *ri* :wait-interpolation)
        )

    (stop-ih :left left :only-stop nil :with-rec with-rec)
    )

  ;; grasp knob
  (send *ri* :move-gripper :rarm 0.08)

  (let (ik-target
        ik-target-adj
        ih-target
        diff-ih
        diffcds)
    (if left
        (progn
          (setq ih-target (send *ih-left-target* :copy-worldcoords))
          (setq diff-ih (send *diff-left-ih* :copy-worldcoords))
          )
      (progn
        (setq ih-target (send *ih-right-target* :copy-worldcoords))
        (setq diff-ih (send *diff-right-ih* :copy-worldcoords))
        )
      )

    (if with-rec
        (progn
          (setq ih-rec-flag nil)
          (until ih-rec-flag
                 (if only-rotate
                     (setq *ih-cds* (k4a-check-detection "/point_pose_ih/ObjectDetection"))
                   )
                 (setq ik-target (send (send *ih-cds* :copy-worldcoords) :transform diff-ih))
                 (setq diffcds (send (send ih-target :inverse-transformation)
                                     :transform (send ik-target :worldcoords) :world))
                 (format t "diffcds ~A ~%" diffcds)
                 (format t "norm diffcds pos ~A ~%" (norm (send diffcds :pos)))
                 (if (< (norm (send diffcds :pos)) *ih-rec-norm-thre*)
                     (setq ih-rec-flag t)
                   )
                 )
          (format t "ik-target is ~A ~%" ik-target)
          (setq ik-target-adj (send ik-target :copy-worldcoords))
          )
      (progn
        (setq ik-target (send ih-target :copy-worldcoords))
        (setq ik-target-adj (adjust-cds-with-spot ik-target "stove"))
        ))
    (send *pr2* :rarm :inverse-kinematics
          ik-target-adj
          :rotation-axis t
          :revert-if-fail nil)
    )
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)


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
      (send *pr2* :rarm :angle-vector #f(-14.727 68.7101 -60.2136 -76.3185 109.312 -48.51 -7.17108)) ;; left TODO
    (send *pr2* :rarm :angle-vector #f(-37.9792 67.891 -75.6121 -80.9552 114.675 -44.3419 -2.95313)))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (reset-manip-pose :arm :rarm :time 2000)
  )

(defun stop-ih (&key (left nil) (only-stop t) (with-rec t))
  (send *pr2* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *pr2* :head-neck-p :joint-angle *initial-head-neck-p*)

  (reset-manip-pose :arm :rarm :time 2000)

  (if left
      (send *pr2* :rarm :angle-vector #f(-14.727 68.7101 -60.2136 -76.3185 109.312 -48.51 -7.17108)) ;; left TODO
    (send *pr2* :rarm :angle-vector #f(-37.9792 67.891 -75.6121 -80.9552 114.675 -44.3419 -2.95313))) ;; #f(-37.49 74.2613 -98.4166 -92.2371 105.499 -61.216 -179.863) for old
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (send *ri* :start-grasp :rarm :wait t)

  (let (ik-target
        ik-target-adj
        ih-target
        diff-ih
        diffcds)
    (if left
        (progn
          (setq ih-target (send *ih-left-target* :copy-worldcoords))
          (setq diff-ih (send *diff-left-ih* :copy-worldcoords))
          )
      (progn
        (setq ih-target (send *ih-right-target* :copy-worldcoords))
        (setq diff-ih (send *diff-right-ih* :copy-worldcoords))
        )
      )

    (if with-rec
        (progn
          (setq ih-rec-flag nil)
          (until ih-rec-flag
                 (setq *ih-cds* (k4a-check-detection "/point_pose_ih/ObjectDetection"))
                 (setq ik-target (send (send *ih-cds* :copy-worldcoords) :transform diff-ih))
                 (setq diffcds (send (send ih-target :inverse-transformation)
                                     :transform (send ik-target :worldcoords) :world))
                 (format t "diffcds ~A ~%" diffcds)
                 (format t "norm diffcds pos ~A ~%" (norm (send diffcds :pos)))
                 (if (< (norm (send diffcds :pos)) *ih-rec-norm-thre*)
                     (setq ih-rec-flag t)
                     )
                 )
          (format t "ik-target is ~A ~%" ik-target)
          ;; (setq ik-target-adj (send ik-target :copy-worldcoords))
          )
      (progn
        (setq ik-target (send ih-target :copy-worldcoords))
        (setq ik-target-adj (adjust-cds-with-spot ik-target "stove"))
      ))
    (send *pr2* :rarm :inverse-kinematics
          ik-target-adj
          :rotation-axis t
          :revert-if-fail nil)
    )
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)


  (send *pr2* :rarm :move-end-pos #f(10 0 0))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (if left
      (send *pr2* :rarm :angle-vector #f(-14.727 68.7101 -60.2136 -76.3185 109.312 -48.51 -7.17108)) ;; left TODO
    (send *pr2* :rarm :angle-vector #f(-37.9792 67.891 -75.6121 -80.9552 114.675 -44.3419 -2.95313))) ;; #f(-37.49 74.2613 -98.4166 -92.2371 105.499 -61.216 -179.863) for old
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (when only-stop
    (reset-manip-pose :arm :rarm :time 2000)
    )
  )

