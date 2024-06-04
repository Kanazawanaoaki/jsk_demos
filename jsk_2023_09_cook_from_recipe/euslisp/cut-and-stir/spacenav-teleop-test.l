#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_tmp.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/wrench.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/move-to-adjust.l")

;; ros init
(ros::roseus "pr2_spacenav_teleop" :anonymous t)
(ros::load-ros-manifest "sensor_msgs")

(load "models/arrow-object.l")
(setq *arrow* (arrow))
(objects (list *arrow* *pr2*))


;; define cb
(defun spacenav-joy-cb (msg)
  (print (send msg :axes))
  (print (send msg :buttons))
  (setq spacenav-trans-thre 0.4)
  (setq spacenav-trans-step 20) ;; TODO use scale instead?
  (setq spacenav-rot-thre 0.4)
  (setq spacenav-rot-step 10)

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (setq now-coords (send (send *pr2* *spacenav-arm* :end-coords) :copy-worldcoords))
  (setq *now-axes* (send msg :axes))
  (setq change-flag nil)

  ;; x
  (if (> (elt (send msg :axes) 0) spacenav-trans-thre)
      (progn
        (send now-coords :translate (float-vector spacenav-trans-step 0 0) :world)
        (setq change-flag t)
        )
    )
  (if (< (elt (send msg :axes) 0) (* -1.0 spacenav-trans-thre))
      (progn
        (send now-coords :translate (float-vector (* -1.0 spacenav-trans-step) 0 0) :world)
        (setq change-flag t)
        )
    )
  ;; y
  (if (> (elt (send msg :axes) 1) spacenav-trans-thre)
      (progn
        (send now-coords :translate (float-vector 0 spacenav-trans-step 0) :world)
        (setq change-flag t)
        )
    )
  (if (< (elt (send msg :axes) 1) (* -1.0 spacenav-trans-thre))
      (progn
        (send now-coords :translate (float-vector 0 (* -1.0 spacenav-trans-step) 0) :world)
        (setq change-flag t)
        )
    )
  ;; z
  (if (> (elt (send msg :axes) 2) spacenav-trans-thre)
      (progn
        (send now-coords :translate (float-vector 0 0 spacenav-trans-step) :world)
        (setq change-flag t)
        )
    )
  (if (< (elt (send msg :axes) 2) (* -1.0 spacenav-trans-thre))
      (progn
        (send now-coords :translate (float-vector 0 0 (* -1 spacenav-trans-step)) :world)
        (setq change-flag t)
        )
    )

  ;; roll
  (if (> (elt (send msg :axes) 3) spacenav-rot-thre)
      (progn
        (send now-coords :rotate (deg2rad spacenav-rot-step) :x :world)
        (setq change-flag t)
        )
    )
  (if (< (elt (send msg :axes) 3) (* -1.0 spacenav-rot-thre))
      (progn
        (send now-coords :rotate (deg2rad (* -1 spacenav-rot-step)) :x :world)
        (setq change-flag t)
        )
    )
  ;; pitch
  (if (> (elt (send msg :axes) 4) spacenav-rot-thre)
      (progn
        (send now-coords :rotate (deg2rad spacenav-rot-step) :y :world)
        (setq change-flag t)
        )
    )
  (if (< (elt (send msg :axes) 4) (* -1.0 spacenav-rot-thre))
      (progn
        (send now-coords :rotate (deg2rad (* -1 spacenav-rot-step)) :y :world)
        (setq change-flag t)
        )
    )
  ;; yaw
  (if (> (elt (send msg :axes) 5) spacenav-rot-thre)
      (progn
        (send now-coords :rotate (deg2rad spacenav-rot-step) :z :world)
        (setq change-flag t)
        )
    )
  (if (< (elt (send msg :axes) 5) (* -1.0 spacenav-rot-thre))
      (progn
        (send now-coords :rotate (deg2rad (* -1 spacenav-rot-step)) :z :world)
        (setq change-flag t)
        )
    )

  ;; switch arm
  (if (= (elt (send msg :buttons) 0) 1)
      (if (equal *spacenav-arm* :rarm)
          (setq *spacenav-arm* :larm)
        (setq *spacenav-arm* :rarm)
        )
      )
  ;; gripper
  (if (= (elt (send msg :buttons) 1) 1)
      (if (and (equal *spacenav-arm* :rarm) (equal *r-gripper-state* nil))
          (progn
            (send *ri* :start-grasp :rarm :gain *spacenav-r-grasp-gain* :wait t)
            (setq *r-gripper-state* t)
            )
        )
      (if (and (equal *spacenav-arm* :rarm) (equal *r-gripper-state* t))
          (progn
            ;; (send *ri* :stop-grasp :rarm :wait t)
            (send *ri* :move-gripper :rarm *spacenav-r-gripper-dis* :effort (* 2000 0.03) :wait t)
            (setq *r-gripper-state* nil)
            )
        )
      (if (and (equal *spacenav-arm* :larm) (equal *l-gripper-state* nil))
          (progn
            (send *ri* :start-grasp :larm :gain *spacenav-r-grasp-gain* :wait t)
            (setq *l-gripper-state* t)
            )
        )
      (if (and (equal *spacenav-arm* :larm) (equal *l-gripper-state* t))
          (progn
            ;; (send *ri* :stop-grasp :larm :wait t)
            (send *ri* :move-gripper :larm *spacenav-l-gripper-dis* :effort (* 2000 0.03) :wait t)
            (setq *l-gripper-state* nil)
            )
        )
      )

  (if change-flag
      (progn
        (send *pr2* :head-neck-y :joint-angle *spacenav-init-head-y*)
        (send *pr2* :head-neck-p :joint-angle *spacenav-init-head-p*)
        (send *pr2* *spacenav-arm* :inverse-kinematics (send now-coords :copy-worldcoords))
        (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
        (send *ri* :wait-interpolation)
        )
    )
  (send *arrow* :newcoords (send now-coords :copy-worldcoords))
  (send *viewer* :draw-objects)
  (send *irtviewer* :look-all (list *pr2* *arrow*))
  )


(defun spacenav-teleop (&key (init-pose (send *pr2* :reset-manip-pose)) (r-grasp-gain 0.01) (l-grasp-gain 0.01) (r-gripper-dis 0.09) (l-gripper-dis 0.09) (pose-initialize t))
  (manequine-end)
  (speak-with-log "3Dマウスの操縦を開始します")
  (if pose-initialize
      (progn
        (send *pr2* :angle-vector init-pose)
        (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
        (send *ri* :wait-interpolation)
        )
    )
  ;; set default
  (setq *spacenav-arm* :rarm)
  (setq *spacenav-r-grasp-gain* r-grasp-gain)
  (setq *spacenav-l-grasp-gain* l-grasp-gain)
  (setq *spacenav-r-gripper-dis* r-gripper-dis)
  (setq *spacenav-l-gripper-dis* l-gripper-dis)

  ;; todo use (send *ri* :state :gripper :larm :position) and set the  gripper-state
  ;; (if (>= (send *ri* :state :))
  ;; (setq **)
  (setq *spacenav-r-gripper-state* nil)
  (setq *spacenav-l-gripper-state* nil)
  (setq *spacenav-init-head-y* (send *pr2* :head-neck-y :joint-angle))
  (setq *spacenav-init-head-p* (send *pr2* :head-neck-p :joint-angle))

  (ros::unsubscribe "/spacenav/joy")
  (ros::subscribe "/spacenav/joy"
                  sensor_msgs::Joy #'spacenav-joy-cb 1)

  (ros::rate 10)
  (do-until-key
   ;; (x::window-main-one) ;; IRT viewerの視点を変えられる。見にくければ変えよう
   (ros::spin-once)
   (ros::sleep))
  (speak-with-log "3Dマウスの操縦を終了します")
  )

(format t "Please run (spacenav-teleop) ~%")
