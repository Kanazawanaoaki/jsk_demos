(ros::roseus "pr2_move_utils")

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
