(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )

;; sleepする時間
;; (setq *s-time* 1000)
(setq *s-time* 0)

(defun curry-0 ()
  (unix:usleep *s-time*)
  (warn "調理の準備 ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-0-smach.l")
  ;; (smach-demo-0)
  )

(defun curry-1 ()
  (unix:usleep *s-time*)
  (warn "人参の下ごしらえ ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-1-smach.l")
  ;; (smach-demo-1)
  )

(defun curry-2 ()
  (unix:usleep *s-time*)
  (warn "じゃがいもの下ごしらえ ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-2-smach.l")
  ;; (smach-demo-2)
  )

(defun curry-3 ()
  (unix:usleep *s-time*)
  (warn "たまねぎの下ごしらえ ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-3-smach.l")
  ;; (smach-demo-3)
  )

(defun curry-4 ()
  (unix:usleep *s-time*)
  (warn "炒める調理の準備 ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-4-smach.l")
  ;; (smach-demo-4)
  )

(defun curry-5 ()
  (unix:usleep *s-time*)
  (warn "たまねぎを炒める調理 ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-5-smach.l")
  ;; (smach-demo-5)
  )

(defun curry-6 ()
  (unix:usleep *s-time*)
  (warn "肉を炒める調理 ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-6-smach.l")
  ;; (smach-demo-6)
  )

(defun curry-7 ()
  (unix:usleep *s-time*)
  (warn "煮込む調理の準備 ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-7-smach.l")
  ;; (smach-demo-7)
  )

(defun curry-8 ()
  (unix:usleep *s-time*)
  (warn "煮込む調理 ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-8-smach.l")
  ;; (smach-demo-8)
  )

(defun curry-9 ()
  (unix:usleep *s-time*)
  (warn "仕上げ ~%")
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/whole-curry-test/curry-9-smach.l")
  ;; (smach-demo-9)
  )



;; curry-0
(defun curry-0-1 ()
  (unix:usleep *s-time*)
  (warn "棚の中にヘラとおたまをセットする ~%")
  )

(defun curry-0-2 ()
  (unix:usleep *s-time*)
  (warn "ボウル１をセットする ~%")
  )

(defun curry-0-3 ()
  (unix:usleep *s-time*)
  (warn "野菜をセットする ~%")
  )

(defun curry-0-4 ()
  (unix:usleep *s-time*)
  (warn "計量カップはここでセットする~%")
  )

(defun curry-0-5 ()
  (unix:usleep *s-time*)
  (warn "コンロの前まで移動する ~%")
  )

(defun curry-0-6 ()
  (unix:usleep *s-time*)
  (warn "ボウル２・３をセットする ~%")
  )

(defun curry-0-7 ()
  (unix:usleep *s-time*)
  (warn "キッチンの前に戻る ~%")
  )

(defun curry-0-8 ()
  (unix:usleep *s-time*)
  (warn "まな板をセットする ~%")
  )

(defun curry-0-9 ()
  (unix:usleep *s-time*)
  (warn "道具３つをセットする~%")
  )


;; curry-1
(defun curry-1-1 ()
  (unix:usleep *s-time*)
  (warn "人参を掴む ~%")
  )

(defun curry-1-2 ()
  (unix:usleep *s-time*)
  (warn "シンクの前に移動する ~%")
  )

(defun curry-1-3 ()
  (unix:usleep *s-time*)
  (warn "人参を洗う ~%")
  )

(defun curry-1-4 ()
  (unix:usleep *s-time*)
  (warn "キッチンの前に戻る ~%")
  )

(defun curry-1-5 ()
  (unix:usleep *s-time*)
  (warn "人参をまな板に置く ~%")
  )

(defun curry-1-6 ()
  (unix:usleep *s-time*)
  (warn "ピーラーを掴む ~%")
  )

(defun curry-1-7 ()
  (unix:usleep *s-time*)
  (warn "人参の皮剥き ~%")
  )

(defun curry-1-8 ()
  (unix:usleep *s-time*)
  (warn "ピーラーを置く，包丁を掴む ~%")
  )

(defun curry-1-9 ()
  (unix:usleep *s-time*)
  (warn "人参切断 ~%")
  )

(defun curry-1-10 ()
  (unix:usleep *s-time*)
  (warn "包丁を置く ~%")
  )

(defun curry-1-11 ()
  (unix:usleep *s-time*)
  (warn "ボウル１に移す動作 ~%")
  )


;; curry-2
(defun curry-2-1 ()
  (unix:usleep *s-time*)
  (warn "じゃがいもを掴む ~%")
  )

(defun curry-2-2 ()
  (unix:usleep *s-time*)
  (warn "シンクの前に移動する ~%")
  )

(defun curry-2-3 ()
  (unix:usleep *s-time*)
  (warn "じゃがいもを洗う ~%")
  )

(defun curry-2-4 ()
  (unix:usleep *s-time*)
  (warn "キッチンの前に戻る ~%")
  )

(defun curry-2-5 ()
  (unix:usleep *s-time*)
  (warn "じゃがいもをまな板に置く ~%")
  )

(defun curry-2-6 ()
  (unix:usleep *s-time*)
  (warn "じゃがいもピーラーを掴む ~%")
  )

