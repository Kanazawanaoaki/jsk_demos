(require :pr2-interface "package://pr2eus/pr2-interface.l")
(require :pr2-cook-tmp "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_tmp.l")

(setq *initial-head-neck-y* 0.0)
(setq *initial-head-neck-p* 50.0)

(setq *yes-flag* nil)
(setq *speak-jp* t)


(defun stir-fry-cook-stove (&key (object-name "egg-mixture") (vessel "フライパン") (tool "ヘラ") (state "soft-scrambled-egg") (spot "stove"))
  (let ((pre-set-avs (list))
        cook-from-now-file-name
        now-msg
        model_file
        target_state
        )
    (setq pre-set-avs (list #f(-23.3076 50.4461 -21.9938 -121.268 -173.134 -64.7071 191.807)))
    (setq cook-from-now-file-name "av-files/cook-from-now-stirfry-with-spatula-and-pan-rarm-20231212-data.l")
    (setq model_file "2023-12-12_cook_sunny_datas_model_2023_1212_2131.pkl") ;; TODO
    (setq target_state "soft-scrambled-egg")

    ;; フライパンを抑える
    (hold-pot-on-stove :arm :larm :object-name vessel :grasp-flag t)

    ;; 物体把持初期姿勢
    (send *pr2* :rarm :angle-vector (elt (reverse pre-set-avs) 0))
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation)
    (send *ri* :start-grasp :rarm :wait t :gain 1.0)

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

    ;; フライパンから手を離す
    (release-pot-on-stove :arm :larm)
    )
  )


(defun wait-cook-stove (&key (object-name "egg") (state "heat-through") (vessel "フライパン"))
  (cond
   ;; state が時間指定ならその時間待つ
   ((string= state "thirty-seconds") ;; TODO ここは賢く処理をしたい
    (unix:sleep 30)
    (return-from wait-cook-stove t)
    )
   ;; それ以外なら状態変化をみる．
   (t
    (let (model_file
          target_state)
      (cond
       ((and
         (string= state "heat-through")
         (string= object-name "egg")
         )
        ;; (setq model_file "cooked_sunny_content_model_2023_1010_1904.pkl") ;; TODO
        (setq model_file "2023-12-12_cook_sunny_datas_model_2023_1212_2131.pkl")
        (setq target_state "egg is heat-through")
        )
       (t
        (format t "object-name ~A, state ~A, vessel ~A is not defined !!!~%" object-name state vessel)
        (return-from wait-cook-stove nil)
        )
       )

      ;; 鍋やフライパンの領域を注視
      (described_gazing_area_detector-command :query-list (list "the content of the pot" "the content of the frying pan"))
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
      (setq cook-from-now-file-name "av-files/cook-from-now-pour-bowl1-to-pan-20231212-data.l")
      )
     ((and (string= from-object "ボウル0") (string= to-object "フライパン") (string= spot-name "stove") (equal arm :rarm))
      (setq pre-set-avs (list #f(-28.2146 0.07681 -56.1994 -95.3798 -127.421 -97.0024 137.794)
                              #f(-21.4171 10.8467 -51.9823 -76.3682 -134.766 -103.742 117.398)))
      (setq cook-from-now-file-name "av-files/cook-from-now-pour-bowl0-to-pan-20231212-data.l")
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

(defun place-objects-on-table (&key (object-name "ボウル1") (arm :rarm) (set-flag nil) (grasp-flag nil) (spot-name "stove"))
  (let ((pre-set-avs (list))
        (pre-set-val (float-vector 0 0 0))
        (set-target-coords (make-coords))
        ik-target-adj
        )
    (cond
     ((and (string= object-name "ボウル1") (string= spot-name "stove") (equal arm :rarm))
      (setq pre-set-avs (list #f(-61.1287 29.236 -64.3672 -121.542 -107.621 -114.592 103.041) #f(-45.3343 3.47451 -56.4107 -109.672 -99.5375 -114.592 104.776)))
      (setq pre-set-val #f(-50 0 50))
      ;; (setq set-target-coords (make-coords :pos #f(600.991 -365.044 878.981) :rpy #f(-0.496 1.352 -2.114)))
      (setq set-target-coords (make-coords :pos #f(584.41 -365.828 878.981) :rpy #f(-0.491 1.352 -2.114)))
      )
     ((and (string= object-name "ボウル0") (string= spot-name "stove") (equal arm :rarm))
      (setq pre-set-avs (list #f(-28.2146 0.07681 -56.1994 -95.3798 -127.421 -97.0024 137.794)
                              #f(-21.4171 10.8467 -51.9823 -76.3682 -134.766 -103.742 117.398)))
      (setq pre-set-val #f(0 0 100))
      ;; (setq set-target-coords (make-coords :pos #f(760.846 -230.582 846.976) :rpy #f(-0.353 1.158 -1.828)))
      (setq set-target-coords (make-coords :pos #f(743.532 -230.499 846.976) :rpy #f(-0.348 1.158 -1.828)))
      )
     ((and (string= object-name "あぶら") (string= spot-name "stove") (equal arm :larm)) ;; larm
      (setq pre-set-avs (list #f(52.4453 35.9984 40.0064 -117.485 -211.029 -72.009 -15.0076)))
      (setq pre-set-val #f(0 0 100))
      ;; (setq set-target-coords (make-coords :pos #f(737.741 557.918 924.705) :rpy #f(0.093 0.064 -3.107)))
      (setq set-target-coords (make-coords :pos #f(716.145 557.863 924.705) :rpy #f(0.098 0.064 -3.107)))
      )
     ((and (string= object-name "ヘラ") (string= spot-name "stove") (equal arm :rarm))
      (setq pre-set-avs (list #f(-23.3076 50.4461 -21.9938 -121.268 -173.134 -64.7071 191.807)))
      (setq pre-set-val #f(0 0 100))
      ;; (setq set-target-coords (make-coords :pos #f(617.101 -150.106 835.171) :rpy #f(0.013 0.078 0.012)))
      (setq set-target-coords (make-coords :pos #f(599.352 -150.805 835.171) :rpy #f(0.018 0.078 0.012)))
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
    ))

(defun hold-pot-on-stove (&key (arm :larm) (object-name "鍋") (grasp-flag t))
  (if (equal arm :larm)
      (progn
        (reset-manip-pose :arm :larm :time 2000)

        (send *pr2* :larm :angle-vector #f(26.9083 69.9996 85.5955 -101.551 -80.4156 -66.7142 -94.6102))
        (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
        (send *ri* :wait-interpolation)

        (send *ri* :stop-grasp :larm :wait t)

        (let (ik-target
              ik-target-adj)
          (cond
           ((string= object-name "鍋")
            ;; (send *pr2* :larm :angle-vector #f(15.0755 56.5882 65.6859 -96.6074 -98.943 -62.4489 -88.545))
            (setq ik-target (make-coords :pos #f(557.801 41.391 945.716) :rpy #f(0.185 -0.498 3.038)))
            (setq ik-target-adj (adjust-cds-with-spot ik-target "stove"))
            )
           ((string= object-name "フライパン")
            ;; (send *pr2* :larm :angle-vector #f(18.8234 64.1057 72.9717 -100.133 -92.8479 -64.159 -87.0742))
            (setq ik-target (make-coords :pos #f(502.073 32.755 904.802) :rpy #f(0.159 -0.479 3.088)))
            (setq ik-target-adj (adjust-cds-with-spot ik-target "stove"))
            )
           (t
            (format t "object-name ~A is not defined !!!~%" object-name)
            (return-from set-pot-on-stove nil)
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


(defun start-ih (&key (left nil) (max-power nil) (only-rotate nil))
  (if only-rotate
      (progn
        (reset-manip-pose :arm :rarm :time 2000)

        (send *pr2* :rarm :angle-vector #f(-37.49 74.2613 -98.4166 -92.2371 105.499 -61.216 -179.863))
        (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
        (send *ri* :wait-interpolation)
        )

    (stop-ih :left left :only-stop nil)
    )

  ;; grasp knob
  (send *ri* :move-gripper :rarm 0.08)

  (let (ik-target
        ik-target-adj)
    ;; (setq ik-target (make-coords :pos #f(540 -33.562 705) :rpy #f(0.0 0.0 -1.5708))) ;; right ;; (float-vector 636 -183 698)
    (setq ik-target (make-coords :pos #f(521.619 -34.682 705.0) :rpy #f(0.0 0.0 -1.5708)))
    (send ik-target :rotate (deg2rad 90) :x)
    (setq ik-target-adj (adjust-cds-with-spot ik-target "stove"))
    ;; (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    (send *pr2* :rarm :inverse-kinematics ;; left TODO
          (send ik-target-adj :copy-worldcoords)
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
      (send *pr2* :rarm :angle-vector #f(-14.727 68.7101 -60.2136 -76.3185 109.312 -48.51 -7.17108)) ;; left TODO
    (send *pr2* :rarm :angle-vector #f(-37.49 74.2613 -98.4166 -92.2371 105.499 -61.216 -179.863)))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (reset-manip-pose :arm :rarm :time 2000)
  )

(defun stop-ih (&key (left nil) (only-stop t))
  (send *pr2* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *pr2* :head-neck-p :joint-angle *initial-head-neck-p*)

  (reset-manip-pose :arm :rarm :time 2000)

  (if left
      (send *pr2* :rarm :angle-vector #f(-14.727 68.7101 -60.2136 -76.3185 109.312 -48.51 -7.17108)) ;; left TODO
    (send *pr2* :rarm :angle-vector #f(-37.49 74.2613 -98.4166 -92.2371 105.499 -61.216 -179.863)))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (send *ri* :start-grasp :rarm :wait t)

  (let (ik-target)
    (if left
        (progn
          (send *pr2* :rarm :angle-vector #f(-10.3805 65.2155 -51.4302 -73.631 122.477 -46.0296 -19.6429)) ;; left TODO
          )
      (progn
        ;; (send *pr2* :rarm :angle-vector #f(-32.9823 60.3212 -73.0221 -74.5233 120.244 -39.7369 -5.03581)) ;; #f(-31.9892 63.9795 -66.939 -75.7959 118.513 -36.3796 -8.94601))
        ;; (setq ik-target (make-coords :pos #f(527.887 -33.562 705) :rpy #f(0.0 0.0 -1.5708)))

        ;; (setq ik-target (make-coords :pos #f(537.887 -33.562 705) :rpy #f(0.0 0.0 -1.5708)))
        (setq ik-target (make-coords :pos #f(519.506 -34.693 705.0) :rpy #f(0.0 0.0 -1.5708)))
        (setq ik-target-adj (adjust-cds-with-spot ik-target "stove"))
        (send *pr2* :rarm :inverse-kinematics
              ik-target-adj
              :rotation-axis t
              :revert-if-fail nil)
        ))
    )
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)


  (send *pr2* :rarm :move-end-pos #f(10 0 0))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (if left
      (send *pr2* :rarm :angle-vector #f(-14.727 68.7101 -60.2136 -76.3185 109.312 -48.51 -7.17108)) ;; left TODO
    (send *pr2* :rarm :angle-vector #f(-37.49 74.2613 -98.4166 -92.2371 105.499 -61.216 -179.863)))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (when only-stop
    (reset-manip-pose :arm :rarm :time 2000)
    )
  )

