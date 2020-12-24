;; add for sense
(setq *x-thre* -15)

(ros::roseus "stove_rec_test" :anonymous t)
(setq *topic-name* "/right_endeffector/wrench")
(ros::load-ros-manifest "geometry_msgs")
(setq *cb-flag* nil)

(defun wrench-x-cb (msg)
  (when msg
    (setq *msg* msg)
    (let (n x y z)
      (setq x (send msg :wrench :force :x))
      (setq y (send msg :wrench :force :y))
      (setq z (send msg :wrench :force :z))
      (setq n (norm (float-vector x  y z)))
      (if (< n *x-thre*)
          (progn 
            (setq *cb-flag* t)
            (format t "OK!! norm: ~A ~%" n)
            )
        (format t "norm: ~A ~%" n))
      )))


(ros::unsubscribe "/right_endeffector/wrench")
(setq *topic-name* "/right_endeffector/wrench")
(setq *cb-flag* nil)
(ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-x-cb)

(defun test ()
  (do-until-key
   (ros::spin-once)
   (ros::sleep)
   )
  )

(test)

