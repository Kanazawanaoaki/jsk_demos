;; 初期化
(if (not (boundp '*pr2*))
    (progn
      (load "package://pr2eus/pr2-interface.l")
      (pr2-init)
      ))

(objects (list *pr2*))

(warn "please run (carrot-peel-all) ~%")
(warn "please run (carrot-cut-all) ~%")
(warn "please run (carrot-all) ~%")
(warn "please run (carrot-peel-and-cut) ~%")

(defun carrot-peel-all ()
  ;; ピーラーをつかむ
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/tool-change/grasp-peeler.l")
  ;; (load "tool-change/grasp-peeler.l")
  (grasp-peeler)
  
  ;; 人参の皮を剥く．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/carrot-peel-rotate-with-rec-tmp-with-sense-test-two.l")
  (now-peel)
  
  ;; 人参を回転させる．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/carrot-rotate-with-rec-tmp.l")
  (now-rotate)
  
  ;; 人参の皮を剥く．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/carrot-peel-rotate-with-rec-tmp-with-sense-test-two.l")
  (now-peel)
  
  ;; ピーラーを置く．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/tool-change/put-peeler.l")
  (put-peeler)
  
  (warn "please run (carrot-cut-all) ~%")
  )

(defun carrot-cut-all ()
  ;; 包丁を持つ．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/tool-change/grasp-knife.l")
  (grasp-knife)

  ;; 人参を切る．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/cut-stable/carrot-cut-test-with-sense-test-two-with-rec.l")
  (now-cut)
  
  ;; 包丁を置く
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/tool-change/put-knife.l")
  (put-knife)
  
  (warn "please run (carrot-transfer) ~%")
  )

(defun carrot-transfer ()
  ;; 容器に移す．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/transfer-vegs/transfer-test-with-rec.l")
  ;; (now-transfer)
  (now-transfer-bowl-1)
  )

(defun carrot-all ()
  (carrot-peel-all)
  (carrot-cut-all)
  (carrot-transfer)
  )

(defun carrot-peel-and-cut ()
  (carrot-peel-all)
  (carrot-cut-all)
  )

(defun tmp-test ()
  ;; 人参の皮を剥く．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/rotate-peel-test/carrot-peel-rotate-with-rec-tmp-with-sense-test-two.l")
  ;; (load "rotate-peel-test/carrot-peel-rotate-with-rec-tmp-with-sense-test-two.l")
  (now-peel)
  
  ;; ピーラーを置く．
  (load "package://jsk_2020_04_pr2_curry/euslisp/kitchen-move/tool-change/put-peeler.l")
  ;; (load "tool-change/put-peeler.l")
  (put-peeler)

  )
