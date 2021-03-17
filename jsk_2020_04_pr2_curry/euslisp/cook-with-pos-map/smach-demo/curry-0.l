;; 準備のプログラムをプリミティブの組み合わせ等を書いていって整理していく感じ．

(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")
;; (warn "please run (curry-0) or (curry-all)~%")

(defun curry-0 () ;; 準備をする．  

  ;; 棚の中にヘラとおたまをセットする ;;重要
  (curry-0-1-set-in-shelf)
  
  ;; ボウル１をセットする ;;pap
  (curry-0-2-set-bowl-1)
  
  ;; 野菜をセットする？ ;; pap
  (curry-0-3-set-vegs)
  
  ;; 計量カップはここでセットする？ ;; pap
  (curry-0-4-set-mcup)
  
  ;; コンロの前まで移動する ;; move
  (curry-0-5-move-to-stove)
  
  ;; ボウル２・３をセットする ;; pap
  (curry-0-6-set-bowl-2-3)
  
  ;; キッチンの前に戻る ;; move
  (curry-0-7-move-to-kitchen)
  
  ;; まな板をセットする ;;pap ;;少し特殊
  (curry-0-8-set-board)
  
  ;; 道具３つをセットする ;;pap
  (curry-0-9-set-tools-on-table)
  )


(defun curry-0-1-set-in-shelf ()  ;; 棚の中にヘラとおたまをセットする
  
  ;; 棚の扉を開ける
  (curry-0-1-1-open-shelf)
  
  ;; ヘラをセットする
  (curry-0-1-2-set-spatula)
  
  ;; おたまをセットする
  (curry-0-1-3-set-ladle)

  ;; 棚の扉を閉める
  (curry-0-1-4-close-shelf)
  )


;; ボウル１をセットする
(defun curry-0-2-set-bowl-1 ()
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  ;; (update-pos)
  ;; (now-set-1-model-rarm-with-dialogue)
  
  )

;; 野菜をセットする？
(defun curry-0-3-set-vegs ()  
  ;; じゃがいもをセットする

  ;; 人参をセットする

  ;; たまねぎをセットする
  )

;; 計量カップはここでセットする？
(defun curry-0-4-set-mcup ()
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  ;; (update-pos)
  ;; (now-set-mcup-with-dialogue)

  )

;; コンロの前まで移動する ;; transition
(defun curry-0-5-move-to-stove ()
  (move-to-stove-with-speech-before) ;; primitive
  )

;; ボウル２・３をセットする
(defun curry-0-6-set-bowl-2-3 ()
  ;; ボウル２をセットする

  ;; ボウル３をセットする
  )

;; キッチンの前に戻る ;; transition
(defun curry-0-7-move-to-kitchen ()
  (move-to-kitchen-with-speech-after)  
  )

;; まな板をセットする
(defun curry-0-8-set-board ()
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cutting-board-codes.l")
  ;; (update-pos)
  ;; (now-set-board-with-dialogue)
  )

;; 道具３つをセットする
(defun curry-0-9-set-tools-on-table ()
  ;; 包丁をセットする
  
  ;; ピーラーをセットする
  
  ;; じゃがいもピーラーをセットする
  )



;; 棚の扉を開ける
(defun curry-0-1-1-open-shelf ()
  
  )

;; ヘラをセットする
(defun curry-0-1-2-set-spatula ()

  
  )

;; おたまをセットする
(defun curry-0-1-3-set-ladle ()
  )

;; 棚の扉を閉める
(defun curry-0-1-4-close-shelf ()
  
  )
