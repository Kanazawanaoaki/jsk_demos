;; トピックなどを定義
(defvar *topic-name* "/segmentation_decomposer/boxes")

;; ros init
(ros::roseus "carrot_rec_test" :anonymous t)
(ros::load-ros-manifest "jsk_recognition_msgs")
(setq *l* (instance ros::transform-listener :init))
(setq found-obj nil)
(setq obj-pos #f(0 0 0))
(setq obj-coord (make-coords :pos #f(0 0 0)))
(print 0)


;; define cb
(defun object-pose-cb (msg)
  (setq *msg* msg)
  (setq *bbox* (car (send msg :boxes)))
  (print 1)
  (setq found-obj t)
  )


;; subscribeして認識
;; (ros::subscribe *topic-name* jsk_recognition_msgs::BoundingBoxArray #'object-pose-cb 1)

(setq found-obj nil)
(until found-obj
  (print 4)

  (setq msg (one-shot-subscribe *topic-name* jsk_recognition_msgs::BoundingBoxArray))
  (object-pose-cb msg)
  )



(setq *y-thre* -12)

;; add for sense
(ros::load-ros-manifest "geometry_msgs")
(setq *cb-flag* nil)
(defun wrench-y-cb (msg)
  (when msg
    (let ((y nil))
      (setq y (send msg :wrench :force :y))
      (if (< y *y-thre*)
          (progn 
            (setq *cb-flag* t)
            (format t "OK!! y: ~A ~%" y)
            )
        (format t "y: ~A ~%" y))
      )))


;; 皮剥き始める所
(setq *topic-name* "/right_endeffector/wrench")
(setq *cb-flag* nil)

;; (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)
;; (ros::subscribe *topic-name* geometry_msgs::WrenchStamped #'wrench-y-cb)

(until *cb-flag*
       (setq msg (one-shot-subscribe *topic-name* geometry_msgs::WrenchStamped))
       (wrench-y-cb msg)
       )

(warn "test is end !!! ~%")
