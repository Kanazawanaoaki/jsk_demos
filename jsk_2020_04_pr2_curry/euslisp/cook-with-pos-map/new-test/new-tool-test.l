(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")

(warn "please run (set-tools) ~%")

(defun set-tools ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (now-set-tools) ;; 包丁，ピーラー，じゃがいもピーラーをセットする．

  (warn "please run (grasp-tools) ~%")
  )

(defun grasp-tools ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)

  (grasp-knife)
  (put-knife)

  (grasp-peeler)
  (put-peeler)

  (grasp-potato-peeler)
  (put-potato-peeler)
  )
