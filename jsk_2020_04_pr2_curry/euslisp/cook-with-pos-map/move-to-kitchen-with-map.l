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
    (send *ri* :speak-jp "移動に失敗しました")
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
    (send *ri* :speak-jp "移動に失敗しました")
    )
  (print (send *ri* :state :worldcoords))
  )

(defun move-to-stove-ri ()
  ;; コンロまで移動する
  (send *ri* :clear-costmap)
  (send *ri* :move-to (make-coords :pos #f(1400 8100 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
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

;; kitchen spotとsink間の移動
(defun go-to-sink ()
  ;; kitchen spotからsinkに実行する
  (send *ri* :go-pos-unsafe 0 -0.6 0)
  (send *ri* :go-pos-unsafe 0.09 0 0)
  (update-pos)
  (update-view)
  (print (send *ri* :state :worldcoords))
  )

(defun go-to-kitchen ()
  ;; sinkからkitchen spotに移動する
  (send *ri* :go-pos-unsafe -0.09 0 0)  
  (send *ri* :go-pos-unsafe 0 0.6 0)
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
