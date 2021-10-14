(defun arg-test (slide-length &key (rotate-flag t) (arm :rarm) (times 600) (trans (float-vector 0 -10 -3)) (w-thre 11) (axis :x))
  (if (equal arm :larm)
      (format t "arm is :larm ~%")
    (progn
      (if (equal arm :rarm)
          (format t "arm is :rarm ~%")
        (format t "arm is hoge ~%")
        )
      ))
  )

(warn "please run (arg-test 10 :arm :larm) ~%")


(defun cond-test (num)
  (cond
   ((equal num 10)
    (format t "num is 10 ~%"))
   ((equal num 1)
    (format t "num is 1 ~%")
    (format t "num is not 10 ~%")
    )
   ((equal num 0)
    (progn
      (format t "num is 0 ~%")
      (format t "num is not 10 ~%")
      (format t "num is not 1 ~%")
      )
    )
   )
  )
