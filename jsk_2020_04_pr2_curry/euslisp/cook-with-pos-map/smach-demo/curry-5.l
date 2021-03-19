;; たまねぎを炒める調理のプログラムをプリミティブの組み合わせ等を書いていって整理していく感じ．

(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/primitive-cook/prmitives-funcs.l")

(defun curry-5 () ;; 準備をする．  

  ;; ヘラを掴む
  ;; TODO これを追加する必要がある．
  
  ;; 火を着ける
  (curry-5-1-set-fire)
  
  ;; 炒める
  (curry-5-2-stir-fry)
  
  ;; 火を止める
  (curry-5-3-turn-off-fire)  
  )


;; ヘラを掴む
;; (defun grasp-spatula ()
  
;;   )

;; 火を着ける
(defun curry-5-1-set-fire ()
  ;; 火を着ける?　TODO ここをsmachでさらに失敗こみで書く．
  
  )

;; 炒める
(defun curry-5-2-stir-fry ()
  )

;; 火を止める
(defun curry-5-3-turn-off-fire ()
  )

