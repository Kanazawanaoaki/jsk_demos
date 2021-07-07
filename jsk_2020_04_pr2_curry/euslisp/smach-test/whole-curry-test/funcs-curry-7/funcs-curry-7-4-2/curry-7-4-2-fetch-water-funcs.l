(defun curry-state-ask ()
  (warn "Please check. Is it going well? ~%")
  (setq ans (read))
  (format t "Your answer is ~A. ~%" ans)
  (if (eql ans 'yes) :success :fail)
  )

(defun init ()
  (warn "init! ~%")
  )


;; (defun now-fetch-water-with-fail-detection (&rest args &key (sleep-time 1) &allow-other-keys)
;;   (after-move)
;;   (set-mcup)
;;   (mcup-water-set)
  
;;   (before-lever)
;;   (grasp-lever-tmp)
  
;;   ;; 失敗を検知する
;;   (grasp-fail-detection :g-thre 10)
;;   (if (equal *fail-flag* t) ;; 一度失敗したらもう一度挑戦する
;;       (progn
;; 	(release-lever-tmp)
;; 	(grasp-lever-tmp :adjust -20)
;;         (grasp-fail-detection :g-thre 10)
;;         (if (equal *fail-flag* t) ;; 二度失敗したら人に助けてもらう
;;             (progn
;; 	      (release-lever-tmp)
;; 	      (reset-rarm)
;;               (send *ri* :speak-jp "水道の操作に失敗しました，水を汲んで合図をして下さい")
;;               (ok-wait)
	      
;; 	      (slide-mcup)
;; 	      (after-mcup-water)
	      
;;               (return-from now-fetch-water-with-fail-detection)))
;;         ))
  
;;   (water-on)
  
;;   ;; 本当はここで認識をする
;;   (unix:sleep sleep-time)
  
;;   (slide-mcup)
;;   (water-off)
;;   (release-lever-tmp)
;;   (reset-rarm)
  
;;   (after-mcup-water)
;;   )


;; 1計量カップをセットする
;; 2レバーを掴む
;; 2-f-1失敗したら少しずらして掴む
;; 2-f-3さらに失敗したら人に助けてもらう
;; 3レバー操作をして水を入れる
;; 4水を止める
;; 5移動する姿勢になる


(defun grasp-detection ()
  ;; グリッパ間距離を見てgraspの成否を判定する
  (grasp-fail-detection-larm :g-thre 10)
  (if (equal *fail-flag* t) :fail :success)
  )

(defun grasp-detection-tmp ()
  (curry-state-ask)
  )

(defun curry-7-4-2-1 ()
  (unix:sleep 1)
  (warn "計量カップをセットする ~%")
  )

(defun curry-7-4-2-2 ()
  (unix:sleep 1)
  (warn "レバーを掴む ~%")
  )

(defun curry-7-4-2-2-f-1 ()
  (unix:sleep 1)
  (warn "少しずらして掴む ~%")
  )

(defun curry-7-4-2-2-f-2 ()
  (unix:sleep 1)
  (warn "人に助けてもらう ~%")
  )
(defun curry-7-4-2-3 ()
  (unix:sleep 1)
  (warn "レバー操作をして水を入れる ~%")
  )

(defun curry-7-4-2-4 ()
  (unix:sleep 1)
  (warn "水を止める ~%")
  )

(defun curry-7-4-2-5 ()
  (unix:sleep 1)
  (warn "移動する姿勢になる ~%")
  )

