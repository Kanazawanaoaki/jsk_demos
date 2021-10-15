(defun ih-primitive-init () ;; ihの動作部分だけをプリミティブを使って書く用にする．
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/my-cook-primitive-funcs.l")
  (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/furniture-appliances/ros-topic-test/smach_state_msg-publisher.l")
  
  (setq *ih-panel-coords* (make-coords :pos (float-vector 563 7940 30865) :rpy (float-vector  3.044 1.407 2.87)))

  ;; coords
  (setq *ih-knob-coords* (make-coords :pos (float-vector 680 8154 30715) :rpy (float-vector -3.047 -0.011 1.512)));; original
  ;; (setq *ih-knob-coords* (make-coords :pos (float-vector 680 8154 30715) :rpy (float-vector -3.047 -0.011 1.512)));;変更後
  
  ;; (move-to-stove-irt)
  (move-to-spot-irt *stove-spot*)
  (objects (list *pr2* *scene*))
  (update-view)
  )

(ih-primitive-init)

(defun ready-pose ()
  (move-arm-av #f(117.007 48.3805 113.439 -103.326 38.7107 -5.72958 14.4628) :arm :larm :times 4000) ;;move-arm primitive
  )

(defun push-knob ()  
  ;; (send *ri* :start-grasp :larm :wait t) ;; grasp primitive?
  (move-gripper-func 0 :arm :larm) ;; move-gripper primitive
  
  (send *arrow* :newcoords (send *ih-knob-coords* :copy-worldcoords))
  (push-primitive (send *ih-knob-coords* :copy-worldcoords) :arm :larm :w-thre -15 :axis :x) ;; push-button primitive
  
  (send *arrow* :newcoords (send *ih-knob-coords* :copy-worldcoords))
  (send *arrow* :translate #f(-100 0 0))
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm :times 4000) ;; move-arm primitive
  )

(defun grasp-knob ()
  (move-gripper-func 0.08 :arm :larm) ;; move-gripper primitive
  
  (send *arrow* :newcoords (send *ih-knob-coords* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 90) :x)
  (send *arrow* :translate #f(100 0 0) :world)
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm) ;;move-arm primitive
    
  (send *arrow* :newcoords (send *ih-knob-coords* :copy-worldcoords))
  (push-primitive (send *ih-knob-coords* :copy-worldcoords) :arm :larm :w-thre -15 :axis :x) ;; push-primitive
  
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(10 0 0) :world)
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm) ;;move-arm primitive
  
  (grasp-object :arm :larm :gain 100) ;;grasp-object primitive
  )

(defun rotate-knob (&rest args &key (deg 30) &allow-other-keys)
  ;; rotate
  (setq avs (list))
  (setq tms (list))

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))

  (cond
   ((> deg 0)
    (dotimes (i (/ deg 10))
      (send *arrow* :rotate (deg2rad 10) :x)
      (send *pr2* :larm :inverse-kinematics
            (send *arrow* :copy-worldcoords)
            :rotation-axis t
            :debug-view nil)
      (setq av (send *pr2* :angle-vector))
      (setq avs (append avs (list av)))
      (setq tms (append tms (list 200)))
      ))
   ((< deg 0)
    (dotimes (i (/ (* deg -1) 10))
      (send *arrow* :rotate (deg2rad -10) :x)
      (send *pr2* :larm :inverse-kinematics
            (send *arrow* :copy-worldcoords)
            :rotation-axis t
            :debug-view nil)
      (setq av (send *pr2* :angle-vector))
      (setq avs (append avs (list av)))
      (setq tms (append tms (list 200)))
      ))
   )

  (unless (equal deg 0)
    (move-object-avs avs tms) ;; move-arm primitive? move object primitive?
    )
  )

(defun release-knob ()
  (send *ri* :stop-grasp :larm :wait t)
  
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(30 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send *ih-knob-coords* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 90) :x)
  (send *arrow* :translate #f(100 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  )

;; recognition
(ros::load-ros-package "roseus")

(defun panel-reader-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :data))
    (format t "~A ~%" *data*)
    (if (ros::time> (send *msg* :header :stamp) *now*)
        (setq *cb-flag* t)
      )
    ))

(defun string2num (string)
  (let (num)
    (cond
     ((equal string "1")
      (setq num 1))
     ((equal string "2")
      (setq num 2))
     ((equal string "3")
      (setq num 3))
     ((equal string "4")
      (setq num 4))
     ((equal string "5")
      (setq num 5))
     ((equal string "6")
      (setq num 6))
     ((equal string "7")
      (setq num 7))
     ((equal string "8")
      (setq num 8))
     ((equal string "9")
      (setq num 9))
     )
    num))

