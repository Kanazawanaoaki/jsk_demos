(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )

(defun curry-1-1 ()
  (unix:sleep 1)
  (warn "人参を掴む ~%")
  )

(defun curry-1-2 ()
  (unix:sleep 1)
  (warn "シンクの前に移動する ~%")
  )

(defun curry-1-3 ()
  (unix:sleep 1)
  (warn "人参を洗う ~%")
  )

(defun curry-1-4 ()
  (unix:sleep 1)
  (warn "キッチンの前に戻る ~%")
  )

(defun curry-1-5 ()
  (unix:sleep 1)
  (warn "人参をまな板に置く ~%")
  )

(defun curry-1-6 ()
  (unix:sleep 1)
  (warn "ピーラーを掴む ~%")
  )

(defun curry-1-7 ()
  (unix:sleep 1)
  (warn "人参の皮剥き ~%")
  )

(defun curry-1-8 ()
  (unix:sleep 1)
  (warn "ピーラーを置く，包丁を掴む ~%")
  )

(defun curry-1-9 ()
  (unix:sleep 1)
  (warn "人参切断 ~%")
  )

(defun curry-1-10 ()
  (unix:sleep 1)
  (warn "包丁を置く ~%")
  )

(defun curry-1-11 ()
  (unix:sleep 1)
  (warn "ボウル１に移す動作 ~%")
  )


