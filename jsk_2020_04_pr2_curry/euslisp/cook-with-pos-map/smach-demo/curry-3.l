;; たまねぎの下ごしらえのプログラムをプリミティブの組み合わせ等を書いていって整理していく感じ．

(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/primitive-cook/prmitives-funcs.l")

(defun curry-3 () ;; 準備をする．  
  
  ;; たまねぎを掴む ;;pap
  (curry-3-1-grasp-onion)
  
  ;; シンクの前に移動する ;;move
  (curry-3-2-move-to-sink)
  
  ;; たまねぎを洗う ;;特殊
  (curry-3-3-wash-onion)
  
  ;; キッチンの前に戻る ;;move
  (curry-3-4-move-to-kitchen)
  
  ;; たまねぎをまな板に置く ;;pap
  (curry-3-5-put-onion-on-board)
  
  ;; 包丁を掴む ;;pap
  (curry-3-6-grasp-knife)
  
  ;; たまねぎ切断 ;;特殊
  (curry-3-7-cut-onion)
  
  ;; 包丁を置く ;;pap
  (curry-3-8-put-knife)
  
  ;; 鍋に移す動作 ;;特殊
  (curry-3-9-transfer-to-pot)
  )


;; たまねぎを掴む
(defun curry-3-1-grasp-onion ()
  )

;; シンクの前に移動する
(defun curry-3-2-move-to-sink ()
  )

;; たまねぎを洗う
(defun curry-3-3-wash-onion ()
  )

;; キッチンの前に戻る
(defun curry-3-4-move-to-kitchen ()
  )

;; たまねぎをまな板に置く
(defun curry-3-5-put-onion-on-board ()
  )

;; 包丁を掴む
(defun curry-3-6-grasp-knife ()
  )

;; たまねぎ切断
(defun curry-3-7-cut-onion ()
  )

;; 包丁を置く
(defun curry-3-8-put-knife ()
  )

;; 鍋に移す動作
(defun curry-3-9-transfer-to-pot ()  
  )

