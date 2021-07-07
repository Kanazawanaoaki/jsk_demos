(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )


;; (defun now-open-shelf-with-fail-detection ()
;;   (setq tmp-coords (send *shelf-door* :copy-worldcoords))
;;   (open-shelf-set)
  
;;   ;; 失敗を検知する
;;   (grasp-fail-detection :g-thre 10)
;;   (if (equal *fail-flag* t) ;; 一度失敗したらもう一度挑戦する
;;       (progn
;;         (if (not (eql (send *shelf-door* :parent) nil))
;;             (send (send *shelf-door* :parent) :dissoc *shelf-door*))
;;         (send *shelf-door* :newcoords tmp-coords)
;;         (open-shelf-set)
;;         (grasp-fail-detection :g-thre 10)
;;         (if (equal *fail-flag* t) ;; 二度失敗したら人に助けてもらう
;;             (progn
;;               (rarm-middle-pose) ;; 中間姿勢になる
;;               (send *ri* :speak-jp "棚の取手を掴むのに失敗しました，棚を開けて合図をして下さい")
;;               (ok-wait)
;;               (return-from now-open-shelf-with-fail-detection)))
;;         ))
  
;;   (open-shelf)
;;   (after-open)
;;   )

;; ;; 棚の扉を開ける
;; (look-at-shelf)
;; (now-open-shelf-with-fail-detection)

;; ;; ヘラをセットする
;; (set-head)
;; (receive-spatula-with-dialogue)
;; (look-at-shelf)
;; (put-spatula-0)

;; ;; おたまをセットする
;; (set-head)
;; (receive-ladle-with-dialogue)
;; (look-at-shelf)
;; (put-ladle-0)

;; ;; 棚の扉を閉める
;; (close-shelf-set)
;; (close-shelf)
;; (after-close)

;; (set-head)


;; ;; 棚の扉を開ける
;; (curry-0-1-1-open-shelf)

;; ;; ヘラをセットする
;; (curry-0-1-2-set-spatula)

;; ;; おたまをセットする
;; (curry-0-1-3-set-ladle)

;; ;; 棚の扉を閉める
;; (curry-0-1-4-close-shelf)



(defun grasp-detection ()
  ;; グリッパ間距離を見てgraspの成否を判定する
  (grasp-fail-detection-larm :g-thre 10)
  (if (equal *fail-flag* t) :fail :success)
  )

(defun grasp-detection-tmp ()
  (curry-state-ask)
  )

(defun curry-0-1-1 ()
  (unix:sleep 1)
  (warn "棚の扉を開ける ~%")
  )

(defun curry-0-1-2 ()
  (unix:sleep 1)
  (warn "ヘラをセットする ~%")
  )

(defun curry-0-1-3 ()
  (unix:sleep 1)
  (warn "おたまをセットする ~%")
  )

(defun curry-0-1-4 ()
  (unix:sleep 1)
  (warn "棚の扉を閉める ~%")
  )
