(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")

(defun curry-0 ()
  (unix:sleep 1)
  (warn "調理の準備 ~%")
  (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-0-smach.l")
  (smach-demo-0)
  )

(defun curry-1 ()
  (unix:sleep 1)
  (warn "人参の下ごしらえ ~%")
  )

(defun curry-2 ()
  (unix:sleep 1)
  (warn "じゃがいもの下ごしらえ ~%")
  )

(defun curry-3 ()
  (unix:sleep 1)
  (warn "たまねぎの下ごしらえ ~%")
  )

(defun curry-4 ()
  (unix:sleep 1)
  (warn "炒める調理の準備 ~%")
  )

(defun curry-5 ()
  (unix:sleep 1)
  (warn "たまねぎを炒める調理 ~%")
  )

(defun curry-6 ()
  (unix:sleep 1)
  (warn "肉を炒める調理 ~%")
  )

(defun curry-7 ()
  (unix:sleep 1)
  (warn "煮込む調理の準備 ~%")
  )

(defun curry-8 ()
  (unix:sleep 1)
  (warn "煮込む調理 ~%")
  )

(defun curry-9 ()
  (unix:sleep 1)
  (warn "仕上げ ~%")
  )

