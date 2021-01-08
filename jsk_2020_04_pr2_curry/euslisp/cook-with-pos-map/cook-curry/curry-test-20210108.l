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
  
  ;; 棚の中にヘラとおたまをセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  ;; (now-set-in-shelf-with-dialogue)
  (now-set-in-shelf-with-dialogue-and-fail-detection)
  
  ;; ボウル１をセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  ;; (now-set-1-model-with-dialogue)
  (now-set-1-model-rarm-with-dialogue)
  
  ;; 野菜をセットする？
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  (now-set-vegs-with-dialogue)
  
  ;; 計量カップはここでセットする？
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  (now-set-mcup-with-dialogue)
  
  ;; コンロの前まで移動する
  ;; (go-to-stove-with-speech-before)
  (move-to-stove-with-speech-before)
  
  ;; ボウル２・３をセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-stove-codes.l")
  (update-pos)
  (now-set-2-model-with-dialogue)
  (now-set-3-model-with-dialogue)
  (now-set-oil-with-dialogue)
  ;; (now-set-mcup-with-dialogue)
  
  ;; キッチンの前に戻る
  ;; (go-to-kitchen-from-stove-with-speech-after)
  (move-to-kitchen-with-speech-after)
  
  ;; まな板をセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cutting-board-codes.l")
  (update-pos)
  (now-set-board-with-dialogue)
  
  ;; 道具３つをセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (now-set-tools-with-dialogue) ;; 包丁，ピーラー，じゃがいもピーラーをセットする．
  (reset-rarm)
  
  (send *ri* :speak-jp "準備を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (curry-1) ~%")
  )

(defun curry-1 () ;; 人参の下ごしらえ
  (send *ri* :speak-jp "人参の調理を開始します")
  
  ;; 人参を掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  ;; (now-grasp-carrot)
  (now-grasp-carrot-with-fail-detection)
  
  ;; シンクの前に移動する
  ;; (go-to-sink-with-speech-before)
  (move-to-sink-with-speech-before)
  
  ;; 人参を洗う
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
  (update-pos)
  (now-wash-veg)
  
  ;; キッチンの前に戻る
  ;; (go-to-kitchen-from-sink-with-speech-after)  
  (move-to-kitchen-with-speech-after)
  
  ;; 人参をまな板に置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  (now-put-carrot-on-board)
  
  ;; ピーラーを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  ;; (grasp-peeler)
  (grasp-peeler-with-fail-detection)
  
  ;; 人参の皮剥き
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/peel-carrot-codes.l")
  (update-pos)
  (now-peel)
  (now-rotate)
  (now-peel)
  
  ;; ピーラーを置く，包丁を掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (put-peeler)
  ;; (grasp-knife)
  (grasp-knife-with-fail-detection)
  
  ;; 人参切断
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cut-carrot-codes.l")
  (update-pos)
  (now-cut)
  
  ;; 包丁を置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (put-knife)
  (reset-rarm)
  
  ;; ;; ボウル１に移す動作
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/transfer-vegs-codes.l")
  ;; (update-pos)
  ;; (now-transfer-bowl-1-kitchen)
  ;; (reset-larm)

  ;; ボウル１に移す動作 まな板を持って移す
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cutting-board-codes.l")
  (update-pos)
  (now-cutting-board-transfer-bowl-1-all-with-fail-detection)
  (reset-rarm)
  
  (send *ri* :speak-jp "人参の調理を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (curry-2) ~%")
  )

