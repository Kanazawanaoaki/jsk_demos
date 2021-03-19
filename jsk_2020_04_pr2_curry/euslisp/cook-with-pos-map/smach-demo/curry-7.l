;; 煮込む調理の準備のプログラムをプリミティブの組み合わせ等を書いていって整理していく感じ．

(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/primitive-cook/prmitives-funcs.l")

(defun curry-7 () ;; 準備をする．  
  
  ;; キッチン前に移動する
  (curry-7-1-move-to-kitchen)
  
  ;; 野菜を鍋に移す
  (curry-7-2-transfer-to-pot)
  
  ;; 計量カップを掴む
  (curry-7-3-grasp-mcup)
  
  ;; 水を汲む
  (curry-7-4-fetch-water)
  
  ;; 計量カップを置く
  (curry-7-5-put-mcup)
  )

;; キッチン前に移動する
(defun curry-7-1-move-to-kitchen ()
  )

;; 野菜を鍋に移す
(defun curry-7-2-transfer-to-pot ()
  )

;; 計量カップを掴む
(defun curry-7-3-grasp-mcup ()
  )

;; 水を汲む
(defun curry-7-4-fetch-water ()
  ;; 水道まで移動する

  ;; 水を汲む

  ;; キッチンに移動する

  ;; 水を注ぐ

  ;; 水汲みの状態を確認する

  ;; ループする
  )

;; 計量カップを置く
(defun curry-7-5-put-mcup ()
  )

