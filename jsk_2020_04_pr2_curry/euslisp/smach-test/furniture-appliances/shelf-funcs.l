(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")

(defun close ()
  (unix:sleep 1)
  (warn "電子レンジの認識 ~%")
  )

(defun open ()
  (unix:sleep 1)
  (warn "電子レンジの扉を開ける ~%")
  )

