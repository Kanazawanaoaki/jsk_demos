;; 人参の下ごしらえのプログラムをプリミティブの組み合わせ等を書いていって整理していく感じ．

(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/primitive-cook/prmitives-funcs.l")

(defun curry-1 () ;; 準備をする．  
  
  ;; 人参を掴む
  (curry-1-1-grasp-carrot)
  
  ;; シンクの前に移動する
  (curry-1-2-move-to-sink)
  
  ;; 人参を洗う
  (curry-1-3-wash-carrot)
  
  ;; キッチンの前に戻る
  (curry-1-4-move-to-kitchen)
  
  ;; 人参をまな板に置く
  (curry-1-5-put-carrot-on-board)
  
  ;; ピーラーを掴む
  (curry-1-6-grasp-peeler)
  
  ;; 人参の皮剥き
  (curry-1-7-peel-carrot)
  
  ;; ピーラーを置く，包丁を掴む
  (curry-1-8-replace-tool)
  
  ;; 人参切断
  (curry-1-9-cut-carrot)

  ;; 包丁を置く
  (curry-1-10-put-knife)
  
  ;; ボウル１に移す動作
  (curry-1-11-transfer-to-bowl-1)  
  )


;; 人参を掴む
(defun curry-1-1-grasp-carrot ()
  )

;; シンクの前に移動する
(defun curry-1-2-move-to-sink ()
  )

;; 人参を洗う
(defun curry-1-3-wash-carrot ()
  )

;; キッチンの前に戻る
(defun curry-1-4-move-to-kitchen ()
  )

;; 人参をまな板に置く
(defun curry-1-5-put-carrot-on-board ()
  )

;; ピーラーを掴む
(defun curry-1-6-grasp-peeler ()
  )

;; 人参の皮剥き
(defun curry-1-7-peel-carrot ()
  )

;; ピーラーを置く，包丁を掴む
(defun curry-1-8-replace-tool ()
  )

;; 人参切断
(defun curry-1-9-cut-carrot ()
  )

;; 包丁を置く
(defun curry-1-10-put-knife ()
  )

;; ボウル１に移す動作
(defun curry-1-11-transfer-to-bowl-1 ()  
  )

