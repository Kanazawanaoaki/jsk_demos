(ros::roseus "pr2_move_utils")

(ros::load-ros-manifest "pr2_msgs")

;; move params related
(defun show-current-move-params ()
  (let ((xy-goal-tolerance)
        (yaw-goal-tolerance)
        (global-footprint-padding)
        (local-footprint-padding))
    (setq xy-goal-tolerance
          (ros::get-param "/move_base_node/DWAPlannerROS/xy_goal_tolerance"))
    (setq yaw-goal-tolerance
          (ros::get-param "/move_base_node/DWAPlannerROS/yaw_goal_tolerance"))
    (setq global-footprint-padding
          (ros::get-param "/move_base_node/global_costmap/footprint_padding"))
    (setq local-footprint-padding
          (ros::get-param "/move_base_node/local_costmap/footprint_padding"))
    (format t "[current move params]~%")
    (format t "xy-goal-tolerance:~A, yaw-goal-tolerance:~A, global-footprint-padding:~A, local-footprint-padding:~A~%" xy-goal-tolerance yaw-goal-tolerance global-footprint-padding local-footprint-padding)
    t))

(defun change-move-params (&rest args)
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/DWAPlannerROS" "xy_goal_tolerance" :double 0.10)
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/DWAPlannerROS" "yaw_goal_tolerance" :double 0.087)  ;; 5deg
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/global_costmap" "footprint_padding" :double 0.03)
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/local_costmap" "footprint_padding" :double 0.03)
  (show-current-move-params)
  t)

(defun store-move-params (&rest args)
  (defparameter *xy-goal-tolerance*
    (ros::get-param "/move_base_node/DWAPlannerROS/xy_goal_tolerance"))
  (defparameter *yaw-goal-tolerance*
    (ros::get-param "/move_base_node/DWAPlannerROS/yaw_goal_tolerance"))
  (defparameter *global-footprint-padding*
    (ros::get-param "/move_base_node/global_costmap/footprint_padding"))
  (defparameter *local-footprint-padding*
    (ros::get-param "/move_base_node/local_costmap/footprint_padding"))
  ;; (defparameter *look-at-human-enabled*
  ;;   (send (one-shot-subscribe "look_at_human/enabled" std_msgs::Bool) :data))
  ;; (call-service "look_at_human/stop" (instance std_srvs::EmptyRequest :init))
  t)

(defun restore-move-params (&rest args)
  (when (boundp '*xy-goal-tolerance*)
    (ros::set-dynamic-reconfigure-param
     "/move_base_node/DWAPlannerROS" "xy_goal_tolerance"
     :double *xy-goal-tolerance*))
  (when (boundp '*yaw-goal-tolerance*)
    (ros::set-dynamic-reconfigure-param
     "/move_base_node/DWAPlannerROS" "yaw_goal_tolerance"
     :double *yaw-goal-tolerance*))
  (when (boundp '*global-footprint-padding*)
    (ros::set-dynamic-reconfigure-param
     "/move_base_node/global_costmap" "footprint_padding"
     :double *global-footprint-padding*))
  (when (boundp '*local-footprint-padding*)
    (ros::set-dynamic-reconfigure-param
     "/move_base_node/local_costmap" "footprint_padding"
     :double *local-footprint-padding*))
  (when (and (boundp '*look-at-human-enabled*) *look-at-human-enabled*)
    (call-service "look_at_human/start" (instance std_srvs::EmptyRequest :init)))
  (show-current-move-params)
  t)

(defun set-default-move-params (&rest args)
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/DWAPlannerROS" "xy_goal_tolerance"
   :double 0.2)
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/DWAPlannerROS" "yaw_goal_tolerance"
   :double 0.17)
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/global_costmap" "footprint_padding"
   :double 0.1)
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/local_costmap" "footprint_padding"
   :double 0.1)
  (show-current-move-params)
  t)

;; wait until movable
(defun wait-cable-out ()
  (setq *cable-flag* t)
  (while *cable-flag*
    (let ((msg (one-shot-subscribe "/power_state" pr2_msgs::PowerState)))
      (setq *cable-flag* (< 0 (send msg :AC_present)))
      (unix::sleep 1)))
  )

(defun wait-cable-in ()
  (setq *cable-flag* t)
  (while *cable-flag*
    (let ((msg (one-shot-subscribe "/power_state" pr2_msgs::PowerState)))
      (setq *cable-flag* (>= 0 (send msg :AC_present)))
      (unix::sleep 1)))
  )

(defun cable-test ()
  (let ((msg (one-shot-subscribe "/power_state" pr2_msgs::PowerState)))
    (format t "now AC_present is ~A ~%" (send msg :AC_present))
    msg))

(defun speech-before-move-with-rec ()
  (let ((msg (cable-test)))
    (if (< 0 (send msg :AC_present))
        (progn
          (send *ri* :speak-jp "移動するので電源ケーブルを抜いて下さい")
          (wait-cable-out)
          (send *ri* :speak-jp "ありがとうございます" :wait t)
          )
      (send *ri* :speak-jp "移動を開始します")
      )
    ))

(defun speech-after-move-with-rec ()
  (let ((msg (cable-test)))
    (if (< 0 (send msg :AC_present))
        (send *ri* :speak-jp "調理を再開します")
      (progn
        (send *ri* :speak-jp "移動が完了しました．電源ケーブルを挿して下さい")
        (wait-cable-in)
        (send *ri* :speak-jp "ありがとうございます．調理を再開します" :wait t)
        ))
    ))
