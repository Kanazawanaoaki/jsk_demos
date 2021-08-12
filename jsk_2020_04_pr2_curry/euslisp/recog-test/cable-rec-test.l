(ros::roseus "cable_rec_test" :anonymous t)
(ros::load-ros-manifest "pr2_msgs")

(defun cable-wait ()
  (setq *cable* t)
  (while *cable*
    (let ((msg (one-shot-subscribe "/power_state" pr2_msgs::PowerState)))
      (setq *cable* (<= 0 (send msg :AC_present)))
      (unix::sleep 1)))
  )


(defun cable-test ()
  (setq msg (one-shot-subscribe "/power_state" pr2_msgs::PowerState))
  (format t "now AC_present is ~A ~%" (send msg :AC_present))
  )


(warn "please run (cable-wait) or (cable-test) ! ~%")
