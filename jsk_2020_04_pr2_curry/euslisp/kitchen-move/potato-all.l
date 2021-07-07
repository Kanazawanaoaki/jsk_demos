;; 初期化
(if (not (boundp '*pr2*))
    (progn
      (load "package://pr2eus/pr2-interface.l")
      (pr2-init)
      ))

(objects (list *pr2*))

(warn "please run (potato-peel-all) ~%")
(warn "please run (potato-cut-all) ~%")
(warn "please run (potato-all) ~%")
(warn "or you can run (potato-cut-with-sense) ~%")

(defun potato-peel-all ()
  ;; じゃがいもピーラーをつかむ
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/tool-change/grasp-potato-peeler.l")
  (grasp-potato-peeler)

  ;; じゃがいもの皮を剥く．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/potato-peel-rotate-with-rec-tmp-with-sense-test-two.l")
  (now-peel)
  
  ;; じゃがいもを回転させる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/potato-rotate-with-rec-tmp.l")
  (now-rotate)
  
  ;; じゃがいもの皮を剥く．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/potato-peel-rotate-with-rec-tmp-with-sense-test-two.l")
  (now-peel)
  
  ;; じゃがいもピーラーを置く．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/tool-change/put-potato-peeler.l")
  (put-potato-peeler)

  (warn "please run (potato-cut-all) or (potato-cut-with-sense)~%")
  )

(defun potato-cut-all ()
  ;; 包丁を持つ．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/tool-change/grasp-knife.l")
  (grasp-knife)

  ;; じゃがいもを半分に切る．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-cut-half-with-rec.l")
  (now-cut)
  
  ;; 右半分を立てる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-half-right-set-with-rec.l")
  (now-set)

  ;; 右半分を回転させる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-half-right-rotate-with-rec.l")
  (now-rotate)

  ;; 右半分を切る．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-cut-right-quarter-box-with-rec.l")
  (now-cut)

  ;; 左半分を回転させる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-half-left-rotate-with-rec.l")
  (now-rotate)

  ;; 左半分を切る．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-cut-left-quarter-box-with-rec.l")
  (now-cut)
  
  ;; 包丁を置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/tool-change/put-knife.l")
  (put-knife)

  (warn "please run (potato-transfer) ~%")
  )

(defun potato-transfer ()
  ;; 容器に移す．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/transfer-vegs/transfer-test-with-rec.l")
  (now-transfer)
  )

(defun potato-all ()
  (potato-peel-all)
  (potato-cut-all)
  (potato-transfer)
  )

(defun potato-cut-with-sense ()
  ;; 包丁を持つ．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/tool-change/grasp-knife.l")
  (grasp-knife)

  ;; じゃがいもを半分に切る．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-cut-half-with-sense-with-rec.l")
  (now-cut-with-sense)

  ;; 右半分を立てる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-half-right-set-with-rec.l")
  (now-set)
  
  ;; 右半分を回転させる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-half-right-rotate-with-rec.l")
  (now-rotate)

  ;; 右半分を切る．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-cut-quarter-box-right-with-rec.l")
  (now-cut-with-sense)

  ;; 左半分を回転させる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-half-left-rotate-with-rec.l")
  (now-rotate)

  ;; 左半分を切る．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-cut-quarter-box-left-with-rec.l")
  (now-cut-with-sense)
  
  ;; 包丁を置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/tool-change/put-knife.l")
  (put-knife)

  (warn "please run (potato-transfer) ~%")
  )

(defun potato-cut-with-sense-2 ()
  ;; 包丁を持つ．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/tool-change/grasp-knife.l")
  ;; (load "tool-change/grasp-knife.l")
  (grasp-knife)

  ;; じゃがいもを半分に切る．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-cut-half-with-sense-with-rec.l")
  ;; (load "cut-stable/potato-cut-half-with-sense-with-rec.l")
  (now-cut-with-sense-2)
  
  ;; 右半分を回転させる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-half-right-rotate-with-rec.l")
  ;; (load "cut-stable/potato-half-right-rotate-with-rec.l")
  (now-rotate)

  ;; 右半分を切る．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-cut-quarter-box-right-with-rec.l")
  ;; (load "cut-stable/potato-cut-quarter-box-right-with-rec.l")
  (now-cut-with-sense-2)

  ;; 左半分を回転させる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-half-left-rotate-with-rec.l")
  ;; (load "cut-stable/potato-half-left-rotate-with-rec.l")
  (now-rotate)

  ;; 左半分を切る．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-cut-quarter-box-left-with-rec.l")
  ;; (load "cut-stable/potato-cut-quarter-box-left-with-rec.l")
  (now-cut-with-sense-2)
  
  ;; 包丁を置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/tool-change/put-knife.l")
  ;; (load "tool-change/put-knife.l")
  (put-knife)

  (warn "please run (potato-transfer) ~%")
  )



(defun potato-peel-and-cut-with-sense ()
  (potato-peel-all)
  (potato-cut-with-sense)
  )


(defun tmp-test ()
  ;; 左半分を回転させる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-half-left-rotate-with-rec.l")
  ;; (load "cut-stable/potato-half-left-rotate-with-rec.l")
  (now-rotate)

  ;; 左半分を切る．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/potato-cut-quarter-box-left-with-rec.l")
  ;; (load "cut-stable/potato-cut-quarter-box-left-with-rec.l")
  (now-cut-with-sense)
  
  ;; 包丁を置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/tool-change/put-knife.l")
  ;; (load "tool-change/put-knife.l")
  (put-knife)
  )
