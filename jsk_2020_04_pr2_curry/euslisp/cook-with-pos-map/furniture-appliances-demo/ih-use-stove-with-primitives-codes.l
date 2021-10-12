(defun ih-primitive-init () ;; ihの動作部分だけをプリミティブを使って書く用にする．
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/my-cook-primitive-funcs.l")
  
  (setq *ih-panel-coords* (make-coords :pos (float-vector 563 7940 30865) :rpy (float-vector  3.044 1.407 2.87)))
  
  (move-to-stove-irt)
  (objects (list *pr2* *scene*))
  (update-view)
  )

(ih-primitive-init)

(defun ready-pose ()
  
  )

(defun push-knob-on ()
  
  )

(defun push-knob-off ()
  
  )



;; now codes 連続のIHコンロ操作のプログラムを書く．
(defun now-start-ih ()
  )


;; ih-use-stove-codes.lの中にある プログラム．
(defun now-start-ih-with-fail-detection (&rest args &key (deg -10) &allow-other-keys)
  (set-pose-3)
  (push-knob)

  (grasp-knob)
  ;; 失敗を検知する
  (grasp-fail-detection-larm :g-thre 10)
  (if (equal *fail-flag* t) ;; 一度失敗したらもう一度挑戦する
      (progn
        (release-knob)
	(push-knob)
        (grasp-knob)
        (grasp-fail-detection-larm :g-thre 10)
        (if (equal *fail-flag* t) ;; 二度失敗したら人に助けてもらう
            (progn
              (release-knob)
              (set-pose-3)
              (send *ri* :speak-jp "IHコンロのつまみの操作に失敗しました，コンロをつけて合図をして下さい")
              (ok-wait)
              (return-from now-start-ih-with-fail-detection)))
        ))
  
  (rotate-knob :deg 30)
  (rotate-knob :deg deg)
  (release-knob)
  (set-pose-3)
  )


    
