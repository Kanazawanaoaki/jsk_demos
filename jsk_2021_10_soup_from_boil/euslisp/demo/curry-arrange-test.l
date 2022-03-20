(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")
(warn "please run (curry-a-0) ~%")

;; add for voice recognition
(ros::roseus "curry_rec_test" :anonymous t)
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

(defun curry-dialogue ()
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

(defun curry-ok-wait ()
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

(defun curry-a-0 () ;;最初に準備をする
  (send *ri* :speak-jp "準備を開始します")
  
  ;; サトウのごはんを用意する
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/arrangement-codes.l")
  (update-pos)
  (now-set-sato-rarm-with-dialogue)
  
  ;; おたまとヘラを用意する
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/arrangement-codes.l")
  (update-pos)
  (now-set-tools-a-with-dialogue)
  
  (send *ri* :speak-jp "準備を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (curry-a-1) ~%")
  )

(defun curry-a-1 () ;;ごはんを温める
  (send *ri* :speak-jp "ごはんを温める調理を開始します")
  
  ;; サトウのごはんを握る
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/arrangement-codes.l")
  (update-pos)
  (now-grasp-sato-rarm) ;; TODO
  
  ;; 電子レンジまで移動する　(それか棚の前まで移動してサトウのご飯を掴む動作をするなど，それには認識が必要か？)
  (move-to-microwave-with-speech-before)
  
  ;; サトウのごはんを調理する
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/microwave-codes.l")
  (update-pos)
  (now-sato-rice-micro)
  
  ;; サトウのごはんを持ってキッチンまで行く 
  (move-to-arrange-with-speech-after)
  
  ;; サトウのごはんを置く，(移動先で受け取る？持ったまま移動して左手に渡すか？) 
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/arrangement-codes.l")
  (update-pos)
  (now-put-sato-rarm)
  
  (send *ri* :speak-jp "ごはんを温める調理を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (curry-a-2) ~%")
  )

(defun curry-a-2 ()
  (send *ri* :speak-jp "盛り付ける調理を開始します")
  
  ;; サトウのごはんを盛り付ける ;;TODO ヘラを 
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/arrangement-codes.l")
  (update-pos)
  ;; (grasp-spatula)
  (grasp-spatula-with-fail-detection)
  (now-arrange-sato)
  (put-spatula)
  
  ;; 少し温めるなら温める (今は良いかな？)
  
  ;; カレーを盛り付ける
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/arrangement-codes.l")
  (update-pos)
  ;; (grasp-ladle)
  (grasp-ladle-with-fail-detection)
  (now-arrange-curry)
  (put-ladle)
  
  ;;完成！！
  (send *ri* :speak-jp "盛り付ける工程を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "カレーライスが完成しました")
  )

