#!/usr/bin/env roseus

;; (ros::load-ros-manifest "roseus")
(ros::load-ros-manifest "std_srvs")
p
(ros::roseus "test_data_collection")
(ros::wait-for-service "after_stow_data_collection/save_request")
(setq req (instance std_srvs::TriggerRequest :init))

(defun test ()
  (setq res (ros::service-call "after_stow_data_collection/save_request" req t))
  )
