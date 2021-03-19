(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )

;; (before-receive-larm) ;; 中間姿勢になる
;; (grasp-carrot-with-fail-detection) ;;失敗検知をしながら掴む
;; (after-grasp-vegs) ;; 持ち上げる
;; (vegs-carry-pose)   ;; 運ぶ姿勢になる  

;; (defun grasp-carrot-with-fail-detection ()
;;   (setq tmp-coords (send *carrot* :copy-worldcoords))
;;   (grasp-carrot)
  
;;   ;; 失敗を検知する
;;   (grasp-fail-detection-larm :g-thre 10)
;;   (if (equal *fail-flag* t) ;; 一度失敗したらもう一度挑戦する
;;       (progn
;;         (if (not (eql (send *carrot* :parent) nil))
;;             (send (send *carrot* :parent) :dissoc *carrot*))
;;         (send *carrot* :newcoords tmp-coords)
;;         (grasp-carrot)
;;         (grasp-fail-detection-larm :g-thre 10)
;;         (if (equal *fail-flag* t) ;; 二度失敗したら人に助けてもらう
;;             (progn
;;               (send *ri* :speak-jp "人参の把持が失敗しました，渡す準備をして合図をして下さい")
;;               (receive-with-dialogue-larm)
;;               (send *ri* :start-grasp :rarm :wait t)
;;               ))
;;         ))
;;   )


(defun grasp-detection ()
  ;; グリッパ間距離を見てgraspの成否を判定する
  (grasp-fail-detection-larm :g-thre 10)
  (if (equal *fail-flag* t) :fail :success)
  )

(defun grasp-detection-tmp ()
  (curry-state-ask)
  )

(defun curry-1-1-1 ()
  (unix:sleep 1)
  (warn "中間姿勢になる ~%")
  )

(defun curry-1-1-2 ()
  (unix:sleep 1)
  (warn "人参を掴む ~%")
  )

(defun curry-1-1-2-f ()
  (unix:sleep 1)
  (warn "人に助けてもらう ~%")
  )

(defun curry-1-1-3 ()
  (unix:sleep 1)
  (warn "持ち上げる ~%")
  )

(defun curry-1-1-4 ()
  (unix:sleep 1)
  (warn "運ぶ姿勢になる ~%")
  )

