(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")

(defun curry-5-1 ()
  (unix:sleep 1)
  (warn "火を着ける ~%")
  )

(defun curry-5-2 ()
  (unix:sleep 1)
  (warn "炒める ~%")
  )

(defun curry-5-3 ()
  (unix:sleep 1)
  (warn "火を止める ~%")
  )

