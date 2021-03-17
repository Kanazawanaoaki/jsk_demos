;; 仕上げのプログラムをプリミティブの組み合わせ等を書いていって整理していく感じ．

(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/primitive-cook/prmitives-funcs.l")

(defun curry-9 () ;; 仕上げ
  
  ;; カレールーを鍋に入れる
  (curry-9-1-transfer-to-pot)
  
  ;; ヘラを置く
  (curry-9-2-put-spatula)
  
  ;; おたまを掴んで火を着ける
  (curry-9-3-set-fire)
  
  ;; 煮込む
  (curry-9-4-stew)
  
  ;; 火を消す
  (curry-9-5-turn-off-fire)
  )

;; 火を着ける
(defun curry-9-1-transfer-to-pot ()
  )

;; 沸騰させる
(defun curry-9-2-put-spatula ()
  )

;; 火を調整する
(defun curry-9-3-set-fire ()
  )

;; 煮込む
(defun curry-9-4-stew ()
  )

;; 火を消す
(defun curry-9-5-turn-off-fire ()
  )

