;; 炒める調理の準備のプログラムをプリミティブの組み合わせ等を書いていって整理していく感じ．

(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/primitive-cook/prmitives-funcs.l")

(defun curry-4 () ;; 準備をする．  
  
  ;; ヘラとおたまを棚から取り出す ;;特殊
  (curry-4-1-set-from-shelf)
  
  ;; コンロの前まで移動する ;;move
  (curry-4-2-move-to-stove)
  
  ;; 油を掛ける ;;特殊？
  (curry-4-3-add-oil)
  )


;; ヘラとおたまを棚から取り出す
(defun curry-4-1-set-from-shelf ()
  )

;; コンロの前まで移動する
(defun curry-4-2-move-to-stove ()
  )

;; 油を掛ける
(defun curry-4-3-add-oil ()  
  )