(defun panel-to-heat (num)
  (cond
   ((<= num 1)
    (return-from panel-to-heat :melting-fire))
   ((and (> num 1) (<= num 5))
    (return-from panel-to-heat :low-heat))
   ((and (> num 5) (<= num 8))
    (return-from panel-to-heat :medium-heat))
   ((and (> num 8) (<= num 10))
    (return-from panel-to-heat :high-heat))
   ((and (> num 10))
    (return-from panel-to-heat :high-power)))
  )

(defun heat-to-panel (heat)
  (cond
   ((equal heat :melting-fire)
    (return-from heat-to-panel 1))
   ((equal heat :low-heat)
    (return-from heat-to-panel 4))
   ((equal heat :medium-heat)
    (return-from heat-to-panel 7))
   ((equal heat :high-heat)
    (return-from heat-to-panel 9))
   ((equal heat :melting-fire)
    (return-from heat-to-panel 11)))
  )

(defun read-data ()
  (let (num-data num)
    (setq num-data (string-trim "p" (string-trim "/" *data*)))
    (setq num (string2num num-data))
    num))

(defun read-panel ()
  (setq *now* (ros::time-now))
  (ros::unsubscribe "/ih_stove_reader/result")
  (setq *cb-flag* nil)
  (ros::subscribe "/ih_stove_reader/result" roseus::StringStamped #'panel-reader-cb)
  (until *cb-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  (read-data)
  )

;; defun smach funcs
(defun ih-smach-start ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/furniture-appliances/ih-stove-smach.l")
  (ih-stove-smach)
  )

(defun ih-smach-on ()
  (pub-msg "on")
  )

(defun ih-smach-off ()
  (pub-msg "off")
  )

(defun ih-smach-finish ()
  (pub-msg "on")
  )

(defun ih-smach-heat (&rest args &key (heat :medium-heat) &allow-other-keys) ;; 引数付きにする :heat :medium-heat (:melting-fire,:low-heat,:medium-heat,:high-heat,:high-power)
  (cond
   ((equal heat :melting-fire)
    (pub-msg "melting-fire"))
   ((equal heat :low-heat)
    (pub-msg "low-heat"))
   ((equal heat :medium-heat)
    (pub-msg "medium-heat"))
   ((equal heat :high-heat)
    (pub-msg "high-heat"))
   ((equal heat :high-power)
    (pub-msg "high-power")))
  )

;; now codes 連続のIHコンロ操作のプログラムを書く．
(defun now-start-ih ()
  (ih-smach-start)
  (ready-pose)
  
  (push-knob)
  (ih-smach-on);; onに状態遷移する  
  
  (grasp-knob)
  ;; grasp 失敗検知
  (grasp-fail-detection :arm :larm :g-thre 10)
  (if (equal *fail-flag* t) ;; 失敗したら知らせる
      (progn
        (release-knob)
        (send *ri* :speak-jp "IHコンロのつまみの操作に失敗しました，コンロをつけて合図をして下さい")
        (return-from now-start-ih)))

  (rotate-knob)
  (ih-smach-on);; onに状態遷移する  
  )

(defun now-adjust-heat (&rest args &key (heat :medium-heat) &allow-other-keys) ;; 引数付きにする :heat :medium-heat (:melting-fire,:low-heat,:medium-heat,:high-heat,:high-power)
  (setq *heat-flag* nil)

  (until *heat-flag*
         (setq *panel-data* (read-panel))
         ;; あっているかチェック
         (if (equal heat (panel-to-heat *panel-data*))
             (progn
               (ih-smach-heat heat);; 火加減の状態遷移をする
               (setq *heat-flag* t) ;;OK
               )
           (progn
             (ih-smach-heat (panel-to-heat *panel-data*));; 火加減の状態遷移をする
             (rotate-knob :deg (* (- (heat-to-panel heat) *panel-data*) 5));; 一メモリにつき5度回す
             )
         )
  )


(defun now-end-ih ()
  (release-knob)
  (push-knob)
  (ready-pose)
  )

(defun now-ih-all ()
  (now-start-ih)
  (if (equal *fail-flag* t) ;; 失敗していたら抜ける
      (return-from now-ih-all))
  (now-adjust-heat)
  (now-end-ih)
  )


;; ;; ih-use-stove-codes.lの中にある プログラム．
;; (defun now-start-ih-with-fail-detection (&rest args &key (deg -10) &allow-other-keys)
;;   (set-pose-3)
;;   (push-knob)

;;   (grasp-knob)
;;   ;; 失敗を検知する
;;   (grasp-fail-detection-larm :g-thre 10)
;;   (if (equal *fail-flag* t) ;; 一度失敗したらもう一度挑戦する
;;       (progn
;;         (release-knob)
;;         (push-knob)
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

