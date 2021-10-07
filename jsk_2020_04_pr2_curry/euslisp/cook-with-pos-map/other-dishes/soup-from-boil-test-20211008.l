(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")
(warn "please run (soup-boil-0) or (soup-boil-all)~%")

;; 最初に換気扇とIHの電源を入れていく

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

(defun soup-boil-0 () ;; 最初の準備
  (send *ri* :speak-jp "準備を開始します") ;; 最初の位置はarrangeの場所 (move-to-arrange-ri-direct)
  
  ;; 設置するもの
  ;; おたまと皿も？？ 
  
  ;; おたまとお皿を用意する
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  ;; (now-set-ladle-a-with-dialogue)
  (now-set-ladle-a-and-plate-with-dialogue)
  
  (send *ri* :speak-jp "準備を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (soup-boil-1) ~%")
  )


(defun soup-boil-1 () ;; 粉末を入れる 動作をさせる
  (send *ri* :speak-jp "沸騰させる調理を開始します")
  
  ;; 着火する
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (now-start-ih-with-fail-detection :deg 0)

  ;; 沸騰させる
  (now-boil-with-dialogue)
  
  ;; 火を止める
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (push-knob)
  
  (send *ri* :speak-jp "沸騰させる調理を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (soup-boil-2) ~%")
  )

(defun soup-boil-2 () ;; 水を汲む
  ;; ;; 盛り付けの位置に移動する arrangeの位置で全てやる，stoveの位置で全てやる，arrangeとstoveの位置を行き来するなど色々考えられる．
  ;; (move-to-arrange-with-speech-before-and-before-with-rec)
  
  ;; おたまを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/arrangement-codes.l")
  (update-pos)
  (grasp-ladle-with-fail-detection)
  
  ;; お湯を注ぐ ;; 何回かやる？
  (setq *pour-flag* nil)
  (until *pour-flag*
         (now-arrange-curry) ;; ここを改良したい？？認識を入れるなどしたい？IKが失敗したらやめるなど？
         ;; お湯を注ぐ状態を確認する
         ;; (look-at-pot) 
         (send *ri* :speak-jp "まだお湯が必要ですか？")
         (curry-dialogue)
         (unless (equal *data* '("はい"))
           (setq *pour-flag* t)
           )
         )
  
  (put-ladle)
  
  ;;完成！！
  (send *ri* :speak-jp "お湯を注ぐ工程を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "スープが完成しました")

  ;; (warn "please run (soup-boil-3) ~%")
  )


(defun soup-boil-3 () ;; 冷ます
  
  (warn "please run (soup-boil-4) ~%")
  )

(defun soup-boil-all ()
  (soup-boil-0) ;; 最初の準備
  (unix:sleep 2)
  (soup-boil-1) ;; 沸騰させる
  (unix:sleep 2)
  (soup-boil-2) ;; お湯を注ぐ
  ;; (unix:sleep 2)
  ;; (soup-boil-3) ;; 冷ます
  )