(defun curry-2 () ;; じゃがいもの下ごしらえ
  (send *ri* :speak-jp "じゃがいもの調理を開始します")
  
  ;; じゃがいもを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  ;; (now-grasp-potato)
  (now-grasp-carrot-with-fail-detection)
  
  ;; シンクの前に移動する
  ;; (go-to-sink-with-speech-before)
  (move-to-sink-with-speech-before)
  
  ;; じゃがいもを洗う
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
  (update-pos)
  (now-wash-veg)
  
  ;; キッチンの前に戻る
  ;; (go-to-kitchen-from-sink-with-speech-after)  
  (move-to-kitchen-with-speech-after)
  
  ;; じゃがいもをまな板に置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  (now-put-potato-on-board)
  
  ;; じゃがいもピーラーを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  ;; (grasp-potato-peeler)
  (grasp-potato-peeler-with-fail-detection)
  
  ;; じゃがいも皮剥き
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/peel-potato-codes.l")
  (update-pos)
  (now-peel)
  (now-rotate)
  (now-peel)
  
  ;; じゃがいもピーラーを置いて包丁を掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (put-potato-peeler)
  ;; (grasp-knife)
  (grasp-knife-with-fail-detection)

  ;; じゃがいも切断   ;; ここ上手くいかないとおもう
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cut-potato-codes.l")
  (update-pos)
  (now-cut-half)
  (now-right-set)
  (now-right-rotate)
  (now-cut-right)
  (now-left-rotate)
  (now-cut-left)
  
  ;; 包丁を置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (put-knife)
  
  ;; ;; ボウル１に移す動作
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/transfer-vegs-codes.l")
  ;; (update-pos)
  ;; (now-transfer-bowl-1-kitchen)
  ;; (reset-larm)

  ;; ボウル１に移す動作 まな板を持って移す
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cutting-board-codes.l")
  (update-pos)
  (now-cutting-board-transfer-bowl-1-all-with-fail-detection)
  (reset-rarm)
  
  (send *ri* :speak-jp "じゃがいもの調理を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")

  (warn "please run (curry-3) ~%")
  )

(defun curry-3 ()
  (send *ri* :speak-jp "たまねぎの調理を開始します")
  
  ;; たまねぎを掴む？？
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  ;; (now-grasp-onion)
  (now-grasp-onion-with-fail-detection)
  
  ;; シンクの前に移動する
  ;; (go-to-sink-with-speech-before)
  (move-to-sink-with-speech-before)
  
  ;; たまねぎを洗う
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
  (update-pos)
  (now-wash-veg)
  
  ;; キッチンの前に戻る
  ;; (go-to-kitchen-from-sink-with-speech-after)  
  (move-to-kitchen-with-speech-after)

  ;; たまねぎをまな板に置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  (now-put-onion-on-board)  
  
  ;; 包丁を掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  ;; (grasp-knife)
  (grasp-knife-with-fail-detection)
  
  ;; たまねぎ切断
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cut-onion-codes.l")
  (update-pos)
  (now-cut)
  
  ;; 包丁を置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (put-knife)
  
  ;; まな板を持って鍋に移す動作
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cutting-board-codes.l")
  (update-pos)
  (now-cutting-board-transfer-set)
  ;; (grasp-knife)
  (grasp-knife-with-fail-detection)
  (now-cutting-board-transfer)
  (put-knife)
  (reset-rarm)
  (now-cutting-board-transfer-after)
  
  (send *ri* :speak-jp "たまねぎの調理を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (curry-4) ~%")
  )

(defun curry-4 () ;; 加熱調理の準備
  (send *ri* :speak-jp "炒める調理の準備を開始します")  
  
  ;; ヘラとおたまを棚から取り出す 
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  ;; (now-set-from-shelf)
  (now-set-from-shelf-with-failure-detection)
  
  ;; コンロの前まで移動する
  ;; (go-to-stove-with-speech-before-and-after)
  (move-to-stove-with-speech-before-and-after)
  
  ;; 油を掛ける
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-stove-codes.l")
  (update-pos)
  ;; (now-add-oil)
  (now-add-oil-with-fail-detection)
  
  (send *ri* :speak-jp "炒める調理の準備を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (curry-5) ~%")
  )

(defun curry-5 () ;; 玉ねぎを炒める
  (send *ri* :speak-jp "たまねぎを炒める調理を開始します")
  
  ;; コンロ操作をする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  ;; (now-on-stove)
  ;; (grasp-spatula)
  (grasp-spatula-with-fail-detection)
  ;; (now-start-ih :deg -10)
  (now-start-ih-with-fail-detection :deg -10)
  (grasp-pot-from-below-model-with-fail-detection)
  (now-spatula-mix-rotate-loop-with-dialogue :times 10)
  
  ;; 火を止める
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (set-spatula)
  (after-spatula-mix)
  (push-knob)
  
  (send *ri* :speak-jp "たまねぎを炒める調理を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")

  (warn "please run (curry-6) ~%")
  )

