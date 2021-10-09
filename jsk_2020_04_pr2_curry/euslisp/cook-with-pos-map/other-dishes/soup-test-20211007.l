(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")
(warn "please run (soup-0) or (soup-all)~%")

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

(defun soup-0 () ;; 最初の準備
  (send *ri* :speak-jp "準備を開始します") ;; 最初の位置はkitchenの場所 (move-to-kitchen-ri-direct)
  
  ;; 設置するもの
  ;; おたま，赤いコップ，など，，皿も？？ 
  
  ;; 赤いコップをセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  (now-set-rcup-with-dialogue)
  
  ;; おたまとお皿を用意する
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  ;; (now-set-ladle-a-with-dialogue)
  (now-set-ladle-a-and-plate-with-dialogue)
  
  (send *ri* :speak-jp "準備を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (soup-1) ~%")
  )


(defun soup-1 () ;; 粉末を入れる
  ;; ここをいい感じにしたい！！アイデアが必要？
  
  (warn "WIP !!  ~%")

  (warn "please run (soup-2) ~%")
  )

(defun soup-2 () ;; 水を汲む
  (send *ri* :speak-jp "水を汲む調理を開始します")
  
  ;; 赤いコップを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  (now-grasp-rcup-pot-side-with-fail-detection)
  
  ;; 水を汲んで注ぐのを繰り返す
  (setq *fetch-flag* nil)
  (until *fetch-flag*
         (move-to-sink-with-speech-before-with-rec)
         
         ;; 水を汲む
         (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
         (update-pos)
         (now-fetch-water-rcup-with-fail-detection :sleep-time 1)

         ;; kitchenまで:go-pos-unsafeで移動
         (go-to-kitchen-from-sink-without-map)
         
         ;; 水を注ぐ
         (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
         (update-pos)
         (now-only-pour-rcup-water :sleep-time 4)
         
         
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
  (put-rcup)
  (reset-larm)
  
  (send *ri* :speak-jp "移動します")
  (unix:sleep 2)
  (move-to-stove-with-speech-after-with-rec)
  
  (send *ri* :speak-jp "水を汲む調理を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (soup-3) ~%")
  )


(defun soup-3 () ;; 沸騰させる
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
  
  (warn "please run (soup-4) ~%")
  )


(defun soup-4 () ;; お湯を注ぐ
  ;; 盛り付けの位置に移動する
  (move-to-arrange-with-speech-before-and-before-with-rec)
  
  ;; おたまを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/arrangement-codes.l")
  (update-pos)
  (grasp-ladle-with-fail-detection)
  
  ;; お湯を注ぐ ;; 何回かやる？
  (setq *pour-flag* nil)
  (until *pour-flag*
	 (grasp-pot-from-below-model-with-fail-detection)
	 (now-arrange-curry) ;; ここを改良したい？？認識を入れるなどしたい？IKが失敗したらやめるなど？
         ;; お湯を注ぐ状態を確認する
         ;; (look-at-pot) 
         (send *ri* :speak-jp "まだお湯が必要ですか？")
         (curry-dialogue)
         (unless (equal *data* '("はい"))
           (setq *pour-flag* t)
           )
         )
  
  (release-pot-from-below-model)
  (put-ladle-a)
  (reset-rarm)
  (set-pose)
  
  ;;完成！！
  (send *ri* :speak-jp "お湯を注ぐ工程を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "スープが完成しました")
  )


(defun soup-all ()
  (soup-0) ;; 最初の準備
  (unix:sleep 2)
  (soup-1) ;; 粉末を入れる
  (unix:sleep 2)
  (soup-2) ;; 水を汲む
  (unix:sleep 2)
  (soup-3) ;; 沸騰させる
  (unix:sleep 2)
  (soup-4) ;; お湯を注ぐ
  )
