(defun calc-av (a)
  (let ((num (length a))
        (sum 0.0))    
    (dolist (i a)
      (setq sum (+ sum i))
      )
    (/ sum num)))

(defun calc-var (a av)
  (let ((num (length a))
        (sos 0.0)) ;; sum of squares   
    (dolist (i a)
      (setq sos (+ sos (* (- i av) (- i av))))
      )
    (/ sos num)))

(defun sigma-section-test (num av sd sigma)
  (let ((err (abs (- num av)))
        (res t))
    (if (> err (* sigma sd))
        (setq res nil)
      )
    res))

(defun min-max-test (num min max)
  (let ((res t))
    (if (< num min)
        (setq res nil))
    (if (> num max)
        (setq res nil))
    res))

(defun sigma-check (num lis sigma)
  (let (av v sd)
    (setq av (calc-av lis))
    (setq v (calc-var lis av))
    (setq sd (sqrt v))
    (sigma-section-test num av sd sigma)
    ))


(defun list-check (num lis sigma)
  (let (av v sd s-res m-res (res t))
    (setq av (calc-av lis))
    (setq v (calc-var lis av))
    (setq sd (sqrt v))
    (setq max (apply #'max lis))
    (setq min (apply #'min lis))
    (unless (sigma-section-test num av sd sigma)
      (setq res nil))
    (unless (min-max-test num min max)
      (setq res nil))
    res))

;; add for sense
(ros::roseus "stove_rec_test" :anonymous t)
(setq *topic-name* "/right_endeffector/wrench")
(ros::load-ros-manifest "geometry_msgs")

;; (setq *x-thre* -15)
;; (setq *cb-flag* nil)
;; (defun wrench-x-cb (msg)
;;   (when msg
;;     (setq *msg* msg)
;;     (let (n x y z)
;;       (setq x (send msg :wrench :force :x))
;;       (setq y (send msg :wrench :force :y))
;;       (setq z (send msg :wrench :force :z))
;;       (setq n (norm (float-vector x  y z)))
;;       (if (< n *x-thre*)
;;           (progn 
;;             (setq *cb-flag* t)
;;             (format t "OK!! norm: ~A ~%" n)
;;             )
;;         (format t "norm: ~A ~%" n))
;;       )))


;; (ros::unsubscribe "/right_endeffector/wrench")
;; (setq *topic-name* "/right_endeffector/wrench")
;; (setq *cb-flag* nil)
;; (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-x-cb)

;; (defun test ()
;;   (do-until-key
;;    (ros::spin-once)
;;    (ros::sleep)
;;    )
;;   )

;; (test)




(setq *wrench-list* (list))
(defun wrench-reg-cb (msg)
  (when msg
    (let (n x y z)
      (setq x (send msg :wrench :force :x))
      (setq y (send msg :wrench :force :y))
      (setq z (send msg :wrench :force :z))
      (setq n (norm (float-vector x  y z)))
      (setq *wrench-list* (append *wrench-list* (list n)))
      (format t "norm: ~A ~%" n)
      )))

(ros::unsubscribe "/right_endeffector/wrench")
(setq *topic-name* "/right_endeffector/wrench")
(setq *cb-flag* nil)
(ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-reg-cb)

(defun test ()
  (setq *wrench-list* (list))
  (do-until-key
   (ros::spin-once)
   (ros::sleep)
   )
  (setq *AV* (calc-av *wrench-list*))
  (setq *V* (calc-var *wrench-list* *AV*))
  (setq *SD* (sqrt *V*))
  (setq *MAX* (apply #'max *wrench-list*))
  (setq *MIN* (apply #'min *wrench-list*))
  
  (format t "average: ~A , variance: ~A , standard deviation: ~A , max: ~A , min: ~A ~%" *AV* *V* *SD* *MAX* *MIN*)
  )

(test)