(defun curry-6 () ;; 肉を炒める
  (send *ri* :speak-jp "肉を炒める調理を開始します")
  
  ;; ボウル２を鍋に移す ヘラは掴んでいる前提
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-stove-codes.l")
  (update-pos)
  (now-transfer-2-model)
  
  ;; コンロ操作をする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  ;; (now-start-ih :deg -10)
  (now-start-ih-with-fail-detection :deg -10)
  (set-spatula)
  (grasp-pot-from-below-model-with-fail-detection)
  (now-spatula-mix-rotate-loop-with-dialogue :times 10)
  
  ;; 火を止める
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (set-spatula)
  (after-spatula-mix)
  (push-knob)
  
  (put-spatula-1) ;; ヘラを置く
  (reset-rarm)
  
  (send *ri* :speak-jp "肉を炒める調理を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (curry-7) ~%")
  )

(defun curry-7 () ;; 野菜を入れる
  (send *ri* :speak-jp "煮込む調理の準備を開始します")
  
  ;; キッチン前に移動する
  ;; (go-to-kitchen-from-stove-with-speech-before)
  (move-to-kitchen-with-speech-before)
  
  ;; ;; ボウル１を鍋に移す ヘラは掴んでいる前提
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  ;; (update-pos)
  ;; (now-transfer-1-model) ;; ヘラは掴んでいる前提
  ;; (put-spatula-1)
  ;; (reset-rarm)
  
  ;; ボウル１を鍋に移す
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  (now-transfer-1-model-with-change)
  
  ;; 計量カップを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  ;; (now-grasp-mcup)
  (now-grasp-mcup-with-fail-detection)
  
  ;; 水を汲んで注ぐのを繰り返す
  (setq *fetch-flag* nil)
  (until *fetch-flag*
         ;; (go-to-sink)
         (move-to-sink-ri-direct)
	 
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
  
  (send *ri* :speak-jp "移動します")
  (unix:sleep 2)
  ;; (go-to-stove-with-speech-after)
  (move-to-stove-with-speech-after)
  
  (send *ri* :speak-jp "煮込む調理の準備を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (curry-8) ~%")
  )

(defun curry-8 () ;; 煮込む動作
  (send *ri* :speak-jp "煮込む調理を開始します")
  
  ;; コンロ操作，沸騰しているか見る
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  ;; (now-start-ih :deg -30)
  (now-start-ih-with-fail-detection :deg -30)
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

(defun curry-9 ()   ;; カレールーを入れる
  (send *ri* :speak-jp "カレールーを入れる工程を開始します")
  
  ;; ボウル３を鍋に移し，ヘラを置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-stove-codes.l")
  (update-pos)
  ;; (grasp-spatula)
  (grasp-spatula-with-fail-detection)
  (now-transfer-3-model)
  (put-spatula-1)
  
  ;; おたまを掴む，コンロ操作，おたまで混ぜる． ;; TODO 少し混ぜながら良さそうか聞いて終わる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  ;; (grasp-ladle) ;; おたまを掴む 
  (grasp-ladle-with-fail-detection)
  ;; (now-start-ih :deg -30) ;; 弱火にする
  (now-start-ih-with-fail-detection :deg -30) ;; 弱火にする
  (now-ladle-mix-rotate-loop-with-dialogue)
  
  ;; 火を止める
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (after-ladle-mix)
  (push-knob)
  (put-ladle-1)  
  
  ;; ここでひとまず完成にする！！！　今回は！！ ;; TODO 対話を入れる
  (send *ri* :speak-jp "カレールーを入れる工程を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "カレーが完成しました")
  
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


(defun curry-all ()
  (curry-0) ;; 準備
  (unix:sleep 2)
  (curry-1) ;; 人参の調理
  (unix:sleep 2)
  (curry-2) ;; じゃがいもの調理
  (unix:sleep 2)
  (curry-3) ;; たまねぎの調理
  (unix:sleep 2)
  (curry-4) ;; 炒める調理の準備
  (unix:sleep 2)
  (curry-5) ;; たまねぎを炒める
  (unix:sleep 2)
  (curry-6) ;; 肉を炒める
  (unix:sleep 2)
  (curry-7) ;; 煮込む調理の準備
  (unix:sleep 2)
  (curry-8) ;; 煮込む調理
  (unix:sleep 2)
  (curry-9) ;; カレールーを入れる
  )


(defun tmp-curry ()
  ;; 火を止める
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (set-spatula)
  (after-spatula-mix)
  (push-knob)
  
  (send *ri* :speak-jp "肉を炒める調理を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (unix:sleep 2)
  (curry-7) ;; 煮込む調理の準備
  (unix:sleep 2)
  (curry-8) ;; 煮込む調理
  (unix:sleep 2)
  (curry-9) ;; カレールーを入れる
  )
