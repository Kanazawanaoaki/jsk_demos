(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()  
  (warn "init! ~%")
  )


(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")

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



;; それぞれの関数，smachを呼び出す時は使わない？？
(defun curry-0 ()
  (send *ri* :speak-jp "準備を開始します")
  
  ;; 棚の中にヘラとおたまをセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  ;; (now-set-in-shelf-with-dialogue)
  (now-set-in-shelf-with-dialogue-and-fail-detection)
  
  ;; ボウル１をセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  ;; (now-set-1-model-with-dialogue)
  (now-set-1-model-rarm-with-dialogue)
  
  ;; 野菜をセットする？
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
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
  (now-grasp-potato-with-fail-detection)
  
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
  (set-pose-3)
  
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
  (set-pose-3)
  
  (put-spatula-1) ;; ヘラを置く
  (reset-rarm)
  
  (send *ri* :speak-jp "肉を炒める調理を行いました．確認して合図をして下さい")
  (curry-ok-wait)
  (send *ri* :speak-jp "次の工程に移ります")
  
  (warn "please run (curry-7) ~%")
  )

(defun curry-7 () ;; 煮込む調理の準備
  (send *ri* :speak-jp "煮込む調理の準備を開始します")
  (unix:sleep 2)
  
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
         ;; (now-fetch-water :sleep-time 1)
         (now-fetch-water-with-fail-detection :sleep-time 1)
         
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
  (now-start-ih-with-fail-detection :deg 0)
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
  (grasp-pot-from-below-model-with-fail-detection)
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


;; curry-0
(defun curry-0-1 ()
  (warn "curry-0-1 棚の中にヘラとおたまをセットする ~%")
  ;; 棚の中にヘラとおたまをセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  ;; (now-set-in-shelf-with-dialogue)
  (now-set-in-shelf-with-dialogue-and-fail-detection)  
  )

(defun curry-0-2 ()
  (warn "curry-0-2 ボウル１をセットする ~%")
  ;; ボウル１をセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  ;; (now-set-1-model-with-dialogue)
  (now-set-1-model-rarm-with-dialogue)
  )

(defun curry-0-3 ()
  (warn "curry-0-3 野菜をセットする ~%")
  ;; 野菜をセットする？
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  (now-set-vegs-with-dialogue)
  )

(defun curry-0-4 ()
  (warn "curry-0-4 計量カップはここでセットする~%")
  ;; 計量カップはここでセットする？
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  (now-set-mcup-with-dialogue)
  )

(defun curry-0-5 ()
  (warn "curry-0-5 コンロの前まで移動する ~%")
  ;; コンロの前まで移動する
  ;; (go-to-stove-with-speech-before)
  (move-to-stove-with-speech-before)
  )

(defun curry-0-6 ()
  (warn "curry-0-6 ボウル２・３をセットする ~%")
  ;; ボウル２・３をセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-stove-codes.l")
  (update-pos)
  (now-set-2-model-with-dialogue)
  (now-set-3-model-with-dialogue)
  (now-set-oil-with-dialogue)
  ;; (now-set-mcup-with-dialogue)
  )

(defun curry-0-7 ()
  (warn "curry-0-7 キッチンの前に戻る ~%")
  ;; キッチンの前に戻る
  ;; (go-to-kitchen-from-stove-with-speech-after)
  (move-to-kitchen-with-speech-after)
  )

(defun curry-0-8 ()
  (warn "curry-0-8 まな板をセットする ~%")
  ;; まな板をセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cutting-board-codes.l")
  (update-pos)
  (now-set-board-with-dialogue)
  )

(defun curry-0-9 ()
  (warn "curry-0-9 道具３つをセットする~%")
  ;; 道具３つをセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (now-set-tools-with-dialogue) ;; 包丁，ピーラー，じゃがいもピーラーをセットする．
  (reset-rarm)
  )


;; curry-1
(defun curry-1-1 ()
  (warn "人参を掴む ~%")
  ;; 人参を掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  ;; (now-grasp-carrot)
  (now-grasp-carrot-with-fail-detection)
  )

(defun curry-1-2 ()
  (warn "シンクの前に移動する ~%")
  ;; シンクの前に移動する
  ;; (go-to-sink-with-speech-before)
  (move-to-sink-with-speech-before)
  )

(defun curry-1-3 ()
  (warn "人参を洗う ~%")
  ;; 人参を洗う
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
  (update-pos)
  (now-wash-veg)
  )

(defun curry-1-4 ()
  (warn "キッチンの前に戻る ~%")
  ;; キッチンの前に戻る
  ;; (go-to-kitchen-from-sink-with-speech-after)  
  (move-to-kitchen-with-speech-after)
  )

(defun curry-1-5 ()
  (warn "人参をまな板に置く ~%")
  ;; 人参をまな板に置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  (now-put-carrot-on-board)
  )

(defun curry-1-6 ()
  (warn "ピーラーを掴む ~%")
  ;; ピーラーを置く，包丁を掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (put-peeler)
  ;; (grasp-knife)
  (grasp-knife-with-fail-detection)
  )

(defun curry-1-7 ()
  (warn "人参の皮剥き ~%")
  ;; 人参の皮剥き
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/peel-carrot-codes.l")
  (update-pos)
  (now-peel)
  (now-rotate)
  (now-peel)
  )

(defun curry-1-8 ()
  (warn "ピーラーを置く，包丁を掴む ~%")
  ;; ピーラーを置く，包丁を掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (put-peeler)
  ;; (grasp-knife)
  (grasp-knife-with-fail-detection)
  )

(defun curry-1-9 ()
  (warn "人参切断 ~%")
  ;; 人参切断
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cut-carrot-codes.l")
  (update-pos)
  (now-cut)
  )

(defun curry-1-10 ()
  (warn "包丁を置く ~%")
  ;; 包丁を置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (put-knife)
  (reset-rarm)
  )

(defun curry-1-11 ()
  (warn "ボウル１に移す動作 ~%")
  ;; ボウル１に移す動作 まな板を持って移す
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cutting-board-codes.l")
  (update-pos)
  (now-cutting-board-transfer-bowl-1-all-with-fail-detection)
  )


;; curry-2
(defun curry-2-1 ()
  (warn "じゃがいもを掴む ~%")
  ;; じゃがいもを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  ;; (now-grasp-potato)
  (now-grasp-potato-with-fail-detection) 
  )

(defun curry-2-2 ()
  (warn "シンクの前に移動する ~%")
  ;; シンクの前に移動する
  ;; (go-to-sink-with-speech-before)
  (move-to-sink-with-speech-before)
  )

(defun curry-2-3 ()
  (warn "じゃがいもを洗う ~%")
  ;; じゃがいもを洗う
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
  (update-pos)
  (now-wash-veg)
  )

(defun curry-2-4 ()
  (warn "キッチンの前に戻る ~%")
  ;; キッチンの前に戻る
  ;; (go-to-kitchen-from-sink-with-speech-after)  
  (move-to-kitchen-with-speech-after)
  )

(defun curry-2-5 ()
  (warn "じゃがいもをまな板に置く ~%")
  ;; じゃがいもをまな板に置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  (now-put-potato-on-board)
  )

(defun curry-2-6 ()
  (warn "じゃがいもピーラーを掴む ~%")
  ;; じゃがいもピーラーを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  ;; (grasp-potato-peeler)
  (grasp-potato-peeler-with-fail-detection)
  )

(defun curry-2-7 ()
  (warn "じゃがいもの皮剥き ~%")
  ;; じゃがいも皮剥き
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/peel-potato-codes.l")
  (update-pos)
  (now-peel)
  (now-rotate)
  (now-peel)
  )

(defun curry-2-8 ()
  (warn "じゃがいもピーラーを置く，包丁を掴む ~%")
  ;; じゃがいもピーラーを置いて包丁を掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (put-potato-peeler)
  ;; (grasp-knife)
  (grasp-knife-with-fail-detection)
  )

(defun curry-2-9 ()
  (warn "じゃがいも切断 ~%")
  ;; じゃがいも切断   ;; ここ上手くいかないとおもう
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cut-potato-codes.l")
  (update-pos)
  (now-cut-half)
  (now-right-set)
  (now-right-rotate)
  (now-cut-right)
  (now-left-rotate)
  (now-cut-left)
  )

(defun curry-2-10 ()
  (warn "包丁を置く ~%")
  ;; 包丁を置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (put-knife)
  )

(defun curry-2-11 ()
  (warn "ボウル１に移す動作 ~%")
  ;; ボウル１に移す動作 まな板を持って移す
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cutting-board-codes.l")
  (update-pos)
  (now-cutting-board-transfer-bowl-1-all-with-fail-detection)
  )

;; curry-3
(defun curry-3-1 ()
  (warn "たまねぎを掴む ~%")
  ;; たまねぎを掴む？？
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  ;; (now-grasp-onion)
  (now-grasp-onion-with-fail-detection)
  )

(defun curry-3-2 ()
  (warn "シンクの前に移動する ~%")
  ;; シンクの前に移動する
  ;; (go-to-sink-with-speech-before)
  (move-to-sink-with-speech-before)
  )

(defun curry-3-3 ()
  (warn "たまねぎを洗う ~%")
  ;; たまねぎを洗う
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
  (update-pos)
  (now-wash-veg)
  )

(defun curry-3-4 ()
  (warn "キッチンの前に戻る ~%")
  ;; キッチンの前に戻る
  ;; (go-to-kitchen-from-sink-with-speech-after)  
  (move-to-kitchen-with-speech-after)
  )

(defun curry-3-5 ()
  (warn "たまねぎをまな板に置く ~%")
  ;; たまねぎをまな板に置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  (now-put-onion-on-board)  
  )

(defun curry-3-6 ()
  (warn "包丁を掴む ~%")
  ;; 包丁を掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  ;; (grasp-knife)
  (grasp-knife-with-fail-detection)
  )

(defun curry-3-7 ()
  (warn "たまねぎ切断 ~%")
  ;; たまねぎ切断
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cut-onion-codes.l")
  (update-pos)
  (now-cut)
  )

(defun curry-3-8 ()
  (warn "包丁を置く ~%")
  ;; 包丁を置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (put-knife)
  )

(defun curry-3-9 ()
  (warn "鍋に移す動作 ~%")
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
  )

;; curry-4
(defun curry-4-1 ()
  (warn "ヘラとおたまを棚から取り出す ~%")
  ;; ヘラとおたまを棚から取り出す 
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  ;; (now-set-from-shelf)
  (now-set-from-shelf-with-failure-detection)
  )

(defun curry-4-2 ()
  (warn "コンロの前まで移動する ~%")
  ;; コンロの前まで移動する
  ;; (go-to-stove-with-speech-before-and-after)
  (move-to-stove-with-speech-before-and-after)
  )

(defun curry-4-3 ()
  (warn "油を掛ける ~%")
  ;; 油を掛ける
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-stove-codes.l")
  (update-pos)
  ;; (now-add-oil)
  (now-add-oil-with-fail-detection)
  )

;; curry-5
(defun curry-5-1 ()
  (warn "ヘラを掴む ~%")
  ;; ヘラを掴んで置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (grasp-spatula-with-fail-detection)
  )

(defun curry-5-2 ()
  (warn "火を着ける ~%")
  ;; コンロ操作をする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (now-start-ih-with-fail-detection :deg -10)  
  )

(defun curry-5-3 ()
  (warn "炒める ~%")
  ;; コンロ操作をする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (grasp-pot-from-below-model-with-fail-detection)
  (now-spatula-mix-rotate-loop-with-dialogue :times 10)    
  )

(defun curry-5-4 ()
  (warn "火を止める ~%")
  ;; 火を止める
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (set-spatula)
  (after-spatula-mix)
  (push-knob)
  (set-pose-3)
  )

;; curry-6
(defun curry-6-1 ()
  (warn "肉を鍋に移す ~%")
  ;; ボウル２を鍋に移す ヘラは掴んでいる前提
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-stove-codes.l")
  (update-pos)
  (now-transfer-2-model)
  )

(defun curry-6-2 ()
  (warn "火を着ける ~%")
  ;; コンロ操作をする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  ;; (now-start-ih :deg -10)
  (now-start-ih-with-fail-detection :deg -10)  
  )

(defun curry-6-3 ()
  (warn "炒める ~%")
  ;; コンロ操作をする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (set-spatula)
  (grasp-pot-from-below-model-with-fail-detection)
  (now-spatula-mix-rotate-loop-with-dialogue :times 10)
  )

(defun curry-6-4 ()
  (warn "火を止める ~%")
  ;; 火を止める
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (set-spatula)
  (after-spatula-mix)
  (push-knob)
  (set-pose-3)
  )

(defun curry-6-5 ()
  (warn "ヘラを置く ~%")
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (put-spatula-1) ;; ヘラを置く
  (reset-rarm)
  )

;; curry-7
(defun curry-7-1 ()
  (warn "キッチン前に移動する ~%")
  ;; キッチン前に移動する
  ;; (go-to-kitchen-from-stove-with-speech-before)
  (move-to-kitchen-with-speech-before)
  )

(defun curry-7-2 ()
  (warn "野菜を鍋に移す ~%")
  ;; ボウル１を鍋に移す
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  (now-transfer-1-model-with-change)
  )

(defun curry-7-3 ()
  (warn "計量カップを掴む ~%")
  ;; 計量カップを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  ;; (now-grasp-mcup)
  (now-grasp-mcup-with-fail-detection)
  )

(defun curry-7-4 ()
  (warn "水を汲む ~%")
  ;; 水を汲んで注ぐのを繰り返す とりあえずこれで行こう．
  (setq *fetch-flag* nil)
  (until *fetch-flag*
         ;; (go-to-sink)
         (move-to-sink-ri-direct)
         
         ;; 水を汲む
         (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
         (update-pos)
         ;; (now-fetch-water :sleep-time 1)
         (now-fetch-water-with-fail-detection :sleep-time 1)
         
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
  )

(defun curry-7-5 ()
  (warn "計量カップを置く ~%")
  ;; 計量カップを置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  (put-mcup)
  (reset-larm)
  )

(defun curry-7-6 ()
  (warn "コンロの前まで移動する ~%")
  (send *ri* :speak-jp "移動します")
  (unix:sleep 2)
  ;; (go-to-stove-with-speech-after)
  (move-to-stove-with-speech-after)
  )

;; curry-8
(defun curry-8-1 ()
  (warn "火を着ける ~%")
  ;; コンロ操作，沸騰しているか見る
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  ;; (now-start-ih :deg -30)
  (now-start-ih-with-fail-detection :deg 0)
  )

(defun curry-8-2 ()
  (warn "沸騰させる ~%")
  ;; コンロ操作，沸騰しているか見る
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (now-boil-with-dialogue)
  )

(defun curry-8-3 ()
  (warn "火を調整する ~%")
  ;; TODO
  )

(defun curry-8-4 ()
  (warn "煮込む ~%")
  ;; TODO
  
  )

(defun curry-8-5 ()
  (warn "火を消す ~%")
  ;; 火を止める
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (push-knob)
  )

;; curry-9
(defun curry-9-1 ()
  (warn "カレールーを鍋に入れる ~%")
  ;; ボウル３を鍋に移す
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-stove-codes.l")
  (update-pos)
  ;; (grasp-spatula)
  (grasp-spatula-with-fail-detection)
  (now-transfer-3-model)
  )

(defun curry-9-2 ()
  (warn "ヘラを置く ~%")
  ;; ヘラを置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-stove-codes.l")
  (update-pos)
  (put-spatula-1)
  )

(defun curry-9-3 ()
  (warn "おたまを掴んで火を着ける ~%")
  ;; おたまを掴む，コンロ操作，おたまで混ぜる． ;; TODO 少し混ぜながら良さそうか聞いて終わる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  ;; (grasp-ladle) ;; おたまを掴む 
  (grasp-ladle-with-fail-detection)
  ;; (now-start-ih :deg -30) ;; 弱火にする
  (now-start-ih-with-fail-detection :deg -30) ;; 弱火にする
  )

(defun curry-9-4 ()
  (warn "煮込む ~%")
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (grasp-pot-from-below-model-with-fail-detection)
  (now-ladle-mix-rotate-loop-with-dialogue)
  )

(defun curry-9-5 ()
  (warn "火を消す ~%")
  ;; 火を止める
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (after-ladle-mix)
  (push-knob)
  (put-ladle-1)  
  )

