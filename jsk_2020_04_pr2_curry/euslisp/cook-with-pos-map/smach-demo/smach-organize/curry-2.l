;; じゃがいもの下ごしらえのプログラムをプリミティブの組み合わせ等を書いていって整理していく感じ．

(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/primitive-cook/prmitives-funcs.l")

(defun curry-2 () ;; 準備をする．  
  
  ;; じゃがいもを掴む ;;pap
  (curry-2-1-grasp-potato)
  
  ;; シンクの前に移動する ;;move
  (curry-2-2-move-to-sink)
  
  ;; じゃがいもを洗う ;;特殊
  (curry-2-3-wash-potato)
  
  ;; キッチンの前に戻る ;;move
  (curry-2-4-move-to-kitchen)
  
  ;; じゃがいもをまな板に置く ;;pap
  (curry-2-5-put-potato-on-board)
  
  ;; じゃがいもピーラーを掴む ;;pap
  (curry-2-6-grasp-potato-peeler)
  
  ;; じゃがいもの皮剥き ;;特殊
  (curry-2-7-peel-potato)
  
  ;; じゃがいもピーラーを置く，包丁を掴む ;;pap
  (curry-2-8-replace-tool)
  
  ;; じゃがいも切断 ;;特殊
  (curry-2-9-cut-potato)

  ;; 包丁を置く ;;pap
  (curry-2-10-put-knife)
  
  ;; ボウル１に移す動作 ;;特殊
  (curry-2-11-transfer-to-bowl-1)  
  )


;; じゃがいもを掴む
(defun curry-2-1-grasp-potato ()
  
  )

;; シンクの前に移動する
(defun curry-2-2-move-to-sink ()
  )

;; じゃがいもを洗う
(defun curry-2-3-wash-potato ()
  )

;; キッチンの前に戻る
(defun curry-2-4-move-to-kitchen ()
  )

;; じゃがいもをまな板に置く
(defun curry-2-5-put-potato-on-board ()
  )

;; じゃがいもピーラーを掴む
(defun curry-2-6-grasp-peeler ()
  )

;; じゃがいもの皮剥き
(defun curry-2-7-peel-potato ()
  )

;; じゃがいもピーラーを置く，包丁を掴む
(defun curry-2-8-replace-tool ()
  )

;; じゃがいも切断
(defun curry-2-9-cut-potato ()
  )

;; 包丁を置く
(defun curry-2-10-put-knife ()
  )

;; ボウル１に移す動作
(defun curry-2-11-transfer-to-bowl-1 ()  
  )

