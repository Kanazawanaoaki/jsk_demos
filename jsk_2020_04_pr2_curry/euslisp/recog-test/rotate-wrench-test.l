(load "package://pr2eus/pr2-interface.l")
(pr2-init)

(send *ri* :state)
(send *pr2* :angle-vector (send *ri* :state :potentio-vector))

(objects (list *pr2*))





;; check mizukumi rec
(ros::roseus "bowl_transfer_test" :anonymous t)
(ros::load-ros-manifest "geometry_msgs")

(setq *mizukumi-flag* nil)
;; (setq *mizukumi-thre* -2) ;; mcup
(setq *mizukumi-thre* 2) ;; rcup

(defun check-mizukumi ()
  (let (msg force z)
    ;; virtual force の値を取得する
    (setq msg (one-shot-subscribe "/left_endeffector/wrench" geometry_msgs::WrenchStamped))
    (setq force (send msg :wrench :force))
    
    (setq *vec* (float-vector (send force :x) (send force :y) (send force :Z)))
    
    ;; 変換する
    (send (send *pr2* :larm :end-coords) :rotate-vector *vec*) ;;これで変換できる
    (setq z (elt *vec* 2))
    (format t "z force is ~A ~%" z)
    
    ;; 判定する
    (if (< z *mizukumi-thre*)
        (progn 
          (setq *mizukumi-flag* t)
          (warn "mizukumi seikou")
          )
      )
    )  
  )


(warn "please run (check-mizukumi)")
