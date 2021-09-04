(defun init ()
  (ros::roseus "panel-reader-test")

  (setq *topic-name* "/ih_stove_reader/result")
  (ros::load-ros-manifest "roseus")
  (setq *cb-flag* nil)
  )

(init)

;; subscribe topic
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
  (warn "please run (read-data) ~%")
  )


;; read data
(defun string2num (string)
  (let (num)
    (cond
     ((equal string "1")
      (setq num 1))
     ((equal string "2")
      (setq num 2))
     ((equal string "3")
      (setq num 3))
     ((equal string "4")
      (setq num 4))
     ((equal string "5")
      (setq num 5))
     ((equal string "6")
      (setq num 6))
     ((equal string "7")
      (setq num 7))
     ((equal string "8")
      (setq num 8))
     ((equal string "9")
      (setq num 9))
     )
    num))

(defun read-data ()
  (let (num-data num)
    (setq num-data (string-trim "p" (string-trim "/" *data*)))
    (setq num (string2num num-data))
    num))

(warn "please run (read-panel) ~%")
