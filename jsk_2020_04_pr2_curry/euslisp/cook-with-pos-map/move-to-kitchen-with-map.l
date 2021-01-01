(require :pr2-interface "package://pr2eus/pr2-interface.l")
(require :eng2-scene "package://jsk_2020_04_pr2_curry/euslisp/model/my-eng2-scene.l")

(defun init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/my-eng2-coords.l")
  
  ;; init ROS Node
  (ros::roseus "pr2-move-with-maps")
  
  ;; init 73B2 room
  (unless (boundp '*scene*) (setq *scene* (make-eng2-scene)))
  
  ;; init PR2
  (unless (boundp '*pr2*) (setq *pr2* (instance pr2-sensor-robot :init)))
  (unless (boundp '*ri*) (setq *ri* (instance pr2-interface :init)))
  (send *pr2* :move-to (send *ri* :state :worldcoords) :world)
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (load "models/arrow-object.l")
  (setq *arrow* (arrow))
  
  (objects (list *scene* *pr2*))

  ;; set global variables
  (setq *s-time* 3)
  (setq *w-time* 2)
  (setq *debug-flag* nil)
  )

(defun update-view ()
  (send *pr2* :copy-worldcoords)
  (send *viewer* :draw-objects)
  (send *irtviewer* :look-all *pr2*)           
  )

(defun update-scene ()
  (objects (list *scene* *pr2*))
  (send *irtviewer* :look-all *pr2*)           
  )

(defun update-pos ()
  (send *pr2* :move-to (send *ri* :state :worldcoords) :world)
  (update-view)
  (print (send *ri* :state :worldcoords))
  )

(init)
(update-view)

(warn "~% If you use real robot, run (update-pos) ~%")
(warn "please run (move-to-kitchen-ri) , (move-to-sink-ri) or (move-to-stove-ri) and (set-pose)~%")

;; add for voice recognition
(ros::load-ros-manifest "speech_recognition_msgs")
(setq *ok-flag* nil)
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

;; IRT上の移動
(defun move-to-kitchen-irt ()
  (send *pr2* :move-to (send *kitchen-spot* :copy-worldcoords) :world)
  (update-view)
  )
(defun move-to-sink-irt ()
  (send *pr2* :move-to (send *sink-spot* :copy-worldcoords) :world)
  (update-view)
  )
(defun move-to-stove-irt ()
  (send *pr2* :move-to (send *stove-spot* :copy-worldcoords) :world)
  (update-view)
  )
(defun move-to-microwave-irt ()
  (send *pr2* :move-to (send *microwave-spot* :copy-worldcoords) :world)
  (update-view)
  )
(defun move-to-seasoning-irt ()
  (send *pr2* :move-to (send *seasoning-spot* :copy-worldcoords) :world)
  (update-view)
  )
(defun move-to-arrange-irt ()
  (send *pr2* :move-to (send *arrange-spot* :copy-worldcoords) :world)
  (update-view)
  )

;; 実機の移動
(defun move-to-kitchen-ri ()
  (send *ri* :clear-costmap)
  ;; (send *ri* :move-to (make-coords :pos #f(1200 8500 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
  (setq local-flag (send *ri* :move-to (make-coords :pos #f(1400 8500 351) :rpy (float-vector pi 0 0)) :frame-id "/map"))
  (if (eql local-flag t)
      (progn
        (send *ri* :go-pos-unsafe 0.2 0 0)
        (warn "go-pos unsafe !! ~%")
        )
    (send *ri* :speak-jp "移動に失敗しました，アシストして下さい")
    )
  (print (send *ri* :state :worldcoords))
  )

(defun move-to-sink-ri ()
  ;; コンロまで移動する
  (send *ri* :clear-costmap)
  ;; (send *ri* :move-to (make-coords :pos #f(1110 9100 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
  (setq local-flag (send *ri* :move-to (make-coords :pos #f(1400 9100 351) :rpy (float-vector pi 0 0)) :frame-id "/map"))
  (if (eql local-flag t)
      (progn   (send *ri* :go-pos-unsafe 0.29 0 0)
               )
    (send *ri* :speak-jp "移動に失敗しました，アシストして下さい")
    )
  (print (send *ri* :state :worldcoords))
  )

(defun move-to-stove-ri ()
  (send *ri* :clear-costmap)
  ;; (send *ri* :move-to (make-coords :pos #f(1200 8100 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
  (setq local-flag (send *ri* :move-to (make-coords :pos #f(1400 8100 351) :rpy (float-vector pi 0 0)) :frame-id "/map"))
  (if (eql local-flag t)
      (progn
        (send *ri* :go-pos-unsafe 0.2 0 0)
        (warn "go-pos unsafe !! ~%")
        )
    (send *ri* :speak-jp "移動に失敗しました，アシストして下さい")
    )
  (print (send *ri* :state :worldcoords))
  )

(defun move-to-microwave-ri ()
  ;; 電子レンジまで移動する
  (send *ri* :clear-costmap)
  ;; (send *ri* :move-to (make-coords :pos #f(1700 9400 351) :rpy (float-vector 0 0 0)) :frame-id "/map")
  (send *ri* :move-to (make-coords :pos #f(1600 9300 351) :rpy (float-vector 0 0 0)) :frame-id "/map")
  (print (send *ri* :state :worldcoords))
  )

(defun move-to-seasoning-ri ()
  ;; 調味料まで移動する
  (send *ri* :clear-costmap)
  (send *ri* :move-to (make-coords :pos #f(1700 8900 351) :rpy (float-vector 0 0 0)) :frame-id "/map")
  (print (send *ri* :state :worldcoords))
  )

(defun move-to-arrange-ri ()
  (send *ri* :clear-costmap)
  ;; (send *ri* :move-to (make-coords :pos #f(1200 8200 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
  (setq local-flag (send *ri* :move-to (make-coords :pos #f(1400 8200 351) :rpy (float-vector pi 0 0)) :frame-id "/map"))
  (if (eql local-flag t)
      (progn
        (send *ri* :go-pos-unsafe 0.2 0 0)
        (warn "go-pos unsafe !! ~%")
        )
    (send *ri* :speak-jp "移動に失敗しました，アシストして下さい")
    )
  (print (send *ri* :state :worldcoords))
  )

;; kitchen spotとsink間の移動
(defun go-to-sink ()
  ;; kitchen spotからsinkに移動する
  (send *ri* :go-pos-unsafe 0 -0.6 0)
  (send *ri* :go-pos-unsafe 0.09 0 0)
  (update-pos)
  (update-view)
  (print (send *ri* :state :worldcoords))
  )

(defun go-to-kitchen-from-sink ()
  ;; sinkからkitchen spotに移動する
  (send *ri* :go-pos-unsafe -0.09 0 0)  
  (send *ri* :go-pos-unsafe 0 0.6 0)
  (update-pos)
  (update-view)
  (print (send *ri* :state :worldcoords))
  )

(defun go-to-stove ()
  ;; kitchen spotからstoveに移動する
  (send *ri* :go-pos-unsafe 0 0.4 0)
  (update-pos)
  (update-view)
  (print (send *ri* :state :worldcoords))
  )

(defun go-to-kitchen-from-stove ()
  ;; stoveからkitchen spotに移動する
  (send *ri* :go-pos-unsafe 0 -0.4 0)
  (update-pos)
  (update-view)
  (print (send *ri* :state :worldcoords))
  )


(defun go-to-microwave () ;; TODO
  ;; kitchenからmicrowaveに移動する
  
  )

(defun go-to-sink-from-arrange ()
  ;; arrange spotからsinkに実行する
  (send *ri* :go-pos-unsafe 0 -0.9 0)
  (send *ri* :go-pos-unsafe 0.09 0 0)
  (update-pos)
  (update-view)
  (print (send *ri* :state :worldcoords))
  )

(defun go-to-arrnage-from-sink ()
  ;; sinkからarrange spotに移動する
  (send *ri* :go-pos-unsafe -0.09 0 0)  
  (send *ri* :go-pos-unsafe 0 0.9 0)
  (update-pos)
  (update-view)
  (print (send *ri* :state :worldcoords))
  )

(defun go-to-sink-from-stove ()
  ;; stoveからsinkに移動する ;; TODO 確認
  (send *ri* :go-pos-unsafe 0 -0.4 0)
  (send *ri* :go-pos-unsafe 0 -0.4 0)
  (update-pos)
  (update-view)
  (print (send *ri* :state :worldcoords))  
  )

(defun go-to-stove-from-sink ()
  ;; sinkからstoveに移動する
  (send *ri* :go-pos-unsafe 0 0.4 0)
  (send *ri* :go-pos-unsafe 0 0.4 0)
  (update-pos)
  (update-view)
  (print (send *ri* :state :worldcoords))  
  )

;; def util-funcs
(defun set-pose ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun set-pose-rec ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *pr2* :head_tilt_joint :joint-angle 0)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )



;; move with speech
(defun speech-before-move ()
  (send *ri* :speak-jp "移動するので電源ケーブルを抜いて，合図して下さい")
  (ros::unsubscribe "/speech_to_text")
  (setq *ok-flag* nil)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'voice-ok-cb)
  (until *ok-flag*
	 (ros::spin-once)
	 (ros::sleep)
	 )

  (send *ri* :speak-jp "ありがとうございます．移動を開始します")
  )

(defun speech-after-move ()
  (send *ri* :speak-jp "電源ケーブルを挿して，合図して下さい")
  
  (ros::unsubscribe "/speech_to_text")
  (setq *ok-flag* nil)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'voice-ok-cb)
  (until *ok-flag*
	 (ros::spin-once)
	 (ros::sleep)
	 )  
  (send *ri* :speak-jp "ありがとうございます．調理を再開します")
  )


(defun go-to-stove-with-speech-before ()
  ;; kitchen spot(拠点)からstoveに移動する
  (speech-before-move)
  (unix:sleep *w-time*)
  (go-to-stove)
  )

(defun go-to-stove-with-speech-after ()
  ;; kitchen spotからstove(拠点)に移動する
  (go-to-stove)
  (speech-after-move)
  (unix:sleep *w-time*)
  )

(defun go-to-stove-with-speech-before-and-after ()
  ;; kitchen spotからstoveに移動し，拠点も移動させる  
  (speech-before-move)
  (unix:sleep *w-time*)
  (go-to-stove)
  (speech-after-move)
  (unix:sleep *w-time*)
  )

(defun go-to-kithen-from-stove-with-speech-after ()
  ;; stoveからkitchen spot(拠点)に移動する
  (go-to-kitchen-from-stove)
  (speech-after-move)
  (unix:sleep *w-time*)
  )

(defun go-to-kithen-from-stove-with-speech-before ()
  ;; stove(拠点)からkitchen spotに移動する
  (speech-before-move)
  (unix:sleep *w-time*)
  (go-to-kitchen-from-stove)
  )


(defun go-to-sink-with-speech-before ()
  ;; kitchen spot(拠点)からsinkに移動する
  (speech-before-move)
  (unix:sleep *w-time*)
  (go-to-sink)  
  )

(defun go-to-kithen-from-sink-with-speech-after ()
  ;; sinkからkitchen spot(拠点)に移動する
  (go-to-kitchen-from-sink)
  (speech-after-move)
  (unix:sleep *w-time*)
  )


;; TODO stove→microwave， microwave→arrnage
