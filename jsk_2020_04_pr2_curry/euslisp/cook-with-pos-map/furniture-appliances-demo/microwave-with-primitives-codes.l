(defun microwave-primitive-init () ;; 電子レンジの動作部分だけをプリミティブを使って書く用にする．
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/my-cook-primitive-funcs.l")
  (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/furniture-appliances/ros-topic-test/smach_state_msg-publisher.l")
  
  (move-to-spot-irt *microwave-spot*)
  (objects (list *pr2* *scene*))
  (update-view)
  )

(microwave-primitive-init)

;; move-with primitive funcs
(defun open-microwave ()
  )


(defun close-microwave ()
  )

(defun push-button () ;; 引数ありのプログラム
  )

(defun push-500w-button ()
  )

(defun push-1min-button ()
  )

(defun push-start-button ()
  )


(defun ready-pose ()
  (move-arm-av #f(117.007 48.3805 113.439 -103.326 38.7107 -5.72958 14.4628) :arm :larm :times 4000) ;;move-arm primitive
  )

(defun push-knob ()  
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
  (push-primitive (send *arrow* :copy-worldcoords) :arm :larm :w-thre -15 :axis :x) ;; push-primitive
  
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(10 0 0) :world)
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm) ;;move-arm primitive
  
  (grasp-object :arm :larm :gain 100) ;;grasp-object primitive
  )

(defun rotate-knob (&rest args &key (deg 30) &allow-other-keys)
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :rotate (deg2rad deg) :x)
  (move-object-ik (send *arrow* :copy-worldcoords) :arm :larm :target (send *pr2* :larm :end-coords) :times 1000) ;; move-arm primitive
  )

(defun rotate-knob-avs (&rest args &key (deg 30) &allow-other-keys)
  ;; rotate
  (setq avs (list))
  (setq tms (list))

  (setq *now-neck-p* (send *pr2* :head :neck-p :joint-angle))
  (setq *now-neck-y* (send *pr2* :head :neck-y :joint-angle))
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :head :neck-p :joint-angle *now-neck-p*)
  (send *pr2* :head :neck-y :joint-angle *now-neck-y*)
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

(defun microwave-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :data))
    (format t "~A ~%" *data*)
    )
  )

(defun panel-reader-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :data))
    (format t "~A ~%" *data*)
    (if (ros::time> (send *msg* :header :stamp) *now*)
        (setq *cb-flag* t)
      )
    ))

(defun read-panel ()
  (setq *now* (ros::time-now))
  (ros::unsubscribe "/microwave_reader/result")
  (setq *cb-flag* nil)
  (ros::subscribe "/microwave_reader/result" roseus::StringStamped #'panel-reader-cb)
  (until *cb-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  )

;; defun smach funcs
(defun microwave-smach-on ()
  (pub-msg "on")
  (send *ri* :speak-jp "電子レンジをonにしました．")
  )

(defun microwave-smach-off ()
  (pub-msg "off")
  (send *ri* :speak-jp "IHコンロをoffにしました．")
  )

(defun microwave-smach-finish ()
  (pub-msg "on")
  )

(defun ih-smach-heat (&rest args &key (heat :medium-heat) &allow-other-keys) ;; 引数付きにする :heat :medium-heat (:melting-fire,:low-heat,:medium-heat,:high-heat,:high-power)
  (cond
   ((equal heat :melting-fire)
    (pub-msg "melting-fire")
    (send *ri* :speak-jp "IHコンロをとろ火にしました．"))
   ((equal heat :low-heat)
    (pub-msg "low-heat")
    (send *ri* :speak-jp "IHコンロを弱火にしました．"))
   ((equal heat :medium-heat)
    (pub-msg "medium-heat")
    (send *ri* :speak-jp "IHコンロを中火にしました．"))
   ((equal heat :high-heat)
    (pub-msg "high-heat")
    (send *ri* :speak-jp "IHコンロを強火にしました．"))
   ((equal heat :high-power)
    (pub-msg "high-power")
    (send *ri* :speak-jp "IHコンロをハイパワーにしました．")))
  )

(defun ih-smach-finish ()
  (pub-msg "finish")
  (send *ri* :speak-jp "IHコンロの操作を修了しました．")
  )

;; now codes 連続のIHコンロ操作のプログラムを書く．
(defun micro-all () ;; サトウのご飯
  ;; put object in microwave
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-put-object)
  (send *pmi* :close-microwave)
  
  ;; push button
  (send *pmi* :push-500w-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-start-button)
  
  ;; wait for heating
  (unix::sleep (* 2 60))

  ;; take object from microwave
  (send *pmi* :open-microwave)
  )

(defun hot-veg-micro () ;; 温野菜の温める
  ;; put object in microwave
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-put-object)
  (send *pmi* :close-microwave)
  
  ;; push button
  (send *pmi* :push-500w-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-start-button)
  
  ;; wait for heating
  (unix::sleep (* 3 60))
  
  ;; take object from microwave
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-take-object)
  (send *pmi* :close-microwave)
  )



(defun now-start-ih ()
  ;; (ih-smach-start) これをすると止まってしまう．あと前にupdate-posが必要
  (ready-pose)
  
  (push-knob)
  (ih-smach-on);; onに状態遷移する  
  
  (grasp-knob)
  ;; grasp 失敗検知
  (grasp-fail-detection :arm :larm :g-thre 10)
  (if (equal *fail-flag* t) ;; 失敗したら知らせる
      (progn
        (release-knob)
        (send *ri* :speak-jp "IHコンロのつまみの操作に失敗しました．")
        (return-from now-start-ih)))
  
  (rotate-knob)
  )

(defun now-adjust-heat (&rest args &key (heat :medium-heat) &allow-other-keys) ;; 引数付きにする :heat :medium-heat (:melting-fire,:low-heat,:medium-heat,:high-heat,:high-power)
  (setq *heat-flag* nil)

  ;; ih-panelを見る
  (move-head-look-at (send (send *ih-panel-coords* :copy-worldcoords) :worldpos)) ;; move-head primitive
  
  (until *heat-flag*
         (setq *panel-data* (read-panel))
         ;; あっているかチェック
         (if (equal heat (panel-to-heat *panel-data*))
             (progn
               (ih-smach-heat :heat heat);; 火加減の状態遷移をする
               (setq *heat-flag* t) ;;OK
               )
           (progn
             (ih-smach-heat :heat (panel-to-heat *panel-data*));; 火加減の状態遷移をする
             (rotate-knob :deg (* (- (heat-to-panel heat) *panel-data*) 10));; 一メモリにつき5度回す
             )
	   )
	 )
  )


(defun now-end-ih ()
  (release-knob)
  (push-knob)
  (ih-smach-off);; offに状態遷移する  
  (ready-pose)
  (ih-smach-finish)
  )

(defun now-ih-all ()
  (update-pos)
  (now-start-ih)
  (if (equal *fail-flag* t) ;; 失敗していたら抜ける
      (return-from now-ih-all))
  (now-adjust-heat)
  (now-end-ih)
  )
