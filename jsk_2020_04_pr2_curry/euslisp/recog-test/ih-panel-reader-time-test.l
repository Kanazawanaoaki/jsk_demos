(defun init ()
  (ros::roseus "panel-reader-test")

  (setq *topic-name* "/ih_stove_reader/result")
  (ros::load-ros-manifest "roseus")
  (setq *cb-flag* nil)
  )

(init)


(defun panel-reader-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :data))
    (format t "~A ~%" *data*)
    (if (ros::time> (send *msg* :header :stamp) *now*)
        (setq *cb-flag* t)
      )
    ))

(defun read-panel ()
  (setq *now* (ros::time-now))
  (ros::unsubscribe *topic-name*)
  (setq *cb-flag* nil)
  (ros::subscribe *topic-name* roseus::StringStamped #'panel-reader-cb)
  (until *cb-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  )

(warn "please run (read-panel) ~%")
