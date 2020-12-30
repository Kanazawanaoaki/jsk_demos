(warn "please run (curry-0) ~%")

(defun curry-0 () ;; 最初の準備
  ;; 棚の中にヘラとおたまをセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (now-set-in-shelf)
  
  ;; ボウル１をセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  (now-set-1-model)
  
  ;; コンロの前まで移動する ;; TODO音声対話を入れる
  (go-to-stove)
  
  ;; ボウル２・３をセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-stove-codes.l")
  (update-pos)
  (now-set-2-model)
  (now-set-3-model)
  
  ;; キッチンの前に戻る ;; TODO音声対話を入れる
  (go-to-kitchen-from-stove)
  
  ;; まな板をセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cutting-board-codes.l")
  (update-pos)
  (now-set-board)
  
  ;; 道具３つをセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (now-set-tools) ;; 包丁，ピーラー，じゃがいもピーラーをセットする．
  (reset-rarm)
  
  (warn "please run (curry-1) ~%")
  )

(defun curry-1 () ;; 人参の下ごしらえ
  ;; 人参を掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  (now-grasp-carrot)
  
  ;; シンクの前に移動する ;; TODO音声対話を入れる
  (go-to-sink)
  
  ;; 人参を洗う
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
  (update-pos)
  ;;(wash-vegs) ;; TODO洗うプログラムを用意する

  ;; キッチンの前に戻る ;; TODO音声対話を入れる
  (go-to-kitchen-from-sink)  
  
  ;; 人参をまな板に置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  (now-put-carrot-on-board)
  
  ;; ピーラーを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (grasp-peeler)
  
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
  (grasp-knife)
  
  ;; 人参切断
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cut-carrot-codes.l")
  (update-pos)
  (now-cut)
  
  ;; 包丁を置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (put-knife)
  
  ;; ボウル１に移す動作
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/transfer-vegs-codes.l")
  (update-pos)
  (now-transfer-bowl-1-kitchen)
  
  (warn "please run (curry-2) ~%")
  )

(defun curry-2 () ;; じゃがいもの下ごしらえ
  ;; じゃがいもを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  (now-grasp-potato)
  
  ;; シンクの前に移動する
  (go-to-sink) ;; TODO音声対話を入れる
  
  ;; じゃがいもを洗う
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
  (update-pos)
  ;;(wash-vegs) ;; TODO洗うプログラムを用意する
  
  ;; キッチンの前に戻る
  (go-to-kitchen-from-sink) ;; TODO音声対話を入れる
  
  ;; じゃがいもをまな板に置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  (now-put-potato-on-board)
  
  ;; じゃがいもピーラーを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (grasp-potato-peeler)
  
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
  (grasp-knife)

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
  
  ;; ボウル１に移す動作
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/transfer-vegs-codes.l")
  (update-pos)
  (now-transfer-bowl-1-kitchen)
  
  (warn "please run (curry-3) ~%")
  )

(defun curry-3 ()
  ;; たまねぎを掴む？？
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  (now-grasp-onion)
  
  ;; シンクの前に移動する
  (go-to-sink) ;; TODO音声対話を入れる
  
  ;; たまねぎを洗う
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
  (update-pos)
  ;;(wash-vegs) ;; TODO

  ;; キッチンの前に戻る
  (go-to-kitchen-from-sink) ;; TODO音声対話を入れる
  
  ;; たまねぎをまな板に置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/grasp-vegs-codes.l")
  (update-pos)
  (now-put-onion-on-board)  
  
  ;; 包丁を掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (grasp-knife)
  
  ;; たまねぎ切断
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cut-carrot-codes.l")
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
  (grasp-knife)
  (now-cutting-board-transfer)
  (put-knife)
  (now-cutting-board-transfer-after)
  
  (warn "please run (curry-4) ~%")
  )

(defun curry-4 () ;; 加熱調理の準備
  ;; ヘラとおたまを棚から取り出す 
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (now-set-from-shelf)

  ;; コンロの前まで移動する ;; TODO音声対話を入れる
  (go-to-stove) ;; ここはケーブル位置もこっちに移動する．
  
  (warn "please run (curry-5) ~%")
  )

