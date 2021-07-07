(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )


(defun grasp-detection-tmp ()
  (curry-state-ask)
  )

(defun grasp-detection ()
  ;; グリッパ間距離を見てgraspの成否を判定する
  (grasp-fail-detection-larm :g-thre 10)
  (if (equal *fail-flag* t) :fail :success)
  )

(defun grasp-detection-tmp ()
  (curry-state-ask)
  )



(defun curry-7-0 ()
  (unix:sleep 1)
  (warn "init!! ~%")
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

(defun curry-7-6 ()
  (unix:sleep 1)
  (warn "コンロの前まで移動する ~%")
  )

(defun curry-7-end ()
  (unix:sleep 1)
  (warn "状態を確認する ~%")
  )

(defun curry-7-4-1 ()
  (unix:sleep 1)
  (warn "水道まで移動する ~%")
  )

(defun curry-7-4-2 ()
  (unix:sleep 1)
  (warn "水を汲む ~%")
  )

(defun curry-7-4-3 ()
  (unix:sleep 1)
  (warn "キッチンに移動する ~%")
  )

(defun curry-7-4-4 ()
  (unix:sleep 1)
  (warn "水を注ぐ ~%")
  )

(defun curry-7-4-5 ()
  (unix:sleep 1)
  (warn "水汲みの状態を確認する ~%")
  )

(defun check-water-state-func ()
  ;; 水汲みの状態を検知する
  )

(defun check-water-state-func-tmp ()
  (curry-state-ask)
  )
