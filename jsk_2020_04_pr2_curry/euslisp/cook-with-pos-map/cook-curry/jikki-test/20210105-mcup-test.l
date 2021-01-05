(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")
(warn "please run (curry-0) or (curry-all)~%")

;; 最初に換気扇とIHの電源を入れていく，野菜を洗って台の上にセットしておく

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

(defun curry-0 () ;; 最初の準備
  (send *ri* :speak-jp "準備を開始します")

  ;; 計量カップをセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  (now-set-mcup-with-dialogue)
  
  (send *ri* :speak-jp "準備を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")

  (warn "please run (curry-1) ~%")
  )

(defun curry-1 () ;; 人参の下ごしらえ
  (send *ri* :speak-jp "煮込む調理の準備を開始します")

  ;; 計量カップを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  ;; (now-grasp-mcup)
  (now-grasp-mcup-with-fail-detection)
  
  (speech-before-move)
  
  ;; 水を汲んで注ぐのを繰り返す
  (setq *fetch-flag* nil)
  (until *fetch-flag*
         (go-to-sink)
         
         ;; 水を汲む
         (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
         (update-pos)
         (now-fetch-water :sleep-time 2)
         
         ;; (go-to-kitchen-from-sink)
         (go-to-kitchen-from-sink-without-map)
         
         ;; 水を注ぐ
         (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
         (update-pos)
         (now-only-pour-water :sleep-time 4)
         
         ;; 水汲みの状態を確認する
         (look-at-pot) 
         (send *ri* :speak-jp "まだ水が必要ですか？")
         (curry-dialogue)
         (unless (equal *data* '("はい"))
           (setq *fetch-flag* t)
           )
         )

  ;; 計量カップを置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  (put-mcup)
  (reset-larm)
    
  (send *ri* :speak-jp "煮込む調理の準備を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (curry-8) ~%")
  )

(defun curry-2 () ;; 煮込む動作
  (send *ri* :speak-jp "煮込む調理を開始します")

  (send *ri* :speak-jp "移動します")
  (unix:sleep 2)
  (go-to-stove-with-speech-after)
  
  ;; コンロ操作，沸騰しているか見る
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (now-start-ih :deg -30)
  (now-boil-with-dialogue)
  
  ;; 火を止める
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (push-knob)
  
  ;; 沸騰したら灰汁を取る？ (今はいいかな？)
  
  
  (send *ri* :speak-jp "煮込む調理を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (curry-9) ~%")
  )

;; defun util funcs
(defun tmp-func ()
  ;; かき混ぜる　ヘラは掴んでいる前提
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)

  (look-at-pot)
  (dotimes (i 10)
    (unix:sleep 30)
    (send *ri* :speak-jp "画像を記録します")
    (unix:sleep 2)
    (rossrv-test)
    (send *ri* :speak-jp "記録しました")
    )
  )


(defun mcup-all ()
  (curry-0) ;; 準備
  (unix:sleep 2)
  (curry-1) ;; 人参の調理
  (unix:sleep 2)
  (curry-2) ;; じゃがいもの調理
  (unix:sleep 2)
  )


(defun tmp-mcup ()
  (curry-0) ;; 準備
  (unix:sleep 2)
  (curry-1) ;; 人参の調理
  (unix:sleep 2)
  )
