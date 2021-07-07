(load "package://jsk_2020_04_pr2_curry/euslisp/model/tool-use-codes.l")

(warn "please run (set-tools) or (set-bowls) or (set-shelf)")

(defun set-tools ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/tool-use-codes.l")
  (update-pos)
  (now-set-tools) ;; 包丁，ピーラー，じゃがいもピーラーをセットする．
  )

(defun set-shelf ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/tool-use-codes.l")
  (update-pos)  
  (set-in-shelf);; 棚の中におたまとヘラをセットする．
  )


(defun set-bowls ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/bowl-use-codes.l")
  (update-pos)
  (now-set-all);; ボウル１〜４をセット
  )
    
