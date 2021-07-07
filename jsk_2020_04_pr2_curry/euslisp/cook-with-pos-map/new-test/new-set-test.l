(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")

(warn "please run (set-bowls) ~%")

(defun set-bowls ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")
  (update-pos)
  (now-set-1)
  (now-set-2)
  
  (warn "please run (set-tools) ~%")
  )

(defun set-tools ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  (now-set-tools) ;; 包丁，ピーラー，じゃがいもピーラーをセットする．
  (reset-rarm)
  
  (warn "please run (switch-bowl) ~%")
  )

(defun switch-bowl ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")
  (update-pos)
  (switch-bowl-2)  
  
  (warn "please run (set-pot-tools) ~%")
  )

(defun set-pot-tools ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  
  (now-set-spatula-1)
  (now-set-ladle-1)
  
  (reset-rarm)
  
  (warn "please run (spatula-test) ~%")
  )

(defun spatula-test ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)

  (grasp-spatula)
  (spatula-mix-test)
  (put-spatula-1)

  (warn "please run (ladle-test) ~%")
  )

(defun ladle-test ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)

  (grasp-ladle)
  (ladle-mix-test)
  (put-ladle-1)  
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

(defun set-all ()
  (set-bowls)
  (set-tools)
  (switch-bowl)
  (set-pot-tools)
  )

(defun mix-test ()
  (spatula-test)
  (ladle-test)
  )
