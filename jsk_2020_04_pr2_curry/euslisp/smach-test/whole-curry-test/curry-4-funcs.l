(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )

(defun curry-4-1 ()
  (unix:sleep 1)
  (warn "ヘラとおたまを棚から取り出す ~%")
  )

(defun curry-4-2 ()
  (unix:sleep 1)
  (warn "コンロの前まで移動する ~%")
  )

(defun curry-4-3 ()
  (unix:sleep 1)
  (warn "油を掛ける ~%")
  )

