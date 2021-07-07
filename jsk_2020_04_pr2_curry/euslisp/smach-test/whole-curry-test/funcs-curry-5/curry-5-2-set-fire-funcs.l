(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )


;; (defun now-start-ih-with-fail-detection (&rest args &key (deg -10) &allow-other-keys)
;;   (set-pose-3)
;;   (push-knob)

;;   (grasp-knob)
;;   ;; 失敗を検知する
;;   (grasp-fail-detection-larm :g-thre 10)
;;   (if (equal *fail-flag* t) ;; 一度失敗したらもう一度挑戦する
;;       (progn
;;         (release-knob)
;; 	(push-knob)
;;         (grasp-knob)
;;         (grasp-fail-detection-larm :g-thre 10)
;;         (if (equal *fail-flag* t) ;; 二度失敗したら人に助けてもらう
;;             (progn
;;               (release-knob)
;;               (set-pose-3)
;;               (send *ri* :speak-jp "IHコンロのつまみの操作に失敗しました，コンロをつけて合図をして下さい")
;;               (ok-wait)
;;               (return-from now-start-ih-with-fail-detection)))
;;         ))
  
;;   (rotate-knob :deg 30)
;;   (rotate-knob :deg deg)
;;   (release-knob)
;;   (set-pose-3)
;;   )


;; 1-push-knob
;; 2-grasp-knob
;; 3-rotate-knob
;; 4-release-knob
;; 2-f-ask-for-help

(defun grasp-detection ()
  ;; グリッパ間距離を見てgraspの成否を判定する
  (grasp-fail-detection-larm :g-thre 10)
  (if (equal *fail-flag* t) :fail :success)
  )

(defun grasp-detection-tmp ()
  (curry-state-ask)
  )

(defun curry-5-2-1 ()
  (unix:sleep 1)
  (warn "つまみを押す ~%")
  )

(defun curry-5-2-2 ()
  (unix:sleep 1)
  (warn "つまみを掴む ~%")
  )

(defun curry-5-2-2-f ()
  (unix:sleep 1)
  (warn "人に助けてもらう ~%")
  )

(defun curry-5-2-3 ()
  (unix:sleep 1)
  (warn "つまみを回す ~%")
  )

(defun curry-5-2-4 ()
  (unix:sleep 1)
  (warn "つまみを離す ~%")
  )