(defun curry-5 () ;; 玉ねぎを炒める
  ;; コンロ操作をする 電源を入れるところから
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (now-on-stove)
  ;; (now-start-ih :deg -10)
  (now-start-ih :deg -30) ;; 中火にする ;;本当に？
  
  ;; かき混ぜる　ヘラは掴んでいる前提 ;; TODO ヘラを掴むのを入れる？
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  ;; (now-spatula-mix)
  
  (now-start-spatula-mix)
  (spatula-mix-rotate-loop :times 10)
  
  ;; 認識を入れて，条件を達成するまで(spatula-mix-rotate-loop :times 10)を繰り返して，(push-knob) (after-spatula-mix)
  ;; tmpとしては音声対話を入れる方式にする．
  
  ;; 火を止める　玉ねぎを炒めたら一度火を止める
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (push-knob)
  (after-spatula-mix)
  
  (warn "please run (curry-6) ~%")
  )

(defun curry-6 () ;; 肉を炒める
  ;; ボウル２を鍋に移す ヘラは掴んでいる前提 ;; TODO変える必要あり．
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-stove-codes.l")
  (update-pos)
  (now-transfer-2-model)
  
  ;; コンロ操作をする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  ;; (now-start-ih :deg -10)
  (now-start-ih :deg -30) ;; 中火にする
  
  ;; かき混ぜる ヘラは掴んでいる前提 ;; TODO
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  ;; (now-spatula-mix)
  
  (now-start-spatula-mix)
  (spatula-mix-rotate-loop :times 5)
  
  ;; 認識を入れて，条件を達成するまで(spatula-mix-rotate-loop :times 10)を繰り返して， (push-knob) (after-spatula-mix)
  ;; tmpとしては音声対話を入れる方式にする．
  
  ;; 火を止める　玉ねぎを炒めたら一度火を止める
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (push-knob)
  (after-spatula-mix)
  
  (warn "please run (curry-7) ~%")
  )

(defun curry-7 () ;; 野菜を入れる
  ;; キッチン前に移動する ;; TODO

  
  ;; ボウル１を鍋に移す ヘラは掴んでいる前提
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  (update-pos)
  (now-transfer-1) ;; ヘラは掴んでいる前提
  (put-spatula-1)
  (reset-rarm)

  ;; 移し終わったら移動をする? ;; TODO

  
  (warn "please run (curry-8) ~%")
  )

(defun curry-8 () ;; 煮込む動作
  ;; おたまを掴む，コンロ操作，おたまで混ぜる． ;; TODO
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (grasp-ladle) ;; おたまを掴む 
  
  (now-start-ih :deg -50) ;; 弱火にする，弱火なのか？
  ;; (now-ladle-mix) ;; おたまで混ぜる
  
  ;; 沸騰するまで見る等をする？
  (look-at-pot)
  (dotimes (i 10)
    (unix:sleep 30)
    (send *ri* :speak-jp "画像を記録します")
    (unix:sleep 2)
    (rossrv-test)
    (send *ri* :speak-jp "記録しました")
    )
  
  ;; 沸騰したら灰汁を取る？
  
  ;; 沸騰してから少ししてから火を止める．時間などを見るのが良いか？
  ;; 火を止める
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (push-knob)
  (after-ladle-mix)
  
  (warn "please run (curry-9) ~%")
  )

(defun curry-9 ()   ;; カレールーを入れる
  ;; ボウル３を鍋に移す 途中でおたまからヘラに持ち替える
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-stove-codes.l")
  (update-pos)
  (put-ladle-1)
  (grasp-spatula)
  (now-transfer-3)
  (put-spatula-1)
  
  ;; おたまを掴む，コンロ操作，おたまで混ぜる． ;; TODO
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (grasp-ladle) ;; おたまを掴む 
  (now-start-ih :deg -50) ;; 弱火にする
  
  (look-at-pot)
  (rossrv-test)
  
  (now-ladle-mix) ;; おたまで混ぜる
  
  ;; (now-start-ladle-mix)
  ;; (ladle-mix-rotate-loop :times 10)
  
  ;; ここは時間で良さそう 時間が立ったら (push-knob) (after-ladle-mix)
  ;; 火を止める
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-stove-codes.l")
  (update-pos)
  (push-knob)
  (after-ladle-mix)
  
  (warn "please run (curry-10) ~%")
  )

(defun curry-10 ()
  ;; 電子レンジまで移動する　(それか棚の前まで移動してサトウのご飯を掴む動作をするなど，それには認識が必要か？) 
  
  
  ;; サトウのごはんを調理する
  
  
  ;; サトウのごはんを持ってキッチンまで行く
  
  (warn "please run (curry-11) ~%")
  )


(defun curry-11 ()
  ;; サトウのごはんを盛り付ける
  
  
  ;; 移動するなら移動する
  
  
  ;; 少し温めるなら温める
  
  ;; カレーを盛り付ける
  

  ;;完成！！
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