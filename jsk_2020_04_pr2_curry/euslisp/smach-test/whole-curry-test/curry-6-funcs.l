(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )

(defun curry-6-1 ()
  (unix:sleep 1)
  (warn "肉を鍋に移す ~%")
  )

(defun curry-6-2 ()
  (unix:sleep 1)
  (warn "火を着ける ~%")
  )

(defun curry-6-3 ()
  (unix:sleep 1)
  (warn "炒める ~%")
  )

(defun curry-6-4 ()
  (unix:sleep 1)
  (warn "火を止める ~%")
  )

(defun curry-6-5 ()
  (unix:sleep 1)
  (warn "ヘラを置く ~%")
  )

