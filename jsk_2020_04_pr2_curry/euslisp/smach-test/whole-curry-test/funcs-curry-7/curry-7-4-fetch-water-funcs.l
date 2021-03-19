(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )


;; ;; 水を汲んで注ぐのを繰り返す
;; (setq *fetch-flag* nil)
;; (until *fetch-flag*
;;        ;; (go-to-sink)
;;        (move-to-sink-ri-direct)
       
;;        ;; 水を汲む
;;        (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/water-use-codes.l")
;;        (update-pos)
;;        ;; (now-fetch-water :sleep-time 1)
;;        (now-fetch-water-with-fail-detection :sleep-time 1)
       
;;        ;; (go-to-kitchen-from-sink)
;;        (go-to-kitchen-from-sink-without-map)
       
;;        ;; 水を注ぐ
;;        (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
;;        (update-pos)
;;        (now-only-pour-water :sleep-time 4)
       
;;        ;; 水汲みの状態を確認する
;;        (look-at-pot) 
;;        (send *ri* :speak-jp "まだ水が必要ですか？")
;;        (curry-dialogue)
;;        (unless (equal *data* '("はい"))
;;          (setq *fetch-flag* t)
;;          )
;;        )

;; 水道まで移動する
;; 水を汲む
;; キッチンに移動する
;; 水を注ぐ
;; 水汲みの状態を確認する
;; ループする


(defun grasp-detection ()
  ;; グリッパ間距離を見てgraspの成否を判定する
  (grasp-fail-detection-larm :g-thre 10)
  (if (equal *fail-flag* t) :fail :success)
  )

(defun grasp-detection-tmp ()
  (curry-state-ask)
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
