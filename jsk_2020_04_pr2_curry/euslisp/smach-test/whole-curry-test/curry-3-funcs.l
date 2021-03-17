(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")

(defun curry-3-1 ()
  (unix:sleep 1)
  (warn "たまねぎを掴む ~%")
  )

(defun curry-3-2 ()
  (unix:sleep 1)
  (warn "シンクの前に移動する ~%")
  )

(defun curry-3-3 ()
  (unix:sleep 1)
  (warn "たまねぎを洗う ~%")
  )

(defun curry-3-4 ()
  (unix:sleep 1)
  (warn "キッチンの前に戻る ~%")
  )

(defun curry-3-5 ()
  (unix:sleep 1)
  (warn "たまねぎをまな板に置く ~%")
  )

(defun curry-3-6 ()
  (unix:sleep 1)
  (warn "包丁を掴む ~%")
  )

(defun curry-3-7 ()
  (unix:sleep 1)
  (warn "たまねぎ切断 ~%")
  )

(defun curry-3-8 ()
  (unix:sleep 1)
  (warn "包丁を置く ~%")
  )

(defun curry-3-9 ()
  (unix:sleep 1)
  (warn "鍋に移す動作 ~%")
  )


