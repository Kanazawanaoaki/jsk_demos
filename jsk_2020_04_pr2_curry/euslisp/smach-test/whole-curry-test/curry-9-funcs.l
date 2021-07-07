(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )

(defun curry-9-1 ()
  (unix:sleep 1)
  (warn "カレールーを鍋に入れる ~%")
  )

(defun curry-9-2 ()
  (unix:sleep 1)
  (warn "ヘラを置く ~%")
  )

(defun curry-9-3 ()
  (unix:sleep 1)
  (warn "おたまを掴んで火を着ける ~%")
  )

(defun curry-9-4 ()
  (unix:sleep 1)
  (warn "煮込む ~%")
  )

(defun curry-9-5 ()
  (unix:sleep 1)
  (warn "火を消す ~%")
  )

