(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )

(defun curry-0 ()
  (unix:sleep 1)
  (warn "調理の準備 ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-0-smach.l")
  ;; (smach-demo-0)
  )

(defun curry-1 ()
  (unix:sleep 1)
  (warn "人参の下ごしらえ ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-1-smach.l")
  ;; (smach-demo-1)
  )

(defun curry-2 ()
  (unix:sleep 1)
  (warn "じゃがいもの下ごしらえ ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-2-smach.l")
  ;; (smach-demo-2)
  )

(defun curry-3 ()
  (unix:sleep 1)
  (warn "たまねぎの下ごしらえ ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-3-smach.l")
  ;; (smach-demo-3)
  )

(defun curry-4 ()
  (unix:sleep 1)
  (warn "炒める調理の準備 ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-4-smach.l")
  ;; (smach-demo-4)
  )

(defun curry-5 ()
  (unix:sleep 1)
  (warn "たまねぎを炒める調理 ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-5-smach.l")
  ;; (smach-demo-5)
  )

(defun curry-6 ()
  (unix:sleep 1)
  (warn "肉を炒める調理 ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-6-smach.l")
  ;; (smach-demo-6)
  )

(defun curry-7 ()
  (unix:sleep 1)
  (warn "煮込む調理の準備 ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-7-smach.l")
  ;; (smach-demo-7)
  )

(defun curry-8 ()
  (unix:sleep 1)
  (warn "煮込む調理 ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-8-smach.l")
  ;; (smach-demo-8)
  )

(defun curry-9 ()
  (unix:sleep 1)
  (warn "仕上げ ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-9-smach.l")
  ;; (smach-demo-9)
  )



;; curry-0
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


;; curry-1
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


;; curry-2
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

