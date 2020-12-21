(warn "please run (curry-0) ~%")

(defun curry-0 () ;; 非加熱調理の準備
  ;; 棚の中にヘラとおたまをセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (now-set-in-shelf)
  
  ;; ボウルをセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")
  (update-pos)
  (now-set-1)
  (now-set-2)
  
  ;; ;; まな板をセットする
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cutting-board-codes.l")
  ;; (update-pos)
  ;; (now-set-board)
  
  ;; 道具３つをセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (now-set-tools) ;; 包丁，ピーラー，じゃがいもピーラーをセットする．
  (reset-rarm)
  
  (warn "please run (curry-1) ~%")
  )

;; 人参を洗ってセットする
(defun curry-1 () ;; 人参の下ごしらえ
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
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/transfer-vegs/transfer-test-with-rec.l")
  (now-transfer-bowl-1)
  
  (warn "じゃがいもを洗ってセットして please run (curry-2) ~%")
  )

(defun curry-2 () ;; じゃがいもの下ごしらえ
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

  ;; じゃがいも切断
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
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/transfer-vegs/transfer-test-with-rec.l")
  (now-transfer-bowl-1)  
  
  (warn " 加熱準備の準備（棚を開けられたら無くせる）をして please run (curry-3) ~%")
  )

(defun curry-3 () ;; 加熱調理の準備
  ;; ボウルをセットする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")
  (update-pos)
  (switch-bowl-2) ;; ボウル２をまな板の上に
  (now-set-3) ;; ボウル３をセットする
  (now-set-4) ;; ボウル４をセットする
  
  ;; ヘラとおたまを置く 
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (now-set-spatula-1)
  (now-set-ladle-1)
  
  (warn "玉ねぎをセットして　please run (curry-4) ~%")
  )

(defun curry-4 () ;; 玉ねぎを炒める
  ;; ボウル２を鍋に移す
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")
  (update-pos)
  (grasp-spatula) ;; ヘラを掴む
  (now-transfer-2)
  
  ;; コンロ操作をする 電源を入れるところから
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)
  (now-on-stove)
  (now-start-ih :deg -10)
  
  ;; かき混ぜる　ヘラは掴んでいる前提
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)
  ;; (now-spatula-mix)
  (now-spatula-mix-loop :times 10)
  
  (warn " 玉ねぎを炒めて確認し，肉をセットして please run (curry-5) ~%")
  )

(defun curry-5 () ;; 肉を炒める
  ;; ;; 火を止める　玉ねぎを炒めたら一度火を止める
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  ;; (update-pos)
  ;; (push-knob)
  
  ;; ボウル４を鍋に移す ヘラは掴んでいる前提
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")
  (update-pos)
  (now-transfer-4) ;; ヘラは掴んでいる前提
  
  ;; コンロ操作をする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)
  (now-start-ih :deg -10)
  
  ;; かき混ぜる ヘラは掴んでいる前提
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)
  ;; (now-spatula-mix)
  (now-spatula-mix-loop :times 10)
  
  (warn "肉を炒めて確認して please run (curry-6) ~%")
  )

(defun curry-6 () ;; 野菜を入れる
  ;; ;; 火を止める　玉ねぎを炒めたら一度火を止める
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  ;; (update-pos)
  ;; (push-knob)
  
  ;; ボウル１を鍋に移す ヘラは掴んでいる前提
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")
  (update-pos)
  (now-transfer-1) ;; ヘラは掴んでいる前提
  (put-spatula-1)
  
  (warn "水を組んで入れたら please run (curry-7) ~%")
  )

(defun curry-7 () ;; 煮込む動作
  ;; おたまを掴む，コンロ操作，おたまで混ぜる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)
  (grasp-ladle) ;; おたまを掴む 
  (now-start-ih :deg -30) ;; コンロ操作
  ;; (now-ladle-mix) ;; おたまで混ぜる
  (now-ladle-mix-loop :times 10) ;; おたまで10回混ぜる
  
  (warn "灰汁を取るなどをしながら，カレールーを入れるタイミングで please run (curry-8) ~%")
  )

(defun curry-8 ()   ;; カレールーを入れる
  ;; ;; 火を止める　玉ねぎを炒めたら一度火を止める
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  ;; (update-pos)
  ;; (push-knob)

  ;; ボウル３を鍋に移す 途中でおたまからヘラに持ち替える
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")
  (update-pos)
  (put-ladle-1)
  (grasp-spatula)
  (now-transfer-3)
  (put-spatula-1)

  ;; おたまを掴む，コンロ操作，おたまで混ぜる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)
  (grasp-ladle) ;; おたまを掴む 
  (now-start-ih :deg -50) ;; コンロ操作
  ;; (now-ladle-mix) ;; おたまで混ぜる
  (now-ladle-mix-loop :times 10) ;; おたまで10回混ぜる
  
  (warn "完成するまで混ぜたり様子をみたりする ~%")
  )


;; defun util funcs
(defun use-ih-tmp ()
  ;; コンロ操作をする
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)
  (now-on-start-ih)
  )

(defun grasp-pot-tmp ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)
  (grasp-pot-from-below)
  )

(defun relase-pot-tmp ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)
  (release-pot-from-below)
  )

(defun spatula-mix-tmp (&rest args &key (times 10) &allow-other-keys)
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)
  (mix-with-spatula-set)
  (spatula-mix-loop :times times)
  (avoid-rarm-spatula)  
  )


(defun tmp-func ()
  ;; じゃがいもピーラーを掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (grasp-potato-peeler)

  ;; じゃがいも皮剥き
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/peel-potato-codes.l")
  (update-pos)
  (now-peel)
  
  ;; じゃがいもピーラーを置いて包丁を掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (put-potato-peeler)
  (grasp-knife)

  ;; じゃがいも切断
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
  )
