#!/usr/bin/env roseus  

;; add for rec
(ros::roseus "microwave_rec_test" :anonymous t)
(ros::load-ros-package "roseus")

(defun microwave-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq data (send *msg* :data))
    (format t "~A ~%" data)
    )
  )

(ros::subscribe "/microwave_reader/result" roseus::StringStamped #'microwave-cb)
(do-until-key
 (ros::spin-once)
 (ros::sleep)
 )


