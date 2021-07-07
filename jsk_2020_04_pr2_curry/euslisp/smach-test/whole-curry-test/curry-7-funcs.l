(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )

(defun curry-7-1 ()
  (unix:sleep 1)
  (warn "キッチン前に移動する ~%")
  )

(defun curry-7-2 ()
  (unix:sleep 1)
  (warn "野菜を鍋に移す ~%")
  )

(defun curry-7-3 ()
  (unix:sleep 1)
  (warn "計量カップを掴む ~%")
  )

(defun curry-7-4 ()
  (unix:sleep 1)
  (warn "水を汲む ~%")
  )

(defun curry-7-5 ()
  (unix:sleep 1)
  (warn "計量カップを置く ~%")
  )

