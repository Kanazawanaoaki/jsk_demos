(require :pr2-interface "package://pr2eus/pr2-interface.l")
(require :eng2-scene "package://jsk_maps/src/eng2-scene.l")

(defun init ()
  
  ;; init ROS Node
  (ros::roseus "pr2-move-with-maps")
  
  ;; init 73B2 room
  (unless (boundp '*scene*) (setq *scene* (make-eng2-scene)))
  
  ;; init PR2
  (unless (boundp '*pr2*) (setq *pr2* (instance pr2-sensor-robot :init)))
  (unless (boundp '*ri*) (setq *ri* (instance pr2-interface :init)))
  (send *pr2* :move-to (send *ri* :state :worldcoords) :world)
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  
  ;; ;; set spots
  (setq *kitchen-spot* (make-coords :pos (float-vector 1200 8500 30000) :rpy (float-vector pi 0 0)))
  (setq *sink-spot* (make-coords :pos (float-vector 1100 9100 30000) :rpy (float-vector pi 0 0)))
  (setq *stove-spot* (make-coords :pos (float-vector 1400 8100 30000) :rpy (float-vector pi 0 0)))
  (setq *microwave-spot* (make-coords :pos (float-vector 1700 9400 30000) :rpy (float-vector pi 0 0)))
  (setq *seasoning-spot* (make-coords :pos (float-vector 1700 8900 30000) :rpy (float-vector pi 0 0)))
  
  (setq */eng2/7f/room73B2-front-of-kitchenboard* (send *scene* :spot "/eng2/7f/room73B2-front-of-kitchenboard"))
  )

(defun update-view ()
  (objects (list *scene* *pr2*))
  (send *irtviewer* :look-all *pr2*)           
  )

(defun update-pos ()
  (send *pr2* :move-to (send *ri* :state :worldcoords) :world)
  )

(init)

(warn "please run (move-to-kitchen-ri) , (move-to-sink-ri) (move-to-stove-ri) and (set-pose)~%")


;; IRT上の移動
(defun move-to-kitchen-irt ()
  (send *pr2* :move-to (send *kitchen-spot* :copy-worldcoords) :world)
  )

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
  )

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

(move-to-kitchen-irt)

;; set for recognize robot's pos
(setq local-cds (make-coords :pos (float-vector 709.078 235.518 1524.735) :rpy (float-vector -3.101 0.632 -0.036)))
;; (setq true-cds (make-coords :pos))
(setq *k-panel* (make-cube 70 55 10))
(send *k-panel* :move-to *pr2* :world)
(send *k-panel* :transform (send local-cds :copy-worldcoords))

(objects (list *pr2* *k-panel* *scene*))
(update-view)


(defun recognition ()
  (setq k-pos (float-vector 0 0 0))
  (dotimes (i 10)
    (setq local-cds (check-detection :type "microwave" :speak-name "denshirenji" :timeout 10 :speak nil))
    (send *k-panel* :move-to *pr2* :world)
    (send *k-panel* :transform (send local-cds :copy-worldcoords))
    (setq k-pos (v+ k-pos (send *k-panel* :pos)))
    )
  (send *k-panel* :newcoords (make-coords :pos (scale 0.1 k-pos)))
  (send *k-panel* :rotate (deg2rad 90) :y)
  (send *k-panel* :translate #f(35 27.5 0))  
  )


;; 自己位置修正