(defun curry-2-7 ()
  (unix:usleep *s-time*)
  (warn "じゃがいもの皮剥き ~%")
  )

(defun curry-2-8 ()
  (unix:usleep *s-time*)
  (warn "じゃがいもピーラーを置く，包丁を掴む ~%")
  )

(defun curry-2-9 ()
  (unix:usleep *s-time*)
  (warn "じゃがいも切断 ~%")
  )

(defun curry-2-10 ()
  (unix:usleep *s-time*)
  (warn "包丁を置く ~%")
  )

(defun curry-2-11 ()
  (unix:usleep *s-time*)
  (warn "ボウル１に移す動作 ~%")
  )

;; curry-3
(defun curry-3-1 ()
  (unix:usleep *s-time*)
  (warn "たまねぎを掴む ~%")
  )

(defun curry-3-2 ()
  (unix:usleep *s-time*)
  (warn "シンクの前に移動する ~%")
  )

(defun curry-3-3 ()
  (unix:usleep *s-time*)
  (warn "たまねぎを洗う ~%")
  )

(defun curry-3-4 ()
  (unix:usleep *s-time*)
  (warn "キッチンの前に戻る ~%")
  )

(defun curry-3-5 ()
  (unix:usleep *s-time*)
  (warn "たまねぎをまな板に置く ~%")
  )

(defun curry-3-6 ()
  (unix:usleep *s-time*)
  (warn "包丁を掴む ~%")
  )

(defun curry-3-7 ()
  (unix:usleep *s-time*)
  (warn "たまねぎ切断 ~%")
  )

(defun curry-3-8 ()
  (unix:usleep *s-time*)
  (warn "包丁を置く ~%")
  )

(defun curry-3-9 ()
  (unix:usleep *s-time*)
  (warn "鍋に移す動作 ~%")
  )

;; curry-4
(defun curry-4-1 ()
  (unix:usleep *s-time*)
  (warn "ヘラとおたまを棚から取り出す ~%")
  )

(defun curry-4-2 ()
  (unix:usleep *s-time*)
  (warn "コンロの前まで移動する ~%")
  )

(defun curry-4-3 ()
  (unix:usleep *s-time*)
  (warn "油を掛ける ~%")
  )

;; curry-5
(defun curry-5-1 ()
  (unix:usleep *s-time*)
  (warn "ヘラを掴む ~%")
  )

(defun curry-5-2 ()
  (unix:usleep *s-time*)
  (warn "火を着ける ~%")
  )

(defun curry-5-3 ()
  (unix:usleep *s-time*)
  (warn "炒める ~%")
  )

(defun curry-5-4 ()
  (unix:usleep *s-time*)
  (warn "火を止める ~%")
  )

;; curry-6
(defun curry-6-1 ()
  (unix:usleep *s-time*)
  (warn "肉を鍋に移す ~%")
  )

(defun curry-6-2 ()
  (unix:usleep *s-time*)
  (warn "火を着ける ~%")
  )

(defun curry-6-3 ()
  (unix:usleep *s-time*)
  (warn "炒める ~%")
  )

(defun curry-6-4 ()
  (unix:usleep *s-time*)
  (warn "火を止める ~%")
  )

(defun curry-6-5 ()
  (unix:usleep *s-time*)
  (warn "ヘラを置く ~%")
  )

;; curry-7
(defun curry-7-1 ()
  (unix:usleep *s-time*)
  (warn "キッチン前に移動する ~%")
  )

(defun curry-7-2 ()
  (unix:usleep *s-time*)
  (warn "野菜を鍋に移す ~%")
  )

(defun curry-7-3 ()
  (unix:usleep *s-time*)
  (warn "計量カップを掴む ~%")
  )

(defun curry-7-4 ()
  (unix:usleep *s-time*)
  (warn "水を汲む ~%")
  )

(defun curry-7-5 ()
  (unix:usleep *s-time*)
  (warn "計量カップを置く ~%")
  )

(defun curry-7-6 ()
  (unix:usleep *s-time*)
  (warn "コンロの前まで移動する ~%")
  )


;; curry-8
(defun curry-8-1 ()
  (unix:usleep *s-time*)
  (warn "火を着ける ~%")
  )

(defun curry-8-2 ()
  (unix:usleep *s-time*)
  (warn "沸騰させる ~%")
  )

(defun curry-8-3 ()
  (unix:usleep *s-time*)
  (warn "火を調整する ~%")
  )

(defun curry-8-4 ()
  (unix:usleep *s-time*)
  (warn "煮込む ~%")
  )

(defun curry-8-5 ()
  (unix:usleep *s-time*)
  (warn "火を消す ~%")
  )

;; curry-9
(defun curry-9-1 ()
  (unix:usleep *s-time*)
  (warn "カレールーを鍋に入れる ~%")
  )

(defun curry-9-2 ()
  (unix:usleep *s-time*)
  (warn "ヘラを置く ~%")
  )

(defun curry-9-3 ()
  (unix:usleep *s-time*)
  (warn "おたまを掴んで火を着ける ~%")
  )

(defun curry-9-4 ()
  (unix:usleep *s-time*)
  (warn "煮込む ~%")
  )

(defun curry-9-5 ()
  (unix:usleep *s-time*)
  (warn "火を消す ~%")
  )

