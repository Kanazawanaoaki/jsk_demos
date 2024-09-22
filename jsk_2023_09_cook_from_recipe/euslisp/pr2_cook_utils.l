#!/usr/bin/env roseus

(ros::load-ros-manifest "roseus")
(ros::load-ros-manifest "std_srvs")
(ros::load-ros-package "lc_state_recognition")
(ros::load-ros-package "jsk_rviz_plugins")
(ros::roseus "pr2_cook_util" :anonymous t)

(ros::advertise "pr2_cooking_current_action" jsk_rviz_plugins::OverlayText 1)
(ros::advertise "pr2_current_cmd_memo" std_msgs::string 1)

(format t "init ~%")
(require :pr2-utils "package://jsk_2023_09_cook_from_recipe/euslisp/pr2-utils.l")
(require :detection-interface "package://jsk_perception/euslisp/detection_interface.l")

(setq *co* (make-coords))

;; object detection with k4a
(defun k4a-check-detection (detecion-topic) ;; TODO 10回くらいsubscribeしてその平均か，外れ値ではないものを使いたいなど
  (let (cds
        trans
        pp_msg
        (start_time (ros::time-now))
        )
    (unless (boundp '*tfl*)
      (setq *tfl* (instance ros::transform-listener :init)))
    (setq trans nil)
    (until trans
           (setq pp_msg (one-shot-subscribe detecion-topic posedetection_msgs::ObjectDetection))
           (if (ros::time>= (send pp_msg :header :stamp) start_time)
               (setq trans (send *tfl* :lookup-transform *base-frame-id* (send pp_msg :header :frame_id) (send pp_msg :header :stamp)))
             )
           )
    (setq cds (make-coords))
    (send cds :move-to trans :local)
    (send cds :move-to (ros::tf-pose->coords (send (car (send pp_msg :objects)) :pose)) :local)
    cds))

;; daialogue
(defun wait-ok-manequine (&key (arm (list "rarm")) (time 0))
  ;; okと言われるまで待つ
  (unix:sleep time)
  (manequine-mode :arm arm :start t)
  (ok-wait)
  (manequine-end)
  )

(defun ok-grasp (&rest args &key (gain 0.01) (arm :rarm) &allow-other-keys)
  (ok-wait)
  (send *ri* :start-grasp arm :wait t :gain gain)
  )

(defun receive-with-dialogue (&rest args &key (gain 0.01) (arm :rarm) &allow-other-keys)
  ;; (send *ri* :speak-jp "包丁を渡す準備をして，合図をして下さい") ;; 等を喋らせている想定でスタート
  (setq *yes-flag* nil)
  (until *yes-flag*
         (send *ri* :stop-grasp arm :wait t)
         (ok-grasp :gain gain)
         (speak-with-log "上手く掴めていますか？")
         (dialogue-func)
         (if (equal *voice-data* '("はい"))
             (setq *yes-flag* t)
           (progn
             (speak-with-log "グリッパを開きます.もう一度お願いします")
             ;; (unix:sleep *w-time*)
             )
           )
         )

  (speak-with-log "次の行動に移ります")
  ;; (unix:sleep *w-time*)
  )


(defun dialogue-manip (&key (init-pose (send *pr2* :reset-manip-pose)) (r-grasp-gain 0.01) (l-grasp-gain 0.01) (r-gripper-dis 0.09) (l-gripper-dis 0.09) (pose-initialize nil))
  (manequine-end)
  (speak-with-log "音声対話操作を開始します")
  (if pose-initialize
      (progn
        (send *pr2* :angle-vector init-pose)
        (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
        (send *ri* :wait-interpolation)
        )
    )
  (setq init-head-y (send *robot* :head-neck-y :joint-angle))
  (setq init-head-p (send *robot* :head-neck-p :joint-angle))
  (setq *finish-flag* nil)
  (until *finish-flag*
         (dialogue-func)
         (cond
          ((or (equal *voice-data* '("左 マネキン")) (equal *voice-data* '("マネキン 左")) (equal *voice-data* '("左腕"))  (equal *voice-data* '("左開始")))
           (speak-with-log "左腕をマネキンモードにします")
           (manequine-mode :arm (list "larm") :start t)
           )
          ((or (equal *voice-data* '("右 マネキン")) (equal *voice-data* '("マネキン 右")) (equal *voice-data* '("右腕"))  (equal *voice-data* '("右開始")))
           (speak-with-log "右腕をマネキンモードにします")
           (manequine-mode :arm (list "rarm") :start t)
           )
          ((or (equal *voice-data* '("マネキン 終了")) (equal *voice-data* '("マネキン 終わり")))
           (speak-with-log "マネキンモードを終了します")
           (manequine-end)
           (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
           (send *pr2* :head-neck-y :joint-angle init-head-y)
           (send *pr2* :head-neck-p :joint-angle init-head-p)
           (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
           (send *ri* :wait-interpolation)
           )
          ((or (equal *voice-data* '("初期 姿勢")) (equal *voice-data* '("初期設定")))
           (speak-with-log "初期姿勢に戻ります")
           (manequine-end)
           (send *pr2* :angle-vector init-pose)
           (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
           (send *ri* :wait-interpolation)
           )
          ((or (equal *voice-data* '("左 つかむ")) (equal *voice-data* '("左閉じる")) (equal *voice-data* '("左手")))
           (speak-with-log "左グリッパを閉じます")
           (send *ri* :start-grasp :larm :gain l-grasp-gain :wait t)
           )
          ((or (equal *voice-data* '("右 つかむ")) (equal *voice-data* '("右閉じる")) (equal *voice-data* '("右手")))
           (speak-with-log "右グリッパを閉じます")
           (send *ri* :start-grasp :rarm :gain r-grasp-gain :wait t)
           )
          ((or (equal *voice-data* '("左 離す")) (equal *voice-data* '("左開ける")) (equal *voice-data* '("左グリッパ")))
           (speak-with-log "左グリッパを開きます")
           ;; (send *ri* :stop-grasp :larm :wait t)
           (send *ri* :move-gripper :larm l-gripper-dis :effort (* 2000 0.03) :wait t)
           )
          ((or (equal *voice-data* '("右 離す")) (equal *voice-data* '("右開ける")) (equal *voice-data* '("右グリッパ")))
           (speak-with-log "右グリッパを開きます")
           (send *ri* :move-gripper :rarm r-gripper-dis :effort (* 2000 0.03) :wait t)
           )
          ((or (equal *voice-data* '("操作 終了")) (equal *voice-data* '("終了")))
           (manequine-end)
           (speak-with-log "音声対話操作を終了します")
           (setq *finish-flag* t)
           )
          (t
           (send *ri* :speak-jp "よくわかりませんでした" :wait t)
           )
          )
         )
  ;; (send *ri* :speak-jp "ありがとうございました" :wait t)
  )

(defun pr2_cook_action_msg_pub (&key (now-str "(hold small-bowl arm2 stove)"))
  (let ((msg))
    (setq msg (instance jsk_rviz_plugins::OverlayText :init))
    (send msg :width 80)
    (send msg :height 200)
    (send msg :line_width 2)
    (send msg :text_size 24)
    (send msg :text now-str)
    (ros::ros-info "msg [~A]" (send msg :text))
    (ros::publish "pr2_cooking_current_action" msg)
    (pr2_action_cmd_memo_pub :now-str (format nil "[pr2_cooking_current_action] ~A" now-str))
    ))

(defun pr2_action_cmd_memo_pub (&key (now-str "(hold small-bowl arm2 stove)"))
  (let ((msg))
    (setq msg (instance std_msgs::string :init))
    (send msg :data now-str)
    (ros::ros-info "msg [~A]" (send msg :data))
    (ros::publish "pr2_current_cmd_memo" msg)
    ))


;; add for grasp detection
(defun grasp-fail-detection (&rest args &key (g-thre 10) (arm :rarm) &allow-other-keys)
  (let ((gripper-len))
    (setq *fail-flag* nil)
    (setq gripper-len (send *ri* :state :gripper arm :position))
    (if (< gripper-len g-thre)
        (setq *fail-flag* t))
    *fail-flag*))

;; release object
(defun release-object (&rest args &key (g-num 0.025) (arm :rarm) &allow-other-keys)
  (let ((curr-gripper))
    ;;グリッパを微妙に開く
    (setq curr-gripper (* 0.001 (send *ri* :state :gripper arm :position)))
    (send *ri* :move-gripper arm (+ g-num curr-gripper))
    ))


;; assoc object
(defun assoc-object-to-arm (object-instance object-handle-cds &key (arm :rarm))
  (let (local-cds)
    (dissoc-object object-instance)

    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send object-handle-cds :copy-worldcoords))
    (send local-cds :assoc object-instance)
    (send local-cds :newcoords (send (send *pr2* arm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc object-instance)

    (send *viewer* :draw-objects)
    (send (send *pr2* arm :end-coords) :assoc object-instance)
    ))


;; old
;; pose teaching
(defun initial-pose-teaching () ;; 道具を握らせて貰って初期姿勢を教わる
  (manequine-end)
  (send *robot* :reset-manip-pose)

  (send *robot* :head-neck-y :joint-angle 0.0)
  (send *robot* :head-neck-p :joint-angle 60.0)

  (send *co* :newcoords (make-coords :pos #f(550 -200 900) :rpy #f(0 0 -1.571)))
  (send *robot* :rarm :inverse-kinematics
        *co*
        :rotation-axis t
        :revert-if-fail nil)
  (send *ri* :angle-vector (send *robot* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm :wait t)

  (send *ri* :speak-jp "物体の持ち方を教えて下さい")
  (unix:sleep 2)

  (wait-ok-manequine);; OKと言われるまでマネキンモード
  (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  (send *robot* :head-neck-y :joint-angle 0.0)
  (send *robot* :head-neck-p :joint-angle 60.0)
  (setq *initial-av* (send *robot* :angle-vector))
  (unix:sleep 2)
  (send *ri* :start-grasp :rarm :wait t) ;; TODO 持つ強さ？

  ;; tmp
  (setq *initial-head-neck-y* 0.0)
  (setq *initial-head-neck-p* 60.0)

  ;; TODO この物体は何ですか？
  )

(defun voice-ok-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :transcript))
    (if (equal *data* '("OK"))
        (progn
          (format t "了解しました！ ~%" *data*)
          (setq *ok-flag* t)
          )
      (format t "data: ~A ~%" *data*)
      )
    )
  )

(defun dump2file (&key (file_name "tmp-teaching-data.l"))
  (dump-loadable-structure file_name *no-obj-l-gri* *obj-l-gri* *initial-av* *place-short-rav-list* *release-short-rav-list* *pick-short-rav-list*)
  (format t "data dumped in ~A ~%" file_name)
  )

(defun load-from-file (&key (file_name "tmp-teaching-data.l") (summarize t) (thre 0.5))
  (load file_name)
  ;; summarize rav-list data if summarize t
  (if summarize
      (summarize-datas :thre thre)
    )
  (format t "data loaded from ~A ~%" file_name)
  (format t "no-obj-l-gri : ~A ~%" *no-obj-l-gri*)
  (format t "obj-l-gri : ~A ~%" *obj-l-gri*)
  (format t "initial-av : ~A ~%" *initial-av*)
  (format t "place-short-rav-list size : ~A ~%" (length *place-short-rav-list*))
  (format t "release-short-rav-list size : ~A ~%" (length *release-short-rav-list*))
  (format t "pick-short-rav-list size : ~A ~%" (length *pick-short-rav-list*))
  (setq *initial-head-neck-y* (elt *initial-av* 15))
  (setq *initial-head-neck-p* (elt *initial-av* 16))
  )

(defun summarize-rav (rav-list &key (threshold 0.1) (larm nil))
  (let (ans-list rec-list)
    (if larm
        (setq rec-list (rav2rec rav-list :arm :larm))
      (setq rec-list (rav2rec rav-list)))
    (setq ans-list (list (elt rav-list 0)))
    (setq now-index 0)
    (dotimes (i (- (length rav-list) 1))
      ;; ans-listの最後とindex i+1の距離がthreshold以上ならappendする
      (setq now-distance (distance (send (elt rec-list now-index) :worldpos) (send (elt rec-list (+ i 1)) :worldpos)))
      (format t "now distance is : ~A~%" now-distance)
      (if (> now-distance threshold)
          (progn
            (setq ans-list (append ans-list (list (elt rav-list (+ i 1)))))
            (setq now-index (+ i 1))
            )
        ))
    (format t "rav-list length : ~A, summarize-rav-list lenght : ~A~%" (length rav-list) (length ans-list))
    ans-list))

;; (defun summarize-datas (&key (thre 0.5) (av-list (list *place-short-rav-list* *release-short-rav-list* *pick-short-rav-list*)))
;;   (dolist (tmp-list av-lists)
;;     (setq tmp-list (summarize-rav tmp-list :threshold thre))
;;     )
;;   ;; (setq *place-short-rav-list* (summarize-rav *place-short-rav-list* :threshold thre))
;;   ;; (setq *release-short-rav-list* (summarize-rav *release-short-rav-list* :threshold thre))
;;   ;; (setq *pick-short-rav-list* (summarize-rav *pick-short-rav-list* :threshold thre))
;;   )
(defun summarize-datas (&key (thre 0.5))
  (setq *place-short-rav-list* (summarize-rav *place-short-rav-list* :threshold thre))
  (setq *release-short-rav-list* (summarize-rav *release-short-rav-list* :threshold thre))
  (setq *pick-short-rav-list* (summarize-rav *pick-short-rav-list* :threshold thre))
  )

(defun rav2rec (rav-list &key (arm :rarm))
  (setq tmp-av (send *robot* :angle-vector))
  (format t "length of rav-list : ~A ~%" (length rav-list))

  (setq rec-list (list))
  (dolist (rav rav-list)
    (send *robot* arm :angle-vector rav)
    (setq now-rec (send (send *robot* arm :end-coords) :copy-worldcoords))
    (setq rec-list (append rec-list (list now-rec)))
    )
  (send *robot* :angle-vector tmp-av)
  rec-list)

(defun assoc-rec-list (rec-list std-coords)
  (setq new-rec-list (list))
  (dolist (rec rec-list)
    (setq new-rec (make-cascoords))
    (send new-rec :newcoords (send rec :copy-worldcoords))
    (print new-rec)
    (send std-coords :assoc new-rec)
    (setq new-rec-list (append new-rec-list (list new-rec)))
    )
  new-rec-list)

(defun view-rec-list (rec-list)
  (dolist (rec rec-list)
    (send rec :draw-on :flush t)
    )
  )

(defun random-coords (initial-cds &key (x 100) (y 50) (theta 30) (theta-positive nil))
  (setq x-num (random x))
  (if (= (random 2) 1)
      (setq x-num (* x-num -1)))
  (setq y-num (random y))
  (if (= (random 2) 1)
      (setq y-num (* y-num -1)))
  (setq theta-num (random theta))
  (if (and (= (random 2) 1) (not theta-positive))
      (setq theta-num (* theta-num -1)))
  (transfer-coords initial-cds :x-num x-num :y-num y-num :theta-num theta-num))

(defun transfer-coords (initial-cds &key (x-num 100) (y-num 50) (theta-num 30))
  (setq ans-cds (send initial-cds :copy-worldcoords))
  (send ans-cds :translate (float-vector x-num y-num 0) :world)
  (send ans-cds :rotate (deg2rad theta-num) :z :world)
  (setq *x-num* x-num)
  (setq *y-num* y-num)
  (setq *theta-num* theta-num)
  ans-cds)

(defun ik-check (rec-list)
  (setq ik-flag t)
  (setq tmp-av (send *robot* :angle-vector))
  (dolist (rec rec-list)
    (setq ik-res (send *robot* :rarm :inverse-kinematics
		       rec
		       ))
    (if (equal ik-res nil)
	(progn
	  (setq ik-flag nil)
	  (return-from ik-check nil)
	  ))
    )
  (send *robot* :angle-vector tmp-av)
  (format t "all ik solved ~%")
  ik-flag
  )

(defun grasp-fail-check (no-obj-gri obj-gri)
  (setq now-gri (send *ri* :state :gripper :rarm :position))
  (setq no-obj-dis (abs (- now-gri no-obj-gri)))
  (setq obj-dis (abs (- now-gri obj-gri)))
  (format t "now-gripper-dis: ~A, no-obj-dis: ~A, obj-dis: ~A ~%" now-gri no-obj-dis obj-dis)
  (if (>= obj-dis no-obj-dis)
      (progn
	;; 失敗時の処理
	(format t "grasp fail? ~%")
	(setq *grasp-fail-flag* t)
	)
    )
  )

;; set pose
(defun set-look-pose ()
  (send *robot* :reset-manip-pose)
  ;; (send *robot* :head-neck-y :joint-angle 0.0)
  ;; (send *robot* :head-neck-p :joint-angle 60.0)
  (send *robot* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *robot* :head-neck-p :joint-angle *initial-head-neck-p*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *robot* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  )

(defun reset-pose ()
  (send *robot* :reset-pose)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *robot* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  )

(defun reset-manip-pose (&key (time 5000) (arm :arms) (head-p 50.0) (head-y 0.0) (torso-lift 300))
  (case arm
        (:arms
         (send *robot* :reset-manip-pose)
         (send *robot* :torso_lift_joint :joint-angle torso-lift)
         )
        (:rarm
         (send *robot* :rarm :angle-vector #f(-75.0 50.0 -110.0 -110.0 20.0 -10.0 -10.0))
         )
        (:larm
         (send *robot* :larm :angle-vector #f(75.0 50.0 110.0 -110.0 -20.0 -10.0 -10.0))
         )
        )
  (send *robot* :head-neck-p :joint-angle head-p)
  (send *robot* :head-neck-y :joint-angle head-y)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *robot* :angle-vector) time)
  (send *ri* :wait-interpolation)
  )

(defun reset-cook-pose (&key (time 5000) (arm :arms) (head-p 50.0) (head-y 0.0) (torso-lift 300))
  (case arm
        (:arms
         ;; (send *robot* :reset-manip-pose)
         (send *robot* :rarm :angle-vector #f(-75.0 50.0 -110.0 -110.0 20.0 -10.0 170.0))
         (send *robot* :larm :angle-vector #f(75.0 50.0 110.0 -110.0 -20.0 -10.0 170.0))
         (send *robot* :torso_lift_joint :joint-angle torso-lift)
         )
        (:rarm
         ;; (send *robot* :rarm :angle-vector #f(-75.0 50.0 -110.0 -110.0 20.0 -10.0 -10.0))
         (send *robot* :rarm :angle-vector #f(-75.0 50.0 -110.0 -110.0 20.0 -10.0 170.0))
         )
        (:larm
         ;; (send *robot* :larm :angle-vector #f(75.0 50.0 110.0 -110.0 -20.0 -10.0 -10.0))
         (send *robot* :larm :angle-vector #f(75.0 50.0 110.0 -110.0 -20.0 -10.0 170.0))
         )
        )
  (send *robot* :head-neck-p :joint-angle head-p)
  (send *robot* :head-neck-y :joint-angle head-y)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *robot* :angle-vector) time)
  (send *ri* :wait-interpolation)
  )

(defun potentio-vector (&key (head-p 50.0) (head-y 0.0))
  (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  (send *robot* :head-neck-p :joint-angle head-p)
  (send *robot* :head-neck-y :joint-angle head-y)
  (send *viewer* :draw-objects)
  )

(defun reset-move-pose (&key (head-p 0.0) (torso 50.0) (tm 2000))
  (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  (send *robot* :torso_lift_joint :joint-angle torso)
  (send *robot* :head-neck-y :joint-angle 0.0)
  (send *robot* :head-neck-p :joint-angle head-p)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *robot* :angle-vector) tm)
  (send *ri* :wait-interpolation)
  )

(defun look-at-cds (cds &key (update-arrow nil) (potentio-vector t))
  (when update-arrow
    (send *arrow* :newcoords (send cds :copy-worldcoords))
    )
  (when potentio-vector
    (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    )
  (send *pr2* :head :look-at (send (send cds :copy-worldcoords) :worldpos))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  )

(defun pr2-arm-up (&key (num 60) (time 3000) (arm :rarm))
  (send *pr2* arm :move-end-pos (float-vector 0 0 num) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) time)
  (send *ri* :wait-interpolation)
  )


(defun set-initial-av (&key (time 4000))
  ;; (manequine-end)
  (send *robot* :angle-vector *initial-av*)
  ;; (send *robot* :head-neck-y :joint-angle 0.0)
  ;; (send *robot* :head-neck-p :joint-angle 60.0)
  (send *robot* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *robot* :head-neck-p :joint-angle *initial-head-neck-p*)
  (send *ri* :angle-vector (send *robot* :angle-vector) time)
  (send *ri* :wait-interpolation)
  )

(defun set-cook-from-now-initial-arm-av (&key (time 4000) (larm nil))
  ;; (manequine-end)
  (if larm
      (send *robot* :larm :angle-vector *cook-from-now-initial-arm-av*)
    (send *robot* :rarm :angle-vector *cook-from-now-initial-arm-av*)
    )
  (send *ri* :angle-vector (send *robot* :angle-vector) time)
  (send *ri* :wait-interpolation)
  )

(defun replay-rav-list (rav-list &key (time 200) (reverse nil) (larm nil) (each-step nil))
  (if reverse
      (setq rav-list (reverse rav-list))
    )
  (setq rav-length (length rav-list))
  (format t "length of rav-list : ~A ~%" rav-length)
  ;; (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  ;; (setq now-head-y (send *robot* :head-neck-y :joint-angle))
  ;; (setq now-head-p (send *robot* :head-neck-p :joint-angle))

  (setq avs (list))
  (setq tms (list))
  (setq cnt 0)
  (dolist (av rav-list)
    ;; (send *robot* :head-neck-y :joint-angle now-head-y)
    ;; (send *robot* :head-neck-p :joint-angle now-head-p)
    ;; (send *robot* :head-neck-y :joint-angle -0.005299)
    ;; (send *robot* :head-neck-p :joint-angle 52.746)
    ;; (send *robot* :head-neck-y :joint-angle 0.0)
    ;; (send *robot* :head-neck-p :joint-angle 60.0)
    (send *robot* :head-neck-y :joint-angle *initial-head-neck-y*)
    (send *robot* :head-neck-p :joint-angle *initial-head-neck-p*)
    (if larm
        (send *robot* :larm :angle-vector av)
      (send *robot* :rarm :angle-vector av))
    (setq avs (append avs (list (send *robot* :angle-vector))))
    (setq tms (append tms (list time)))
    (when each-step
      (format t "current av cnt is ~A, av is ~A ~%" cnt av)
      (send *ri* :angle-vector-sequence avs tms)
      (send *viewer* :draw-objects)
      (send *ri* :wait-interpolation)
      (setq avs (list))
      (setq tms (list))
      (do-until-key
       (print "wait for key pressed (replay each step)")
       (unix:usleep 100000)
       )
      )
    (setq cnt (+ cnt 1))
    )
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  )

(defun replay-short-rav-list (rav-list &key (time 150) (larm nil) (each-step nil)) ;; time 200
  ;; (send *robot* :head-neck-y :joint-angle 0.0)
  ;; (send *robot* :head-neck-p :joint-angle 60.0)
  (send *robot* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *robot* :head-neck-p :joint-angle *initial-head-neck-p*)
  (if larm
      (send *robot* :larm :angle-vector (elt rav-list 0))
    (send *robot* :rarm :angle-vector (elt rav-list 0)))
  (send *ri* :angle-vector (send *robot* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (replay-rav-list rav-list :time time :larm larm :each-step each-step)
  )

(defun replay-rec-list (rec-list &key (time 200) (reverse nil) (larm nil) (each-step nil))
  (if reverse
      (setq rec-list (reverse rec-list))
    )
  (setq rec-length (length rec-list))
  (format t "length of rec-list : ~A ~%" rec-length)
  ;; (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  ;; (setq now-head-y (send *robot* :head-neck-y :joint-angle))
  ;; (setq now-head-p (send *robot* :head-neck-p :joint-angle))

  (setq avs (list))
  (setq tms (list))
  (setq cnt 0)
  (dolist (rec rec-list)
    ;; (send *robot* :head-neck-y :joint-angle now-head-y)
    ;; (send *robot* :head-neck-p :joint-angle now-head-p)
    ;; (send *robot* :head-neck-y :joint-angle -0.005299)
    ;; (send *robot* :head-neck-p :joint-angle 52.746)
    ;; (send *robot* :head-neck-y :joint-angle 0.0)
    ;; (send *robot* :head-neck-p :joint-angle 60.0)
    (send *robot* :head-neck-y :joint-angle *initial-head-neck-y*)
    (send *robot* :head-neck-p :joint-angle *initial-head-neck-p*)
    (if larm
        (setq ik-res (send *robot* :larm :inverse-kinematics
                           rec
                           ))
      (setq ik-res (send *robot* :rarm :inverse-kinematics
                         rec
                         )))
    (if (equal ik-res nil)
        (progn
          (setq *ik-fail-flag* t)
          (return-from replay-rec-list)
          )
      )
    (setq avs (append avs (list (send *robot* :angle-vector))))
    (setq tms (append tms (list time)))
    (when each-step
      (format t "current av cnt is ~A, rec is ~A ~%" cnt rec)
      (send *ri* :angle-vector-sequence avs tms)
      (send *viewer* :draw-objects)
      (send *ri* :wait-interpolation)
      (setq avs (list))
      (setq tms (list))
      (do-until-key
       (print "wait for key pressed (replay each step)")
       (unix:usleep 100000)
       )
      )
    (setq cnt (+ cnt 1))
    )
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  )

(defun replay-short-rec-list (rec-list &key (time 150) (larm nil) (trans-vec #f(0 0 0 )) (each-step nil))
  ;; (send *robot* :head-neck-y :joint-angle 0.0)
  ;; (send *robot* :head-neck-p :joint-angle 60.0)
  (send *robot* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *robot* :head-neck-p :joint-angle *initial-head-neck-p*)
  (setq initial-rec-coords (make-cascoords))
  (send initial-rec-coords :newcoords (send (elt rec-list 0) :copy-worldcoords))
  (setq assoced-rec-list (assoc-rec-list rec-list initial-rec-coords))
  (send initial-rec-coords :translate trans-vec)

  (if larm
      (setq ik-res (send *robot* :larm :inverse-kinematics
                         (elt assoced-rec-list 0)
                         ))
    (setq ik-res (send *robot* :rarm :inverse-kinematics
                       (elt assoced-rec-list 0)
                       )))
  (if (equal ik-res nil)
      (progn
        (setq *ik-fail-flag* t)
        (return-from replay-short-rec-list)
        )
    )
  (send *ri* :angle-vector (send *robot* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  ;; (send *ri* :angle-vector (send *robot* :angle-vector) 4000)
  ;; (send *ri* :wait-interpolation)
  ;; (unix:usleep 3500000)

  (replay-rec-list assoced-rec-list :time time :larm larm :each-step each-step)
  )

(defun record-rav-key ()
  (manequine-mode :arm (list "rarm") :start t)
  (setq *ok-flag* nil)
  (setq  rav-list (list))
  (do-until-key
   (send *robot* :angle-vector (send *ri* :state :potentio-vector))
   (setq now-rav (send *robot* :rarm :angle-vector))
   (format t "now rav : ~A" now-rav)
   (setq rav-list (append rav-list (list now-rav)))
   (unix:usleep 100000)
   )
  (manequine-end)
  (setq rav-length (length rav-list))
  (format t "length of rav-list : ~A ~%" rav-length)
  rav-list
  )

(defun record-rav-voice (&key (arm "rarm"))
  ;; okと言われるまで待つ
  (manequine-mode :arm (list arm) :start t)
  (ros::unsubscribe "/speech_to_text")
  (setq *ok-flag* nil)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'voice-ok-cb)
  (setq rav-list (list))
  (setq rec-list (list))
  (ros::rate 10)
  (until *ok-flag*
         (send *robot* :angle-vector (send *ri* :state :potentio-vector))
         (if (equal arm "rarm")
             (progn
               (setq now-rav (send *robot* :rarm :angle-vector))
               (setq now-rec (send (send *robot* :rarm :end-coords) :copy-worldcoords))
               )
           (progn
             (setq now-rav (send *robot* :larm :angle-vector))
             (setq now-rec (send (send *robot* :larm :end-coords) :copy-worldcoords))
             ))
         (format t "now rav : ~A" now-rav)
         (setq rav-list (append rav-list (list now-rav)))
         (setq rec-list (append rec-list (list now-rec)))
         ;; todo also save times ?
         (ros::spin-once)
         (ros::sleep)
         )

  (send *ri* :speak-jp "ありがとうございます")
  (manequine-end)
  (setq rav-length (length rav-list))
  (format t "length of rav-list : ~A ~%" rav-length)
  (list rav-list rec-list)
  )

(defun initial-pose-teaching-key () ;; 道具を握らせて貰って初期姿勢を教わる
  (manequine-end)
  (send *robot* :reset-manip-pose)
  (send *co* :newcoords (make-coords :pos #f(550 -200 900) :rpy #f(0 0 -1.571)))
  (send *robot* :rarm :inverse-kinematics
        *co*
        :rotation-axis t
        :revert-if-fail nil)
  (send *ri* :angle-vector (send *robot* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm :wait t)

  ;; 待つ
  (manequine-mode :arm (list "rarm") :start t)
  (do-until-key
   (send *robot* :angle-vector (send *ri* :state :potentio-vector))
   (setq now-rav (send *robot* :rarm :angle-vector))
   (format t "now rav : ~A" now-rav)
   (unix:usleep 100000)
   )
  (manequine-end)
  (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  (setq *initial-av* (send *robot* :angle-vector))
  (send *ri* :start-grasp :rarm :wait t) ;; TODO 持つ強さ？
  )

(defun place-object-teaching ()
  (set-initial-av)

  ;; 物体の置き方を教わる
  (send *ri* :speak-jp "物体の置き方を教えて下さい")
  (unix:sleep 2)

  (setq place-ans (record-rav-voice))
  (setq *place-rav-list* (elt place-ans 0))
  (setq *place-rec-list* (elt place-ans 1))

  (send *ri* :stop-grasp :rarm :wait t);; TODO 離す時のグリッパの離し具合？

  ;; 手の離し方
  (send *ri* :speak-jp "手の離し方を教えて下さい")
  (unix:sleep 2)

  (setq release-ans (record-rav-voice))
  (setq *release-rav-list* (elt release-ans 0))
  (setq *release-rec-list* (elt release-ans 1))

  (set-initial-av)
  )

(defun pick-object-teaching ()
  (set-initial-av)

  ;; 物体の掴み方を教わる
  (send *ri* :speak-jp "物体の掴み方を教えて下さい")
  (unix:sleep 2)

  (setq pick-ans (record-rav-voice))
  (setq *pick-rav-list* (elt pick-ans 0))
  (setq *pick-rec-list* (elt pick-ans 1))

  (send *ri* :start-grasp :rarm :wait t)
  (unix:sleep 1)
  ;; TODO 持ち上げる？

  (send *ri* :stop-grasp :rarm :wait t);; TODO 離す時のグリッパの離し具合？
  (unix:sleep 2)

  ;; 離し方を実行する
  (replay-rav-list *release-rav-list*)

  (set-initial-av)
  )

(defun place-and-release-object-teaching-detail ()
  (set-initial-av)

  (send *ri* :speak-jp "物体の置きはじめの姿勢を教えて下さい")
  (unix:sleep 2)
  (wait-ok-manequine)
  (send *robot* :head-neck-y :joint-angle 0.0)
  (send *robot* :head-neck-p :joint-angle 60.0)
  (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  (setq *place-initial-av* (send *robot* :angle-vector))
  (setq *place-initial-rec* (send *robot* :rarm :end-coords))
  (unix:sleep 2)
  (send *ri* :start-grasp :rarm :wait t) ;; TODO 持つ強さ？

  ;; 物体の置き方を教わる
  (send *ri* :speak-jp "物体の置き方を教えて下さい")
  (unix:sleep 2)
  (setq place-ans (record-rav-voice))
  (setq *place-short-rav-list* (elt place-ans 0))
  (setq *place-short-rec-list* (elt place-ans 1))

  (send *ri* :stop-grasp :rarm :wait t);; TODO 離す時のグリッパの離し具合？

  ;; 手の離し方
  (send *ri* :speak-jp "手の離し方を教えて下さい")
  (unix:sleep 2)

  (setq release-ans (record-rav-voice))
  (setq *release-short-rav-list* (elt release-ans 0))
  (setq *release-short-rec-list* (elt release-ans 1))
  (setq *pick-short-rav-list* (reverse *release-short-rav-list*))
  (setq *pick-short-rec-list* (reverse *release-short-rec-list*))

  (set-initial-av)
  )

(defun teaching-test ()
  ;; 初期姿勢，持ち方の教示
  (initial-pose-teaching)

  ;; 物体の置き方と手の離し方の教示
  (place-object-teaching)

  ;; 物体の掴み方の教示
  (pick-object-teaching)

  (warn "please run (replay-test) ~%")
  )

(defun replay-test ()
  ;; ここで机の状態を見る

  ;; 道具を持たせて貰う
  (receive-object)

  ;; 道具を置く
  (set-initial-av)
  (send *ri* :start-grasp :rarm :wait t)
  (unix:sleep 2)
  (replay-rav-list *place-rav-list*)

  ;; 道具を離す
  (send *ri* :stop-grasp :rarm :wait t)
  (unix:sleep 2)
  (replay-rav-list *release-rav-list*)

  ;; ここで道具を見て，バウンディングボックスとか色々な物を保存する．

  ;; 道具を掴む
  (set-initial-av)
  (send *ri* :stop-grasp :rarm :wait t)
  (unix:sleep 2)
  (replay-rav-list *pick-rav-list*)

  (send *ri* :start-grasp :rarm :wait t)
  (unix:sleep 2)

  (warn "please run (replay-test) ~%")
  )

(defun teach-and-replay-test ()
  ;; 動作を教わる
  (teaching-test)

  ;; 教わった動作を再生する
  (send *ri* :speak-jp "教わった動作を実行します")
  (replay-test)

  (send *robot* :rarm :move-end-pos #f(0 0 100) :world)
  (send *ri* :angle-vector (send *robot* :angle-vector))
  (send *ri* :wait-interpolation)

  (send *ri* :speak-jp "動作を実行しました")
  )

(defun same-data-collection (&key (times 10))
  ;; 机の上にそのまま物を置いていく
  ;; 道具を持たせて貰う
  (receive-object)

  (dotimes (i times)
    ;; 物体を置く
    (set-initial-av)
    (send *ri* :start-grasp :rarm :wait t)

    ;; 物体を置く場所を計画する．平面の中でどこに置くか

    (start-data-collection :service "place_data_collection_rosbag/start_request");; 置く時のデータ収集
    (unix:sleep 4)
    (replay-rav-list *place-rav-list*)
    (end-data-collection :service "place_data_collection_rosbag/end_request");; 置く時のデータ収集

    ;; 道具を離す
    (send *ri* :stop-grasp :rarm :wait t)
    (unix:sleep 2)
    (replay-rav-list *release-rav-list*)

    ;; ここで道具を見て，バウンディングボックスとか色々なdataを保存する．

    ;; 道具を掴む
    (set-initial-av)
    (send *ri* :stop-grasp :rarm :wait t)

    (start-data-collection :service "pick_data_collection_rosbag/start_request");; 掴む時のデータ収集
    (unix:sleep 4)
    (replay-rav-list *pick-rav-list*)
    (end-data-collection :service "pick_data_collection_rosbag/end_request");; 掴む時のデータ収集

    (send *ri* :start-grasp :rarm :wait t)
    (unix:sleep 2)

    (send *robot* :rarm :move-end-pos #f(0 0 100) :world)
    (send *ri* :angle-vector (send *robot* :angle-vector))
    (send *ri* :wait-interpolation)
    )
  )

(defun short-teaching-test ()
  (send *ri* :start-grasp :rarm :wait t)
  (unix:sleep 1)
  (setq *no-obj-l-gri* (send *ri* :state :gripper :rarm :position))

  (initial-pose-teaching)
  (unix:sleep 1)
  (setq *obj-l-gri* (send *ri* :state :gripper :rarm :position))
  (set-initial-av)

  (place-and-release-object-teaching-detail)
  (set-initial-av)

  ;; ここで観察する

  )

(defun short-replay-test ()
  ;; ここで机の状態を見る
  ;; 道具を持たせて貰う
  (receive-object)

  ;; 道具を置く
  (set-initial-av)
  (send *ri* :start-grasp :rarm :wait t)
  (unix:sleep 2)
  (replay-short-rav-list *place-short-rav-list*)

  ;; 道具を離す
  (send *ri* :stop-grasp :rarm :wait t)
  (unix:sleep 2)
  (replay-rav-list *release-short-rav-list*)

  ;; ここで道具を見て，バウンディングボックスとか色々な物を保存する．

  ;; 道具を掴む
  (set-initial-av)
  (send *ri* :stop-grasp :rarm :wait t)
  (unix:sleep 2)
  (replay-short-rav-list *pick-short-rav-list*)

  (send *ri* :start-grasp :rarm :wait t)
  (unix:sleep 2)
  )

(defun short-teach-and-replay-test (&key (summarize t))
  ;; 動作を教わる
  (short-teaching-test)

  ;; 教わった動作を再生する
  (send *ri* :speak-jp "教わった動作を実行します")
  ;; summarize rav-list data if summarize t
  (if summarize
      (summarize-datas :thre 0.5)
    )
  (short-replay-test)

  (send *robot* :rarm :move-end-pos #f(0 0 100) :world)
  (send *ri* :angle-vector (send *robot* :angle-vector))
  (send *ri* :wait-interpolation)

  (send *ri* :speak-jp "動作を実行しました")
  )

(defun short-data-test (&key (times 10) (save_img nil) (save_avs t) (summarize t) (thre 0.5))
  ;; 道具を持たせて貰う
  (receive-object)

  ;; summarize rav-list data if summarize t
  (if summarize
      (summarize-datas :thre thre)
    )

  ;; rav2rec
  (setq *place-short-rec-list* (rav2rec *place-short-rav-list*))
  (setq *release-short-rec-list* (rav2rec *release-short-rav-list*))
  (setq *pick-short-rec-list* (rav2rec *pick-short-rav-list*))
  ;; assoc rec to obj-coords
  (setq *obj-coords* (make-cascoords))
  (send *obj-coords* :newcoords (send (elt *release-short-rec-list* 0) :copy-worldcoords))
  (setq *initial-obj-coords* (send *obj-coords* :copy-worldcoords))
  (setq *place-assoc-short-rec-list* (assoc-rec-list *place-short-rec-list* *obj-coords*))
  (setq *release-assoc-short-rec-list* (assoc-rec-list *release-short-rec-list* *obj-coords*))
  (setq *pick-assoc-short-rec-list* (assoc-rec-list *pick-short-rec-list* *obj-coords*))

  (send *ri* :speak-jp "自動のデータ収集を開始します")
  (dotimes (i times)
    ;; 物体を置く
    (set-initial-av)
    (send *ri* :start-grasp :rarm :wait t)

    ;; 物体を置く場所を計画する．平面の中でどこに置くか
    ;; (send *obj-coords* :rotate (deg2rad 10) :z :world)
    (setq *ik-ok-flag* nil)
    (until *ik-ok-flag*
           (send *obj-coords* :newcoords (random-coords *initial-obj-coords* :x 50 :y 50 :theta 90 :theta-positive t))
           ;; (send *obj-coords* :newcoords (random-coords *initial-obj-coords* :x 50 :y 100 :theta 90))
           ;; (send *obj-coords* :newcoords (random-coords *initial-obj-coords* :x 50 :y 50 :theta 0)) ;; for easy
           (format t "x-num: ~A y-num: ~A theta-num: ~A ~%" *x-num* *y-num* *theta-num*)
           (setq ik-place-flag (ik-check *place-assoc-short-rec-list*))
           (setq ik-release-flag (ik-check *release-assoc-short-rec-list*))
           (setq ik-pick-flag (ik-check *pick-assoc-short-rec-list*))
           (if (and ik-place-flag ik-release-flag ik-pick-flag)
               (setq *ik-ok-flag* t)
             )
           )

    ;; (if save_avs
    ;; 	(start-data-collection :service "place_data_collection_rosbag/start_request");; 置く時のデータ収集
    ;;   )
    (unix:sleep 4)
    (replay-short-rec-list *place-assoc-short-rec-list*)
    ;; (if save_avs
    ;; 	(end-data-collection :service "place_data_collection_rosbag/end_request");; 置く時のデータ収集
    ;;   )

    ;; 道具を離す
    (send *ri* :stop-grasp :rarm :wait t)
    (unix:sleep 2)
    (replay-short-rec-list *release-assoc-short-rec-list*)

    ;; ここで道具を見て，バウンディングボックスとか色々なdataを保存する．
    (if save_img
        (progn
          (set-initial-av)
          (set-look-pose)
          (save_data_wait)
        ))

    ;; 道具を掴む
    (set-initial-av)
    (send *ri* :stop-grasp :rarm :wait t)

    ;; 掴む時のデータ収集
    (if save_avs
        (progn
        (start-data-collection :service "pick_data_collection_rosbag/start_request")
        (start-data-collection :service "pick_long_data_collection_rosbag/start_request")
        ))
    (unix:sleep 4)
    (replay-short-rec-list *pick-assoc-short-rec-list*)
    ;; 掴む時のデータ収集
    (if save_avs
        (end-data-collection :service "pick_data_collection_rosbag/end_request")
      )

    (send *ri* :start-grasp :rarm :wait t)
    (unix:sleep 2)

    (send *robot* :rarm :move-end-pos #f(0 0 100) :world)
    (send *ri* :angle-vector (send *robot* :angle-vector))
    (send *ri* :wait-interpolation)
    (if save_avs
        (end-data-collection :service "pick_long_data_collection_rosbag/end_request")
      )
    (set-initial-av)

    (setq *grasp-fail-flag* nil)
    (grasp-fail-check *no-obj-l-gri* *obj-l-gri*)
    (if *grasp-fail-flag*
        (progn
          (send *ri* :speak-jp "物体の把持に失敗したので助けて下さい")
          (ok-wait)
          )
      )
    )
  (send *ri* :speak-jp "自動のデータ収集が終了しました")
  )

(defun tmp-test-key ()
  (initial-pose-teaching-key)

  (set-initial-av)

  (setq *tmp-rav-list* (record-rav-key))
  (set-initial-av)
  (replay-rav-list *tmp-rav-list* :time 200)
  (set-initial-av)
  )

(defun tmp-test-voice ()
  (initial-pose-teaching)

  (set-initial-av)

  ;; (setq *tmp-rav-list* (record-rav-voice))
  (setq tmp-ans (record-rav-voice))
  (setq *tmp-rav-list* (elt tmp-ans 0))
  (setq *tmp-rec-list* (elt tmp-ans 1))

  (set-initial-av)
  (replay-rav-list *tmp-rav-list* :time 200)
  (set-initial-av)
  )


(defun put-spec-point (&key (summarize t) (thre 0.5) (x 50) (y 50) (theta 0))
  ;; 道具を持たせて貰う
  (receive-object)

  ;; summarize rav-list data if summarize t
  (if summarize
      (summarize-datas :thre thre)
    )

  ;; rav2rec
  (setq *place-short-rec-list* (rav2rec *place-short-rav-list*))
  (setq *release-short-rec-list* (rav2rec *release-short-rav-list*))
  (setq *pick-short-rec-list* (rav2rec *pick-short-rav-list*))
  ;; assoc rec to obj-coords
  (setq *obj-coords* (make-cascoords))
  (send *obj-coords* :newcoords (send (elt *release-short-rec-list* 0) :copy-worldcoords))
  (setq *initial-obj-coords* (send *obj-coords* :copy-worldcoords))
  (setq *place-assoc-short-rec-list* (assoc-rec-list *place-short-rec-list* *obj-coords*))
  (setq *release-assoc-short-rec-list* (assoc-rec-list *release-short-rec-list* *obj-coords*))
  (setq *pick-assoc-short-rec-list* (assoc-rec-list *pick-short-rec-list* *obj-coords*))

  (set-initial-av)
  (send *ri* :start-grasp :rarm :wait t)

  ;; 物体を置く場所を計画する．平面の中でどこに置くか
  ;; (send *obj-coords* :rotate (deg2rad 10) :z :world)
  (setq *ik-ok-flag* nil)
  (send *obj-coords* :newcoords (transfer-coords *initial-obj-coords* :x-num x :y-num y :theta-num theta))
  (format t "x-num: ~A y-num: ~A theta-num: ~A ~%" *x-num* *y-num* *theta-num*)
  (setq ik-place-flag (ik-check *place-assoc-short-rec-list*))
  (setq ik-release-flag (ik-check *release-assoc-short-rec-list*))
  (setq ik-pick-flag (ik-check *pick-assoc-short-rec-list*))
  (if (and ik-place-flag ik-release-flag ik-pick-flag)
      (setq *ik-ok-flag* t)
    )

  (unix:sleep 4)
  (replay-short-rec-list *place-assoc-short-rec-list*)

  ;; 道具を離す
  (send *ri* :stop-grasp :rarm :wait t)
  (unix:sleep 2)
  (replay-short-rec-list *release-assoc-short-rec-list*)

  ;; 道具を掴む
  (set-initial-av)
  (send *ri* :stop-grasp :rarm :wait t)
  )

(defun random-res-list-test (&key (num 10) (x 50) (y 50) (theta 0) (theta-positive t))
  ;; random result list
  (setq *random-res-list* (list))
  (setq now-cds (make-coords))

  (dotimes (i num)
    (random-coords now-cds :x x :y y :theta theta :theta-positive theta-positive)
    (format t "x-num: ~A y-num: ~A theta-num: ~A ~%" *x-num* *y-num* *theta-num*)
    (setq *random-res-list* (append *random-res-list* (list (list *x-num* *y-num* *theta-num*))))
    )
  (format t "random-res-list : ~A ~%" *random-res-list*)
  )

(defun dump-random-res-list  (&key (file_name "tmp-random-res-list.l"))
  (dump-loadable-structure file_name *random-res-list*)
  (format t "data dumped in ~A ~%" file_name)
  )

(defun dump-data-collection-setting-list  (&key (file_name "tmp-data-collection-setting.l"))
  (dump-loadable-structure file_name *random-res-list* *no-obj-l-gri* *obj-l-gri* *initial-av* *place-short-rav-list* *release-short-rav-list* *pick-short-rav-list*)
  (format t "data dumped in ~A ~%" file_name)
  )


(defun duka-data-test (&key (times 10) (save_img nil) (save_avs t) (summarize t) (thre 0.5) (x 50) (y 50) (theta 0) (theta-positive t) (receive t) (dump_file_name "tmp-data-collection-setting.l"))
  ;; 道具を持たせて貰う
  (if receive
      (receive-object)
    )

  ;; summarize rav-list data if summarize t
  (if summarize
      (summarize-datas :thre thre)
    )

  ;; random result list
  (setq *random-res-list* (list))

  ;; rav2rec
  (setq *place-short-rec-list* (rav2rec *place-short-rav-list*))
  (setq *release-short-rec-list* (rav2rec *release-short-rav-list*))
  (setq *pick-short-rec-list* (rav2rec *pick-short-rav-list*))
  ;; assoc rec to obj-coords
  (setq *obj-coords* (make-cascoords))
  (send *obj-coords* :newcoords (send (elt *release-short-rec-list* 0) :copy-worldcoords))
  (setq *initial-obj-coords* (send *obj-coords* :copy-worldcoords))
  (setq *place-assoc-short-rec-list* (assoc-rec-list *place-short-rec-list* *obj-coords*))
  (setq *release-assoc-short-rec-list* (assoc-rec-list *release-short-rec-list* *obj-coords*))
  (setq *pick-assoc-short-rec-list* (assoc-rec-list *pick-short-rec-list* *obj-coords*))

  (send *ri* :speak-jp "自動のデータ収集を開始します")
  (dotimes (i times)
    ;; 物体を置く
    (set-initial-av)
    (send *ri* :start-grasp :rarm :wait t)

    ;; 物体を置く場所を計画する．平面の中でどこに置くか
    ;; (send *obj-coords* :rotate (deg2rad 10) :z :world)
    (setq *ik-ok-flag* nil)
    (until *ik-ok-flag*
           (send *obj-coords* :newcoords (random-coords *initial-obj-coords* :x x :y y :theta theta :theta-positive theta-positive))
           ;; (send *obj-coords* :newcoords (random-coords *initial-obj-coords* :x 50 :y 50 :theta 0 :theta-positive t))
           ;; (send *obj-coords* :newcoords (random-coords *initial-obj-coords* :x 50 :y 100 :theta 90))
           ;; (send *obj-coords* :newcoords (random-coords *initial-obj-coords* :x 50 :y 50 :theta 0)) ;; for easy
           (format t "x-num: ~A y-num: ~A theta-num: ~A ~%" *x-num* *y-num* *theta-num*)
           ;; (setq *random-res-list* (append *random-res-list* (list (list *x-num* *y-num* *theta-num*))))
           (setq ik-place-flag (ik-check *place-assoc-short-rec-list*))
           (setq ik-release-flag (ik-check *release-assoc-short-rec-list*))
           (setq ik-pick-flag (ik-check *pick-assoc-short-rec-list*))
           (if (and ik-place-flag ik-release-flag ik-pick-flag)
               (setq *ik-ok-flag* t)
             )
           )

    ;; (if save_avs
    ;; 	(start-data-collection :service "place_data_collection_rosbag/start_request");; 置く時のデータ収集
    ;;   )
    (unix:sleep 4)
    (replay-short-rec-list *place-assoc-short-rec-list*)
    ;; (if save_avs
    ;; 	(end-data-collection :service "place_data_collection_rosbag/end_request");; 置く時のデータ収集
    ;;   )

    ;; 道具を離す
    (send *ri* :stop-grasp :rarm :wait t)
    (unix:sleep 2)
    (replay-short-rec-list *release-assoc-short-rec-list*)

    ;; ここで道具を見て，バウンディングボックスとか色々なdataを保存する．
    (if save_img
        (progn
          (set-initial-av)
          (set-look-pose)
          (save_data_wait)
        ))

    ;; 道具を掴む
    (set-initial-av)
    (send *ri* :stop-grasp :rarm :wait t)

    ;; 掴む時のデータ収集
    (if save_avs
        (progn
          (data-collection-start)
          (start-data-collection :service "pick_data_collection_rosbag/start_request")
          (start-data-collection :service "pick_long_data_collection_rosbag/start_request")
          ))
    (unix:sleep 4)
    (replay-short-rec-list *pick-assoc-short-rec-list*)

    (send *ri* :start-grasp :rarm :wait t)
    (unix:sleep 2)

    (send *robot* :rarm :move-end-pos #f(0 0 100) :world)
    (send *ri* :angle-vector (send *robot* :angle-vector))
    ;; (send *ri* :wait-interpolation)
    (unix:usleep 900000)

    ;; 掴む時のデータ収集
    (if save_avs
        (end-data-collection :service "pick_data_collection_rosbag/end_request")
      )

    (set-initial-av)

    (if save_avs
        (progn
          (data-collection-stop)
          (end-data-collection :service "pick_long_data_collection_rosbag/end_request")
          )
      )

    (setq *grasp-fail-flag* nil)
    (grasp-fail-check *no-obj-l-gri* *obj-l-gri*)
    (if *grasp-fail-flag*
        (progn
          (send *ri* :speak-jp "物体の把持に失敗したので助けて下さい")
          (ok-wait)
          )
      )
    (setq *random-res-list* (append *random-res-list* (list (list *x-num* *y-num* *theta-num* (not *grasp-fail-flag*)))))
    )
  (send *ri* :speak-jp "自動のデータ収集が終了しました")
  (dump-data-collection-setting-list :file_name dump_file_name)
  )


;; self move ver
(defun calc-real-num-diff () ;; tmp TODO returnとかちゃんと書いて中に入れたい．
  (setq now-arm-coords (send (send *robot* :rarm :end-coords) :copy-worldcoords))
  ;; (setq real-x (elt (send (send *initial-obj-coords* :transformation now-arm-coords :world) :pos) 0))
  ;; (setq real-y (elt (send (send *initial-obj-coords* :transformation now-arm-coords :world) :pos) 1))
  (setq real-x (- (elt (send now-arm-coords :worldpos) 0) (elt (send *initial-obj-coords* :worldpos) 0)))
  (setq real-y (- (elt (send now-arm-coords :worldpos) 1) (elt (send *initial-obj-coords* :worldpos) 1)))
  (setq real-theta-raw (elt (elt (send (send *initial-obj-coords* :transformation now-arm-coords) :rpy-angle) 0) 0))
  (setq real-theta (rad2deg real-theta))
  )

(defun self-move-summarize-datas (&key (thre 0.5)) ;;TODO リスト処理で書き換えたい
  (setq *first-pregrasp-short-rav-list* (summarize-rav *first-pregrasp-short-rav-list* :threshold thre))
  (setq *after-grasp-short-rav-list* (summarize-rav *after-grasp-short-rav-list* :threshold thre))
  (setq *release-short-rav-list* (summarize-rav *release-short-rav-list* :threshold thre))
  (setq *reset-short-rav-list* (summarize-rav *reset-short-rav-list* :threshold thre))
  )

(defun self-move-initial-pose-teaching ()
  (manequine-end)
  (send *robot* :reset-pose)

  (send *ri* :stop-grasp :rarm :wait t)

  (send *ri* :speak-jp "初期姿勢を教えて下さい")
  (unix:sleep 2)

  (wait-ok-manequine :arm (list "rarm" "head")) ;; OKと言われるまでマネキンモード
  (unix:sleep 2)
  (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  (setq *initial-av* (send *robot* :angle-vector))
  (setq *initial-head-neck-y* (send *robot* :head-neck-y :joint-angle))
  (setq *initial-head-neck-p* (send *robot* :head-neck-p :joint-angle))
  (unix:sleep 2)
  (send *ri* :start-grasp :rarm :wait t)
  )

(defun self-move-task-teaching-detail ()
  ;; 掴むまでの最初の動作教示
  (set-initial-av)
  (send *ri* :stop-grasp :rarm :wait t)
  ;; 最初の動作の開始点
  (send *ri* :speak-jp "掴むまでの最初の動作の開始点を教えて下さい")
  (unix:sleep 2)
  (wait-ok-manequine)
  (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  (send *robot* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *robot* :head-neck-p :joint-angle *initial-head-neck-p*)
  (setq *first-pregrasp-initial-av* (send *robot* :angle-vector))
  (setq *first-pregrasp-initial-rec* (send *robot* :rarm :end-coords))
  (unix:sleep 2)
  ;; 最初の動作
  (send *ri* :speak-jp "掴むまでの最初の動作を教えて下さい")
  (unix:sleep 2)
  (setq first-pregrasp-ans (record-rav-voice))
  (setq *first-pregrasp-short-rav-list* (elt first-pregrasp-ans 0))
  (setq *first-pregrasp-short-rec-list* (elt first-pregrasp-ans 1))
  (send *ri* :start-grasp :rarm :wait t)

  ;; 掴んだ後の動作を教わる
  (send *ri* :speak-jp "掴んだ後の動作を教えて下さい")
  (setq after-grasp-ans (record-rav-voice))
  (setq *after-grasp-short-rav-list* (elt after-grasp-ans 0))
  (setq *after-grasp-short-rec-list* (elt after-grasp-ans 1))


  ;; 手の離し方
  (send *ri* :speak-jp "手の離し方を教えて下さい")
  (send *ri* :stop-grasp :rarm :wait t);; TODO 離す時のグリッパの離し具合？
  (unix:sleep 2)
  (setq release-ans (record-rav-voice))
  (setq *release-short-rav-list* (elt release-ans 0))
  (setq *release-short-rec-list* (elt release-ans 1))

  ;; 戻し方を教わる
  (set-initial-av)
  (send *ri* :start-grasp :rarm :wait t);; tmp
  ;; 戻す動作の開始点を教わる
  (send *ri* :speak-jp "戻す動作の開始点を教えて下さい")
  (unix:sleep 2)
  (wait-ok-manequine)
  (send *robot* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *robot* :head-neck-p :joint-angle *initial-head-neck-p*)
  (setq *reset-initial-av* (send *robot* :angle-vector))
  (setq *reset-initial-rec* (send *robot* :rarm :end-coords))
  (unix:sleep 2)
  ;; 最初の動作
  (send *ri* :speak-jp "戻す動作を教えて下さい")
  (unix:sleep 2)
  (setq reset-ans (record-rav-voice))
  (setq *reset-short-rav-list* (elt reset-ans 0))
  (setq *reset-short-rec-list* (elt reset-ans 1))

  (set-initial-av)
  )

(defun self-move-short-teaching-test ()
  (send *ri* :start-grasp :rarm :wait t)
  (unix:sleep 1)
  (setq *no-obj-l-gri* (send *ri* :state :gripper :rarm :position))

  (self-move-initial-pose-teaching)
  (unix:sleep 1)
  (setq *obj-l-gri* (send *ri* :state :gripper :rarm :position))
  (set-initial-av)

  (self-move-task-teaching-detail)
  (set-initial-av)
  )

(defun self-move-short-replay-test ()
  ;; 初期姿勢になる
  (set-initial-av)
  (send *ri* :stop-grasp :rarm :wait t)
  (unix:sleep 2)

  ;; つかむまでの最初の動作
  (replay-short-rav-list *first-pregrasp-short-rav-list*)
  (unix:sleep 1)
  (send *ri* :start-grasp :rarm :wait t)

  ;; 掴んだあとの動作
  (replay-short-rav-list *after-grasp-short-rav-list*)
  (unix:sleep 1)

  ;; 手を離す動作
  (send *ri* :stop-grasp :rarm :wait t)
  (unix:sleep 2)
  (replay-rav-list *release-short-rav-list*)

  ;; 戻す動作
  (set-initial-av)
  (send *ri* :start-grasp :rarm :wait t);; tmp
  (unix:sleep 1)
  (replay-short-rav-list *reset-short-rav-list*)

  (unix:sleep 2)
  (set-initial-av)
  )

(defun self-move-short-teach-and-replay-test (&key (summarize t))
  ;; 動作を教わる
  (self-move-short-teaching-test)

  ;; 教わった動作を再生する
  (send *ri* :speak-jp "教わった動作を実行します")
  ;; summarize rav-list data if summarize t
  (if summarize
      ;; (summarize-datas :thre 0.5)
      ;; (summarize-datas :thre 0.5 :av-lists (list *first-pregrasp-short-rav-list* *after-grasp-short-rav-list* *release-short-rav-list* *reset-short-rav-list*))
      (self-move-summarize-datas :thre 0.5) ;; TODO
    )
  (self-move-short-replay-test)

  (send *ri* :speak-jp "動作を実行しました")
  )

(defun self-move-data-collection-test  (&key (times 10) (save_img nil) (save_avs t) (summarize t) (thre 0.5) (x 50) (y 50) (theta 0) (theta-positive t) (check-place nil) (dump_file_name "tmp-data-collection-setting.l"))
  (if check-place
      (progn
        ;; もし場所が移動していた場合は最初に掴ませてもらう？
        ;; 初期姿勢になる
        (set-initial-av)
        (send *ri* :stop-grasp :rarm :wait t)
        (replay-short-rav-list *first-pregrasp-short-rav-list*)
        (send *ri* :speak-jp "対象となるポイントをつかませて下さい")
        (unix:sleep 2)
        (wait-ok-manequine)
        (send *ri* :start-grasp :rarm :wait t)
        (manequine-end) ;; サーボonにする
        (send *robot* :angle-vector (send *ri* :state :potentio-vector))
        )
    (progn
      ;; 移動していない場合は最初に掴んだ状態からスタート
      ;; 初期姿勢になる
      (set-initial-av)
      (send *ri* :stop-grasp :rarm :wait t)
      (unix:sleep 2)
      ;; つかむまでの最初の動作
      (replay-short-rav-list *first-pregrasp-short-rav-list*)
      (unix:sleep 1)
      (send *ri* :start-grasp :rarm :wait t)
      )
    )
  ;; summarize rav-list data if summarize t
  (if summarize
      ;; (summarize-datas :thre thre)
      (self-move-summarize-datas :thre 0.5) ;; TODO
    )

  ;; random result list ;;tmp?
  (setq *random-res-list* (list))
  (setq *real-num-list* (list))
  (setq *obj-coords-list* (list))
  (setq *ik-flags* (list))

  ;; rav2rec
  (setq *first-pregrasp-short-rec-list* (rav2rec *first-pregrasp-short-rav-list*))
  (setq *after-grasp-short-rec-list* (rav2rec *after-grasp-short-rav-list*))
  (setq *release-short-rec-list* (rav2rec *release-short-rav-list*))
  (setq *reset-short-rec-list* (rav2rec *reset-short-rav-list*))
  ;; assoc rec to obj-coords
  (setq *obj-coords* (make-cascoords))
  (send *obj-coords* :newcoords (send (elt *after-grasp-short-rec-list* 0) :copy-worldcoords))
  (setq *initial-obj-coords* (send *obj-coords* :copy-worldcoords))
  (setq *first-pregrasp-assoc-short-rec-list* (assoc-rec-list *first-pregrasp-short-rec-list* *obj-coords*))
  (setq *after-grasp-assoc-short-rec-list* (assoc-rec-list *after-grasp-short-rec-list* *obj-coords*))
  (setq *release-assoc-short-rec-list* (assoc-rec-list *release-short-rec-list* *obj-coords*))
  (setq *reset-assoc-short-rec-list* (assoc-rec-list *reset-short-rec-list* *obj-coords*))

  ;; for random move
  (setq now-place (make-coords))
  (setq initial-now-place (send now-place :copy-worldcoords))
  (setq prev-x 0)
  (setq prev-y 0)
  (setq prev-theta 0)

  (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  (setq now-arm-coords (send (send *robot* :rarm :end-coords) :copy-worldcoords))
  (setq real-x (- (elt (send now-arm-coords :worldpos) 0) (elt (send *initial-obj-coords* :worldpos) 0)))
  (setq real-y (- (elt (send now-arm-coords :worldpos) 1) (elt (send *initial-obj-coords* :worldpos) 1)))
  (setq real-theta-raw (elt (elt (send (send *initial-obj-coords* :transformation now-arm-coords) :rpy-angle) 0) 0))
  (setq real-theta (rad2deg real-theta-raw))
  (send *obj-coords* :newcoords (send *initial-obj-coords* :copy-worldcoords))
  (send *obj-coords* :translate (float-vector real-x real-y 0) :wolrd)
  (send *obj-coords* :rotate (deg2rad real-theta-raw) :z)
  (format t "[real] x-num: ~A y-num: ~A theta-num: ~A ~%" real-x real-y real-theta) ;; 現在の位置とデータ収集時の差分　;; TODO この差分を使ってその後のrealとかも補正する?
  (send *ri* :speak-jp "自動のデータ収集を開始します")
  (dotimes (i times)

    ;; 移動して動作をするか考える
    (setq *ik-ok-flag* nil)
    (until *ik-ok-flag*
           ;; サーボをoffにする
           (send *ri* :start-grasp :rarm :wait t)
           (servo-off-mode :arm (list "rarm"))

           ;; ちょっと移動する
           (setq target-place (random-coords initial-now-place :x x :y y :theta theta :theta-positive theta-positive))
           (send *ri* :go-pos-unsafe (* (- *x-num* prev-x) 0.001) (* (- *y-num* prev-y) 0.001) (- *theta-num* prev-theta))
           (setq prev-x *x-num*)
           (setq prev-y *y-num*)
           (setq prev-theta *theta-num*)
           (unix:sleep 2)

           ;; 現在の腕の位置から座標を取る
           (manequine-end) ;; サーボonにする
           (send *robot* :angle-vector (send *ri* :state :potentio-vector))
           ;; (send *obj-coords* :newcoords  (send (send *robot* :rarm :end-coords) :copy-worldcoords)) ;; この時にx,yとthetaだけの回転にしたい．
           (setq now-arm-coords (send (send *robot* :rarm :end-coords) :copy-worldcoords))
           ;; (setq real-x (elt (send (send *initial-obj-coords* :transformation now-arm-coords :world) :pos) 0))
           ;; (setq real-y (elt (send (send *initial-obj-coords* :transformation now-arm-coords :world) :pos) 1))
           (setq real-x (- (elt (send now-arm-coords :worldpos) 0) (elt (send *initial-obj-coords* :worldpos) 0)))
           (setq real-y (- (elt (send now-arm-coords :worldpos) 1) (elt (send *initial-obj-coords* :worldpos) 1)))
           (setq real-theta-raw (elt (elt (send (send *initial-obj-coords* :transformation now-arm-coords) :rpy-angle) 0) 0))
           (setq real-theta (rad2deg real-theta-raw))
           (send *obj-coords* :newcoords (send *initial-obj-coords* :copy-worldcoords))
           (send *obj-coords* :translate (float-vector real-x real-y 0) :wolrd)
           (send *obj-coords* :rotate (deg2rad real-theta-raw) :z)
           (format t "x-num: ~A y-num: ~A theta-num: ~A ~%" *x-num* *y-num* *theta-num*)
           (format t "[real] x-num: ~A y-num: ~A theta-num: ~A ~%" real-x real-y real-theta)

           ;; IKが解けるか確認
           (setq ik-first-pregrasp-flag (ik-check *first-pregrasp-assoc-short-rec-list*))
           (setq ik-after-grasp-flag (ik-check *after-grasp-assoc-short-rec-list*))
           (setq ik-release-flag (ik-check *release-assoc-short-rec-list*))
           (setq ik-reset-flag (ik-check *reset-assoc-short-rec-list*))
           ;; (if (and ik-first-pregrasp-flag ik-after-grasp-flag ik-release-flag ik-reset-flag)
           ;;     (setq *ik-ok-flag* t)
           ;;   )
           (format t "fist: ~A, after: ~A, release: ~A, reset: ~A ~%" ik-first-pregrasp-flag ik-after-grasp-flag ik-release-flag ik-reset-flag)
           (setq ik-first-pregrasp-flag (ik-check *first-pregrasp-assoc-short-rec-list*))
           (if ik-first-pregrasp-flag
               (setq *ik-ok-flag* t)
             )
           )
    ;; tmp
    (setq *ik-flags* (append *ik-flags* (list (list ik-first-pregrasp-flag ik-after-grasp-flag ik-release-flag ik-reset-flag))))
    (setq now-place (send target-place :copy-worldcoords))
    ;; 腕を離す
    (send *ri* :stop-grasp :rarm :wait t)
    (send *robot* :rarm :move-end-pos #f(-100 0 0))
    (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
    (send *ri* :wait-interpolation)

    ;; データ収集
    (set-initial-av)
    (send *ri* :stop-grasp :rarm :wait t)
    (unix:sleep 2)
    ;; 最初のつかむまでの動作
    (if save_avs
        (progn
          (data-collection-start)
          (start-data-collection :service "first_pregrasp_data_collection_rosbag/start_request")
          ;; (start-data-collection :service "set_whole_data_collection_rosbag/start_request")
          ))
    (unix:sleep 2)
    (replay-short-rec-list *first-pregrasp-assoc-short-rec-list*)

    ;; つかむ
    (send *ri* :start-grasp :rarm :wait t)
    (unix:sleep 2)
    (if save_avs
        (end-data-collection :service "first_pregrasp_data_collection_rosbag/end_request")
      )
    ;; TODO ここにも動作checkの関数が必要？

    ;; ;; 掴んだあとの動作
    ;; (replay-short-rec-list *after-grasp-assoc-short-rec-list*)
    ;; (if save_avs
    ;;     (end-data-collection :service "set_whole_data_collection_rosbag/end_request")
    ;;   )

    ;; ;; 離す動作
    ;; (send *ri* :stop-grasp :rarm :wait t)
    ;; (unix:sleep 2)
    ;; (replay-short-rec-list *release-assoc-short-rec-list*)

    ;; ;; 戻す動作
    ;; (set-initial-av)
    ;; (send *ri* :start-grasp :rarm :wait t)
    ;; (unix:sleep 2)
    ;; (if save_avs
    ;;     (progn
    ;;       (data-collection-start)
    ;;       (start-data-collection :service "reset_data_collection_rosbag/start_request")
    ;;       ))
    ;; (unix:sleep 3)
    ;; (replay-short-rec-list *reset-assoc-short-rec-list*)
    ;; (if save_avs
    ;;     (end-data-collection :service "reset_data_collection_rosbag/end_request")
    ;;   )

    ;; (unix:sleep 2)
    ;; (set-initial-av)

    ;; ;; 最後にまたつかむ動作
    ;; (send *ri* :stop-grasp :rarm :wait t)
    ;; (unix:sleep 2)
    ;; (replay-short-rec-list *first-pregrasp-assoc-short-rec-list*)
    ;; (send *ri* :stop-grasp :rarm :wait t)
    ;; (unix:sleep 2)

    (setq *grasp-fail-flag* nil)
    (grasp-fail-check *no-obj-l-gri* *obj-l-gri*)
    (if *grasp-fail-flag*
        (progn
          (send *ri* :speak-jp "つかむ動作に失敗したので助けて下さい")
          (send *ri* :stop-grasp :rarm :wait t)
          (replay-short-rav-list *first-pregrasp-short-rav-list*)
          (ok-wait)
          )
      )
    (setq *random-res-list* (append *random-res-list* (list (list *x-num* *y-num* *theta-num* (not *grasp-fail-flag*)))))
    (setq *real-num-list* (append *real-num-list* (list (list real-x real-y real-theta))))
    (setq *obj-coords-list* (append *obj-coords-list* (list (send *obj-coords* :copy-worldcoords))))
    )
  (send *ri* :speak-jp "自動のデータ収集が終了しました")
  (self-move-dump-data-collection-setting-list :file_name dump_file_name)
  )

(defun self-move-dump-data (&key (file_name "tmp-self-move-teaching-data.l"))
  (dump-loadable-structure file_name *no-obj-l-gri* *obj-l-gri* *initial-av* *initial-head-neck-y* *initial-head-neck-p* *first-pregrasp-short-rav-list* *after-grasp-short-rav-list* *release-short-rav-list* *reset-short-rav-list*)
  (format t "data dumped in ~A ~%" file_name)
  )

(defun self-move-load-from-file (&key (file_name "tmp-self-move-teaching-data.l") (summarize t) (thre 0.5))
  (load file_name)
  ;; summarize rav-list data if summarize t
  (if summarize
      (self-move-summarize-datas :thre thre)
    )
  (format t "data loaded from ~A ~%" file_name)
  (format t "no-obj-l-gri : ~A ~%" *no-obj-l-gri*)
  (format t "obj-l-gri : ~A ~%" *obj-l-gri*)
  (format t "initial-av : ~A ~%" *initial-av*)
  (format t "first-pregrasp-short-rav-list size : ~A ~%" (length *first-pregrasp-short-rav-list*))
  (format t "after-grasp-short-rav-list size : ~A ~%" (length *after-grasp-short-rav-list*))
  (format t "release-short-rav-list size : ~A ~%" (length *release-short-rav-list*))
  (format t "reset-short-rav-list size : ~A ~%" (length *reset-short-rav-list*))
  )

(defun self-move-dump-data-collection-setting-list (&key (file_name "tmp-self-dump-data-collection-setting.l"))
  (dump-loadable-structure file_name *random-res-list* *real-num-list* *obj-coords-list* *no-obj-l-gri* *obj-l-gri* *initial-av* *initial-head-neck-y* *initial-head-neck-p* *first-pregrasp-short-rav-list* *after-grasp-short-rav-list* *release-short-rav-list* *reset-short-rav-list*)
  (format t "data dumped in ~A ~%" file_name)
  )


;; cook test
(defun cook-initial-pose-teaching (&key (larm nil)) ;; 道具を握らせて貰って初期姿勢を教わる
  (manequine-end)
  (send *robot* :reset-manip-pose)

  (send *ri* :wait-interpolation)

  (if larm
      (send *ri* :stop-grasp :larm :wait t)
    (send *ri* :stop-grasp :rarm :wait t))

  (send *ri* :speak-jp "初期姿勢を教えて下さい")
  (unix:sleep 2)

  (wait-ok-manequine :arm (list "rarm" "larm")) ;; OKと言われるまでマネキンモード
  (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  (send *robot* :head-neck-y :joint-angle 0.0)
  (send *robot* :head-neck-p :joint-angle 50.0)
  (setq *initial-av* (send *robot* :angle-vector))
  (unix:sleep 2)
  (send *ri* :start-grasp :rarm :wait t) ;; TODO 持つ強さ？
  (send *ri* :start-grasp :larm :wait t) ;; TODO 持つ強さ？

  ;; tmp
  (setq *initial-head-neck-y* (send *robot* :head-neck-y :joint-angle))
  (setq *initial-head-neck-p* (send *robot* :head-neck-p :joint-angle))
  )

(defun cook-teach (&key (initial-teach nil) (larm nil))
  (if initial-teach
      (cook-initial-pose-teaching :larm larm)
    )

  (set-initial-av)

  ;; 混ぜかたを教わる
  (send *ri* :speak-jp "調理動作の開始地点を教えて下さい")
  (unix:sleep 2)
  (if larm
      (wait-ok-manequine :arm (list "larm"))
    (wait-ok-manequine :arm (list "rarm")))
  (send *robot* :head-neck-y :joint-angle 0.0)
  ;; (send *robot* :head-neck-p :joint-angle 60.0)
  (send *robot* :head-neck-p :joint-angle 50.0)
  (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  (setq *cook-initial-av* (send *robot* :angle-vector))
  (if larm
      (setq *cook-initial-lec* (send *robot* :larm :end-coords))
    (setq *cook-initial-rec* (send *robot* :rarm :end-coords)))
  (unix:sleep 2)
  (send *ri* :start-grasp :rarm :wait t) ;; TODO 持つ強さ？

  ;; 物体の置き方を教わる
  (send *ri* :speak-jp "調理動作を教えて下さい")
  (unix:sleep 2)
  (if larm
      (progn
          (setq place-ans (record-rav-voice :arm "larm"))
          (setq *cook-short-lav-list* (elt place-ans 0))
          (setq *cook-short-lec-list* (elt place-ans 1))
          )
    (progn
      (setq place-ans (record-rav-voice))
      (setq *cook-short-rav-list* (elt place-ans 0))
      (setq *cook-short-rec-list* (elt place-ans 1))
      ))
  (set-initial-av)
  )

(defun cook-teach-whole ()
  (cook-initial-pose-teaching)

  (cook-teach)
  )

(defun cook-replay (&key (save_img t) (save_bag nil) (rosbag_time 5))
  (if save_img
      (progn
        ;; データの保存
        (set-initial-av)
        (trigger-request "/cook_data_collection/save_request")
        ))

  (do-until-key
   (set-initial-av)

   (unix:sleep 2)
   (replay-short-rav-list *cook-short-rav-list*)

   (set-initial-av)

   ;; (do-until-key
   ;;  (print "wait key")
   ;;  )
   (if save_img
       (progn
         ;; データの保存
         (trigger-request "/cook_data_collection/save_request")
         ))

   (if save_bag
       (progn
         ;; データの保存
         (start-data-collection :service "cook_data_collection_rosbag/start_request");; rosbag収集開始
         (unix:sleep rosbag_time)
         (end-data-collection :service "cook_data_collection_rosbag/end_request");; rosbag収集終了
         ))
   )
  )

(defun test-pan-today ()
  (cook-teach)

  (send *ri* :speak-jp "教わった動作を実行します")

  (cook-replay-today)
  )

(defun cook-replay-today (&key (save_img nil) (save_bag nil) (rosbag_time 5))
  (if save_img
      (progn
        ;; データの保存
        (set-initial-av)
        (trigger-request "/cook_data_collection/save_request")
        ))

  ;; (do-until-key
   (set-initial-av :time 2000)

   (unix:sleep 1)
   (replay-short-rav-list *cook-short-rav-list* :time 150)

   (set-initial-av :time 2000)

   ;; (do-until-key
   ;;  (print "wait key")
   ;;  )
   (if save_img
       (progn
         ;; データの保存
         (trigger-request "/cook_data_collection/save_request")
         ))

   (if save_bag
       (progn
         ;; データの保存
         (start-data-collection :service "cook_data_collection_rosbag/start_request");; rosbag収集開始
         (unix:sleep rosbag_time)
         (end-data-collection :service "cook_data_collection_rosbag/end_request");; rosbag収集終了
         ))
   ;; )
  )


(defun cook-replay-wait (&key (save_img t) (save_bag nil) (rosbag_time 5))
  (if save_img
      (progn
        ;; データの保存
        (set-initial-av)
        (trigger-request "/cook_data_collection/save_request")
        ))

  (while t
   (set-initial-av)

   (unix:sleep 2)
   (replay-short-rav-list *cook-short-rav-list*)

   (set-initial-av)

   (do-until-key
    (print "wait key")
    (unix:sleep 1)
    )
   (if save_img
       (progn
         ;; データの保存
         (trigger-request "/cook_data_collection/save_request")
         ))

   (if save_bag
       (progn
         ;; データの保存
         (start-data-collection :service "cook_data_collection_rosbag/start_request");; rosbag収集開始
         (unix:sleep rosbag_time)
         (end-data-collection :service "cook_data_collection_rosbag/end_request");; rosbag収集終了
         ))
   )
  )

(defun cook-replay-once (&key (save_img t) (save_bag nil) (rosbag_time 5) (larm nil) (initial-av t))
  (if initial-av
      (set-initial-av))

  (unix:sleep 2)
  (if larm
      (replay-short-rav-list *cook-short-lav-list* :larm t)
    (replay-short-rav-list *cook-short-rav-list*))

  (if initial-av
      (set-initial-av))
  )

(defun cook-replay-rec-once (&key (save_img t) (save_bag nil) (rosbag_time 5) (larm nil) (initial-av t) (trans-vec #f(0 0 0)))
  (if initial-av
      (set-initial-av))

  (unix:sleep 2)
  (if larm
      (progn
        (setq *cook-short-lec-list* (rav2rec *cook-short-lav-list* :arm :larm))
        (replay-short-rec-list *cook-short-lec-list* :larm t :trans-vec trans-vec)
        )
    (progn
      (setq *cook-short-rec-list* (rav2rec *cook-short-rav-list*))
      (replay-short-rec-list *cook-short-rec-list* :trans-vec trans-vec)
    ))

  (if initial-av
      (set-initial-av))
  )


(defun dump-cook-file (&key (file_name "tmp-cook-teaching-data.l") (larm nil))
  (if larm
      (dump-loadable-structure file_name *initial-av* *cook-short-lav-list*)
    (dump-loadable-structure file_name *initial-av* *cook-short-rav-list*))
  ;; (dump-loadable-structure file_name *initial-av* *cook-short-rav-list* *initial-head-neck-y* *initial-head-neck-p*)
  (format t "data dumped in ~A ~%" file_name)
  )


(defun summarize-cook-datas (&key (thre 0.5) (larm nil))
  (if larm
      (setq *cook-short-lav-list* (summarize-rav *cook-short-lav-list* :threshold thre :larm t))
    (setq *cook-short-rav-list* (summarize-rav *cook-short-rav-list* :threshold thre)))
  )

(defun load-cook-file (&key (file_name "tmp-cook-teaching-data.l") (summarize t) (thre 0.5) (larm nil))
  (load file_name)
  ;; summarize rav-list data if summarize t
  (if summarize
      (summarize-cook-datas :thre thre :larm larm)
      )
  (setq *initial-head-neck-y* (elt *initial-av* 15))
  ;; (setq *initial-head-neck-p* (elt *initial-av* 16))
  (setq *initial-head-neck-p* 50)
  (format t "data loaded from ~A ~%" file_name)
  ;; (format t "cook-short-rav-list size : ~A ~%" (length *cook-short-rav-list*))
  )



(defun cook-from-now-teach (&key (larm nil))
  (unix:sleep 3)
  (send *ri* :speak-jp "現在の姿勢を記憶します" :wait t)
  (if larm
      (progn
        (setq *cook-from-now-use-arm* :larm)
        (setq *cook-from-now-initial-arm-av* (send *robot* :larm :angle-vector))
        )
    (progn
      (setq *cook-from-now-use-arm* :rarm)
      (setq *cook-from-now-initial-arm-av* (send *robot* :rarm :angle-vector))
      )
    )

  ;; 調理動作を教わる
  (send *ri* :speak-jp "記憶しました" :wait t)
  (unix:sleep 2)
  (send *ri* :speak-jp "調理動作の開始地点を教えて下さい" :wait t)
  (unix:sleep 1)
  (if larm
      (wait-ok-manequine :arm (list "larm"))
    (wait-ok-manequine :arm (list "rarm")))
  (send *robot* :head-neck-y :joint-angle 0.0)
  ;; (send *robot* :head-neck-p :joint-angle 60.0)
  (send *robot* :head-neck-p :joint-angle 50.0)
  (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  ;; (setq *cook-initial-av* (send *robot* :angle-vector))
  (if larm
      (progn
        (setq *cook-initial-lec* (send *robot* :larm :end-coords))
        (unix:sleep 2)
        ;; (send *ri* :start-grasp :larm :wait t) ;; TODO 持つ強さ？
        )
    (progn
      (setq *cook-initial-rec* (send *robot* :rarm :end-coords))
      (unix:sleep 2)
      ;; (send *ri* :start-grasp :rarm :wait t) ;; TODO 持つ強さ？
      )
    )

  ;; 物体の置き方を教わる
  (send *ri* :speak-jp "調理動作を教えて下さい" :wait t)
  (unix:sleep 2)
  (if larm
      (progn
          (setq place-ans (record-rav-voice :arm "larm"))
          (setq *cook-short-lav-list* (elt place-ans 0))
          (setq *cook-short-lec-list* (elt place-ans 1))
          )
    (progn
      (setq place-ans (record-rav-voice))
      (setq *cook-short-rav-list* (elt place-ans 0))
      (setq *cook-short-rec-list* (elt place-ans 1))
      ))
  (set-cook-from-now-initial-arm-av :larm larm)
  )

(defun dump-cook-from-now-file (&key (file_name "tmp-cook-from-now-teaching-data.l") (larm nil))
  (if larm
      (dump-loadable-structure file_name *cook-from-now-initial-arm-av* *cook-short-lav-list*)
    (dump-loadable-structure file_name *cook-from-now-initial-arm-av* *cook-short-rav-list*))
  ;; (dump-loadable-structure file_name *initial-av* *cook-short-rav-list* *initial-head-neck-y* *initial-head-neck-p*)
  (format t "data dumped in ~A ~%" file_name)
  )

(defun load-cook-from-now-file (&key (file_name "tmp-cook-from-now-teaching-data.l") (summarize t) (thre 0.5) (larm nil))
  (load file_name)
  ;; summarize rav-list data if summarize t
  (if summarize
      (summarize-cook-datas :thre thre :larm larm)
    )
  (setq *initial-head-neck-y* 0)
  (setq *initial-head-neck-p* 50)
  (format t "data loaded from ~A ~%" file_name)
  ;; (format t "cook-short-rav-list size : ~A ~%" (length *cook-short-rav-list*))
  )

(defun rotate-gripper-av (arm-av rotate-deg)
  (let (ans-av)
    (setq ans-av (float-vector (elt arm-av 0) (elt arm-av 1) (elt arm-av 2) (elt arm-av 3) (elt arm-av 4) (elt arm-av 5) (+ (elt arm-av 6) rotate-deg)))
    ans-av))

(defun rotate-cook-from-now (&key (larm nil) (rotate-deg 360))
  (let (current-ans-list (list))
    (setq *cook-from-now-initial-arm-av* (rotate-gripper-av *cook-from-now-initial-arm-av* rotate-deg))
    (if larm
        (progn
          (dolist (current-arm-av *cook-short-lav-list*)
            (setq current-ans-list (append current-ans-list (list (rotate-gripper-av current-arm-av rotate-deg))))
            )
          (setq *cook-short-lav-list* current-ans-list))
      (progn
        (dolist (current-arm-av *cook-short-rav-list*)
          (setq current-ans-list (append current-ans-list (list (rotate-gripper-av current-arm-av rotate-deg))))
          )
        (setq *cook-short-rav-list* current-ans-list))
      )
    ))


(defun cook-from-now-replay-once (&key (larm nil) (initial-av t) (reverse nil) (each-step nil) (time 150))
  (if initial-av
      (set-cook-from-now-initial-arm-av :larm larm)
    )

  (unix:sleep 2)
  (if larm
      (progn
        (if reverse
            (replay-short-rav-list (reverse *cook-short-lav-list*) :larm t :each-step each-step :time time)
          (replay-short-rav-list *cook-short-lav-list* :larm t :each-step each-step :time time))
        )
    (progn
      (if reverse
          (replay-short-rav-list (reverse *cook-short-rav-list*) :each-step each-step :time time)
        (replay-short-rav-list *cook-short-rav-list* :each-step each-step :time time)
        )))

  (if initial-av
      (set-cook-from-now-initial-arm-av :larm larm)
    )
  )

(defun cook-from-now-replay-rec-once (&key (larm nil) (initial-av t) (trans-vec #f(0 0 0)) (each-step nil))
  (if initial-av
      (set-cook-from-now-initial-arm-av :larm larm))

  (unix:sleep 2)
  (if larm
      (progn
        (setq *cook-short-lec-list* (rav2rec *cook-short-lav-list* :arm :larm))
        (replay-short-rec-list *cook-short-lec-list* :larm t :trans-vec trans-vec :each-step each-step)
        )
    (progn
      (setq *cook-short-rec-list* (rav2rec *cook-short-rav-list*))
      (replay-short-rec-list *cook-short-rec-list* :trans-vec trans-vec :each-step each-step)
      ))

  (if initial-av
      (set-cook-from-now-initial-arm-av :larm larm))
  )



(defun cook-pick-and-pour-teaching-detail (&key (initial-teach nil))
  (if initial-teach
      (cook-initial-pose-teaching)
    )
  ;; 掴むまでの最初の動作教示
  (set-initial-av)
  (send *ri* :stop-grasp :rarm :wait t)
  ;; 最初の動作の開始点
  (send *ri* :speak-jp "掴むまでの最初の動作の開始点を教えて下さい")
  (unix:sleep 2)
  (wait-ok-manequine)
  (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  (send *robot* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *robot* :head-neck-p :joint-angle *initial-head-neck-p*)
  (setq *first-pregrasp-initial-av* (send *robot* :angle-vector))
  (setq *first-pregrasp-initial-rec* (send *robot* :rarm :end-coords))
  (unix:sleep 2)
  ;; 最初の動作
  (send *ri* :speak-jp "掴むまでの最初の動作を教えて下さい")
  (unix:sleep 2)
  (setq first-pregrasp-ans (record-rav-voice))
  (setq *first-pregrasp-short-rav-list* (elt first-pregrasp-ans 0))
  (setq *first-pregrasp-short-rec-list* (elt first-pregrasp-ans 1))
  (send *ri* :start-grasp :rarm :wait t)

  ;; 掴んだ後の動作を教わる
  (send *ri* :speak-jp "掴んだ後の動作を教えて下さい")
  (setq after-grasp-ans (record-rav-voice))
  (setq *after-grasp-short-rav-list* (elt after-grasp-ans 0))
  (setq *after-grasp-short-rec-list* (elt after-grasp-ans 1))


  ;; 手の離し方
  (send *ri* :speak-jp "手の離し方を教えて下さい")
  (send *ri* :stop-grasp :rarm :wait t);; TODO 離す時のグリッパの離し具合？
  (unix:sleep 2)
  (setq release-ans (record-rav-voice))
  (setq *release-short-rav-list* (elt release-ans 0))
  (setq *release-short-rec-list* (elt release-ans 1))

  ;; 初期姿勢に戻る
  (set-initial-av)
  )


(defun cook-pick-and-pour-short-replay-test ()
  ;; 初期姿勢になる
  (set-initial-av)
  (send *ri* :stop-grasp :rarm :wait t)
  (unix:sleep 2)

  ;; つかむまでの最初の動作
  (replay-short-rav-list *first-pregrasp-short-rav-list*)
  (unix:sleep 1)
  (send *ri* :start-grasp :rarm :wait t)

  ;; 掴んだあとの動作
  (replay-short-rav-list *after-grasp-short-rav-list*)
  (unix:sleep 1)

  ;; 手を離す動作
  (send *ri* :stop-grasp :rarm :wait t)
  (unix:sleep 2)
  (replay-rav-list *release-short-rav-list*)

  (unix:sleep 2)
  (set-initial-av)
  )

(defun cook-pick-short-replay-test ()
  ;; 初期姿勢になる
  (set-initial-av)
  (send *ri* :stop-grasp :rarm :wait t)
  (unix:sleep 2)

  ;; つかむまでの最初の動作
  (replay-short-rav-list *first-pregrasp-short-rav-list*)
  (unix:sleep 1)
  (send *ri* :start-grasp :rarm :wait t)
  )

(defun cook-pour-short-replay-test ()
  ;; 掴んだあとの動作
  (replay-short-rav-list *after-grasp-short-rav-list* :time 150)
  (unix:sleep 1)

  ;; 手を離す動作
  (send *ri* :stop-grasp :rarm :wait t)
  (unix:sleep 1)
  (replay-rav-list *release-short-rav-list* :time 100)

  (set-initial-av :time 1000)
  )

(defun dump-cook-pour-file (&key (file_name "tmp-cook-pour-teaching-data.l"))
  (dump-loadable-structure file_name *initial-av* *first-pregrasp-short-rav-list* *after-grasp-short-rav-list* *release-short-rav-list*)
  (format t "data dumped in ~A ~%" file_name)
  )

(defun summarize-cook-pour-datas (&key (thre 0.5)) ;;TODO リストのリスト処理で書き換えたい
  (setq *first-pregrasp-short-rav-list* (summarize-rav *first-pregrasp-short-rav-list* :threshold thre))
  (setq *after-grasp-short-rav-list* (summarize-rav *after-grasp-short-rav-list* :threshold thre))
  (setq *release-short-rav-list* (summarize-rav *release-short-rav-list* :threshold thre))
  )

(defun load-cook-pour-file (&key (file_name "tmp-cook-pour-teaching-data.l") (summarize t) (thre 0.5))
  (load file_name)
  ;; summarize rav-list data if summarize t
  (if summarize
      (summarize-cook-pour-datas :thre thre)
    )
  (setq *initial-head-neck-y* (elt *initial-av* 15))
  ;; (setq *initial-head-neck-p* (elt *initial-av* 16))
  (setq *initial-head-neck-p* 50)
  (format t "data loaded from ~A ~%" file_name)
  (format t "initial-av : ~A ~%" *initial-av*)
  (format t "first-pregrasp-short-rav-list size : ~A ~%" (length *first-pregrasp-short-rav-list*))
  (format t "after-grasp-short-rav-list size : ~A ~%" (length *after-grasp-short-rav-list*))
  (format t "release-short-rav-list size : ~A ~%" (length *release-short-rav-list*))
  )

;; add for lc_state_recognition
(defun clip-query-change (&key (yes-query "Melted butter") (no-query "Hard butter"))
  (let (prompt)
    (setq prompt (format nil "~A;~A" yes-query no-query))
    (ros::set-dynamic-reconfigure-param "/clip_ros_client" "clip_queries" :string prompt)
    (format t "clip prompt is changed to ~A ~%" prompt)
    ))

(defun lc_state_recognition-command (&key (yes-query "Melted butter") (no-query "Hard butter") (raw-threshold 0.4) (sma-threshold 0.5))
  (let (res)
    (setq req (instance lc_state_recognition::StateChangeRecognitionRequest :init))
    (send req :yes_query yes-query)
    (send req :no_query no-query)
    (send req :raw_threshold raw-threshold)
    (send req :sma_threshold sma-threshold)
    (setq res (ros::service-call "/state_recognition/command" req t))
    (format t "lc_state_recognition command is sent! ~%")
    (format t "result : ~A ~%" res)
    )
  )

(defun described_gazing_area_detector-command (&key (query-list (list "the content of the pot" "the content of the frying pan" "the content of the bowl")))
  (let (res)
    (setq req (instance lc_state_recognition::GazingAreaDetectionStartRequest :init))
    (send req :queries query-list)
    (setq res (ros::service-call "/described_gazing_area_detector/start_request" req t))
    (format t "described_gazing_area_detector command is sent! ~%")
    (format t "result : ~A ~%" res)
    )
  )

(defun lc_adjusted_clip_state_recognition-command (&key (model_file "") (target_state ""))
  (let (res)
    (setq req (instance lc_state_recognition::AdjustedClipStateRecognitionStartRequest :init))
    (send req :model_file model_file)
    (send req :target_state target_state)
    (setq res (ros::service-call "/adjusted_clip_state_recognizer/start_request" req t))
    (format t "lc_adjusted_clip_state_recognition command is sent! ~%")
    (format t "result : ~A ~%" res)
    )
  )

(defun lc_adjusted_clip_stop-command ()
  (let (res)
    (setq req (instance std_srvs::TriggerRequest :init))
    (setq res (ros::service-call "/adjusted_clip_state_recognizer/stop_request" req t))
    (format t "lc_adjusted_clip_stop command is sent! ~%")
    )
  )

(defun state-cb (msg)
  (print msg)
  (setq *hoge* msg)
  (setq data (send msg :data))
  (if (equal data *yes-query*)
      (progn
        (setq *yes-flag* t)
        (if *speak-jp* (send *ri* :speak-jp "状態変化を認識しました")
          (send *ri* :speak-en "I recognized the state change."))
        ))
  )

(defun ok-voice-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *voice-data* (send *msg* :transcript))
    (setq *voice-data-flag* t)
    (format t "voice-data: ~A ~%" *voice-data*)
    (if (equal *voice-data* '("OK"))
        (progn
          (if *speak-jp* (send *ri* :speak-jp "ありがとうございます")
            (send *ri* :speak-en "Thank you!"))
          (format t "了解しました！ ~%" *voice-data*)
          (setq *yes-flag* t)
          ))
    )
  )

;; (manequine-end)
