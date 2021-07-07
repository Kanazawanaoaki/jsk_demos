(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")

(defun curry-0-1 ()
  (unix:sleep 1)
  (warn "棚の中にヘラとおたまをセットする ~%")
  )

(defun curry-0-2 ()
  (unix:sleep 1)
  (warn "ボウル１をセットする ~%")
  )

(defun curry-0-3 ()
  (unix:sleep 1)
  (warn "野菜をセットする ~%")
  )

(defun curry-0-4 ()
  (unix:sleep 1)
  (warn "計量カップはここでセットする~%")
  )

(defun curry-0-5 ()
  (unix:sleep 1)
  (warn "コンロの前まで移動する ~%")
  )

(defun curry-0-6 ()
  (unix:sleep 1)
  (warn "ボウル２・３をセットする ~%")
  )

(defun curry-0-7 ()
  (unix:sleep 1)
  (warn "キッチンの前に戻る ~%")
  )

(defun curry-0-8 ()
  (unix:sleep 1)
  (warn "まな板をセットする ~%")
  )

(defun curry-0-9 ()
  (unix:sleep 1)
  (warn "道具３つをセットする~%")
  )

