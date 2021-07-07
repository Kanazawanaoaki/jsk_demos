(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )

;; ;; 人参の皮剥き
;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/peel-carrot-codes.l")
;; (update-pos)
;; (now-peel)
;; (now-rotate)
;; (now-peel)


(defun grasp-detection ()
  ;; グリッパ間距離を見てgraspの成否を判定する
  (grasp-fail-detection-larm :g-thre 10)
  (if (equal *fail-flag* t) :fail :success)
  )

(defun grasp-detection-tmp ()
  (curry-state-ask)
  )

(defun curry-1-7-1 ()
  (unix:sleep 1)
  (warn "半分の皮を剥く ~%")
  )

(defun curry-1-7-2 ()
  (unix:sleep 1)
  (warn "回転させる ~%")
  )

(defun curry-1-7-3 ()
  (unix:sleep 1)
  (warn "もう半分の皮を剥く ~%")
  )

(defun curry-1-7-1-f-1 ()
  (unix:sleep 1)
  (warn "腕を戻す ~%")
  )

(defun curry-1-7-1-f-2 ()
  (unix:sleep 1)
  (warn "人参を位置に戻す ~%")
  )

(defun curry-1-7-1-1 ()
  (unix:sleep 1)
  (warn "人参を掴む ~%")
  )

(defun curry-1-7-1-2 ()
  (unix:sleep 1)
  (warn "人参を位置にセットする ~%")
  )

(defun curry-1-7-1-3 ()
  (unix:sleep 1)
  (warn "人参の皮を剥く ~%")
  )

(defun curry-1-7-1-4 ()
  (unix:sleep 1)
  (warn "腕を戻す ~%")
  )

(defun curry-1-7-1-5 ()
  (unix:sleep 1)
  (warn "人参を置く ~%")
  )

