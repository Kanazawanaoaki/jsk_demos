;; 初期化
(if (not (boundp '*pr2*))
    (progn
      (load "package://pr2eus/pr2-interface.l")
      (pr2-init)
      ))

(objects (list *pr2*))

(warn "please run (potato-peel-all) ~%")

(defun potato-peel-all ()
  ;; じゃがいもピーラーをつかむ
  (load "tool-change/grasp-potato-peeler.l")
  (grasp-potato-peeler)

  ;; じゃがいもの皮を剥く．
  (load "rotate-peel-test/potato-peel-rotate-with-rec-tmp-with-sense-test-two.l")
  (now-peel)

  ;; じゃがいもを回転させる．
  (load "rotate-peel-test/potato-rotate-with-rec-tmp.l")
  (now-rotate)

  ;; じゃがいもの皮を剥く．
  (load "rotate-peel-test/potato-peel-rotate-with-rec-tmp-with-sense-test-two.l")
  (now-peel)

  (warn "please run (potato-cut-all) ~%")
  )

(defun potato-cut-all ()
  ;; じゃがいもピーラーから包丁に持ち替える．
  (load "tool-change/potato-peeler-to-knife.l")
  (put-potato-peeler)
  (grasp-knife)

  ;; じゃがいもを半分に切る．
  (load "cut-stable/potato-cut-half-with-rec.l")
  (now-cut)

  ;; 右半分を立てる．
  (load "cut-stable/potato-half-right-set-with-rec.l")
  (now-set)

  ;; 右半分を回転させる．
  (load "cut-stable/potato-half-right-rotate-with-rec.l")
  (now-rotate)

  ;; 右半分を切る．
  (load "cut-stable/potato-cut-right-quarter-box-with-rec.l")
  (now-cut)

  ;; 左半分を回転させる．
  (load "cut-stable/potato-half-left-rotate-with-rec.l")
  (now-rotate)

  ;; 左半分を切る．
  (load "cut-stable/potato-cut-left-quarter-box-with-rec.l")
  (now-cut)
  
  ;; 包丁を置く
  (load "tool-change/put-knife.l")
  (put-knife)

  ;; 容器に移す．
  (load "transfer-vegs/transfer-test-with-rec.l")
  (now-transfer)

  (warn "please run (carrot-peel-all) ~%")
  )

(defun carrot-peel-all ()
  ;; ピーラーを持つ．
  (load "tool-change/grasp-peeler.l")
  (grasp-peeler)

  ;; 人参の皮を剥く．
  (load "rotate-peel-test/carrot-peel-rotate-with-rec-tmp-with-sense-test-two.l")
  (now-peel)

  ;; 人参を回転させる．  
  (load "rotate-peel-test/carrot-rotate-with-rec-tmp.l")
  (now-rotate)

  ;; 人参の皮を剥く．
  (load "rotate-peel-test/carrot-peel-rotate-with-rec-tmp-with-sense-test-two.l")
  (now-peel)

  (warn "please run (carrot-cut-all) ~%")
  )

(defun carrot-cut-all ()
  ;; ピーラーから包丁に持ち替える．
  (load "tool-change/peeler-to-knife.l")
  (put-peeler)
  (grasp-knife)

  ;; 人参を切る．
  (load "cut-stable/potato-cut-half-with-rec.l")
  (now-cut)

  ;; 包丁を置く
  (load "tool-change/put-knife.l")
  (put-knife)

  ;; 容器に移す．
  (load "transfer-vegs/transfer-test-with-rec.l")
  (now-transfer)

  (warn "please run (grasp-all) ~%")
  )

(defun grasp-all ()
  ;; 容器を掴む．
  (load "transfer-vegs/transfer-test-with-rec.l")
  (now-transfer)

  ;; 容器を掴んで移動する．
  (load "transfer-vegs/grasp-cup.l")
  (now-micro)
  
  (warn "please run (micro-all) ~%")
  )

(defun micro-all ()
  (require :pr2-microwave-interface "package://microwave_pr2_201710/euslisp/lib/pr2-microwave-interface.l")

  (setq *pmi* (instance pr2-microwave-interface :init))
  (send *pmi* :kanazawa-pose)
  (send *pmi* :update-microwave-pose)

  ;; put object in microwave
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-put-object)
  (send *pmi* :close-microwave)

  ;; push button
  (send *pmi* :push-500w-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-start-button)
  
  ;; wait for heating
  (unix::sleep (* 3 60))

  ;; take object from microwave
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-take-object)
  (send *pmi* :close-microwave)

  (warn "please run (solt-all) ~%")
  )


