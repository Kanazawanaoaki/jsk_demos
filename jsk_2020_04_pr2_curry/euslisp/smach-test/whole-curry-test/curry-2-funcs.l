(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )

(defun curry-2-1 ()
  (unix:sleep 1)
  (warn "じゃがいもを掴む ~%")
  )

(defun curry-2-2 ()
  (unix:sleep 1)
  (warn "シンクの前に移動する ~%")
  )

(defun curry-2-3 ()
  (unix:sleep 1)
  (warn "じゃがいもを洗う ~%")
  )

(defun curry-2-4 ()
  (unix:sleep 1)
  (warn "キッチンの前に戻る ~%")
  )

(defun curry-2-5 ()
  (unix:sleep 1)
  (warn "じゃがいもをまな板に置く ~%")
  )

(defun curry-2-6 ()
  (unix:sleep 1)
  (warn "じゃがいもピーラーを掴む ~%")
  )

(defun curry-2-7 ()
  (unix:sleep 1)
  (warn "じゃがいもの皮剥き ~%")
  )

(defun curry-2-8 ()
  (unix:sleep 1)
  (warn "じゃがいもピーラーを置く，包丁を掴む ~%")
  )

(defun curry-2-9 ()
  (unix:sleep 1)
  (warn "じゃがいも切断 ~%")
  )

(defun curry-2-10 ()
  (unix:sleep 1)
  (warn "包丁を置く ~%")
  )

(defun curry-2-11 ()
  (unix:sleep 1)
  (warn "ボウル１に移す動作 ~%")
  )


