(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")

(warn "please run (set-pot-tools) ~%")

(defun set-pot-tools ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)
  
  (now-set-spatula-1)
  (now-set-ladle-1)

  (warn "please run (spatula-test) ~%")
  )

(defun spatula-test ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)

  (spatula-mix-test)
  (put-spatula-1)

  (warn "please run (ladle-test) ~%")
  )

(defun ladle-test ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  (update-pos)

  (ladle-mix-test)
  (put-ladle-1)  
  )


