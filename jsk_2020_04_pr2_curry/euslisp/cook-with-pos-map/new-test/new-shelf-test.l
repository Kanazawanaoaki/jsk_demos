(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")

(warn "please run (open-test) ~%")

(defun open-test ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)

  (open-shelf-set)
  (open-shelf)
  (after-open)

  (warn "please run (close-test) ~%")
  )

(defun close-test ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  (update-pos)

  (close-shelf-set)
  (close-shelf)
  (after-close)

  (warn "please run (reset-rarm) ~%")
  
  )
