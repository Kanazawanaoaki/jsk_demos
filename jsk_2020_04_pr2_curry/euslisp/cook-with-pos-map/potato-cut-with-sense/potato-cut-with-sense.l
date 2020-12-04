(warn "please run (before-cut-potato) ~%")

(defun before-cut-potato ()
  ;; 包丁を掴む
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (grasp-knife)

  (warn "please run (cut-potato) ~%")
  )

(defun cut-potato ()
  ;; じゃがいもを半分に切る．
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/potato-cut-with-sense/potato-cut-half.l")
  (update-pos)
  (now-cut-with-sense)
  
  ;; 右半分を立てる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cut-potato-codes.l")
  (update-pos)
  (now-right-set)
  
  ;; 右半分を回転させる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cut-potato-codes.l")
  (update-pos)
  (now-right-rotate)
  
  ;; 右半分を切る．
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/potato-cut-with-sense/potato-cut-right.l")
  (update-pos)
  (now-cut-with-sense)

  ;; 左半分を回転させる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/cut-potato-codes.l")
  (update-pos)
  (now-left-rotate)
  
  ;; 左半分を切る．
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/potato-cut-with-sense/potato-cut-left.l")
  (update-pos)
  (now-cut-with-sense)
  )

(defun after-cut-potato ()
  ;; 包丁を置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (put-knife)
  
  ;; ボウル１に移す動作
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/transfer-vegs/transfer-test-with-rec.l")
  (now-transfer-bowl-1)
  )
