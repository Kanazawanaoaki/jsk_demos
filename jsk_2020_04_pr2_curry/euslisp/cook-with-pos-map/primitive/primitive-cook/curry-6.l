;; 肉を炒める調理のプログラムをプリミティブの組み合わせ等を書いていって整理していく感じ．

(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/primitive-cook/prmitives-funcs.l")

(defun curry-6 () ;; 準備をする．  

  ;; 肉を鍋に移す
  (curry-6-1-transfer-to-pot)
  
  ;; 火を着ける
  (curry-6-2-set-fire)
  
  ;; 炒める
  (curry-6-3-stir-fry)
  
  ;; 火を止める
  (curry-6-4-turn-off-fire)

  ;; ヘラを置く
  (curry-6-5-put-spatula)
  )

;; 肉を鍋に移す
(defun curry-6-1-transfer-to-pot ()
  )

;; 火を着ける
(defun curry-6-2-set-fire ()
  )

;; 炒める
(defun curry-6-3-stir-fry ()
  )

;; 火を止める
(defun curry-6-4-turn-off-fire ()
  )

;; ヘラを置く
(defun curry-6-5-put-spatula ()
  )

