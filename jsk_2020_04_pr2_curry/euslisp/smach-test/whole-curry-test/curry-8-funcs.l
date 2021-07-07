(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )

(defun curry-8-1 ()
  (unix:sleep 1)
  (warn "火を着ける ~%")
  )

(defun curry-8-2 ()
  (unix:sleep 1)
  (warn "沸騰させる ~%")
  )

(defun curry-8-3 ()
  (unix:sleep 1)
  (warn "火を調整する ~%")
  )

(defun curry-8-4 ()
  (unix:sleep 1)
  (warn "煮込む ~%")
  )

(defun curry-8-5 ()
  (unix:sleep 1)
  (warn "火を消す ~%")
  )

