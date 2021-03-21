;; 煮込む調理のプログラムをプリミティブの組み合わせ等を書いていって整理していく感じ．

(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/primitive-cook/prmitives-funcs.l")

(defun curry-8 () ;; 準備をする．  
  
  ;; 火を着ける
  (curry-8-1-set-fire)
  
  ;; 沸騰させる
  (curry-8-2-boil)
  
  ;; 火を調整する
  (curry-8-3-adjust-fire)
  
  ;; 煮込む
  (curry-8-4-stew)
  
  ;; 火を消す
  (curry-8-5-turn-off-fire)
  )

;; 火を着ける
(defun curry-8-1-set-fire ()
  )

;; 沸騰させる
(defun curry-8-2-boil ()
  )

;; 火を調整する
(defun curry-8-3-adjust-fire ()
  )

;; 煮込む
(defun curry-8-4-stew ()
  )

;; 火を消す
(defun curry-8-5-turn-off-fire ()
  )

