(defun cut-carrot-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  
  ;; set cutting board
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/cutting-board.l")
  (setq *cutting-board* (cutting-board))
  (send *cutting-board* :newcoords (send *cutting-board-coords* :copy-worldcoords))
  
  ;; set global variables
  (setq adj 0)
  (setq adj2 0)
  
  
  (move-to-kitchen-irt)
  (objects (list *pr2* *scene* *cutting-board*))
  (update-view)  
  )

(cut-carrot-init)

(warn "If you use real robot, run (update-pos) ~%")
(warn "please run (now-transfer) or (now-transfer-bowl-1) ~%")


;; set for recognition

;; トピックを定義
(setq *bbox-topic-name* "/segmentation_decomposer/boxes")

;; ros init
(ros::roseus "vegs_rec_test" :anonymous t)
(ros::load-ros-manifest "jsk_recognition_msgs")
(setq *l* (instance ros::transform-listener :init))
(setq found-obj nil)
(print 0)

;; define cb
(defun object-pose-cb (msg)
  (setq *msg* msg)
  (setq *bbox* (car (send msg :boxes)))
  ;; (print 1)
  (when msg
    (when (send *msg* :boxes)
      (let ((cam-coords nil))
	(setq tm2 (send *l* :get-latest-common-time "base_footprint" "head_mount_kinect_rgb_optical_frame"))    
	(setq *dim* (send *bbox* :dimensions))
	(setq width (* (send *dim* :x) 1000))
	(setq length (* (send *dim* :y) 1000))
	(setq height (* (send *dim* :z) 1000))
	(setq *pose* (send *bbox* :pose))
	(setq cam->obj-coords (ros::tf-pose->coords *pose*))
	(when (send *l* :wait-for-transform  "base_footprint" "head_mount_kinect_rgb_optical_frame" tm2 10)
	  (setq cam-coords (send (send *pr2* :copy-worldcoords) :transform 
				 (send *l* :lookup-transform "base_footprint" "head_mount_kinect_rgb_optical_frame" tm2))))
	(when cam-coords
	  (setq obj-coord (send cam-coords :transform cam->obj-coords))
	  (setq tmp (- (+ (elt (send obj-coord :pos) 2) (/ height 2)) (+ (elt (send *cutting-board* :worldpos) 2) 10)))
	  (send obj-coord :translate (float-vector 0 0 (- (/ height 2) (/ tmp 2))) :world)
	  (setq height tmp)
        
	  (setq obj-pos (scale 0.001 (send obj-coord :worldpos)))
	  (if (> width 0)
	      (progn
		(setq found-obj t)
		(setq *width* width)
		(setq *length* length)
		(setq *height* height)
		(setq *obj-coord* obj-coord)
		))
	  (print (list 'found? found-obj obj-pos)))
	obj-pos))))
  
;; add for sense
(ros::load-ros-manifest "geometry_msgs")
(defun wrench-y-cb (msg)
  (when msg
    (let ((y nil))
      (setq y (send msg :wrench :force :y))
      (if (< y -10)
	  (progn 
	    (setq *cb-flag* t)
	    (format t "OK!! ~A ~%" y)
	    )
	(format t "~A ~%" y))
      )))

(defun wrench-y-cb-2 (msg)
  (when msg
    (let ((y nil))
      (setq y (send msg :wrench :force :y))
      (if (> y 2)
	  (progn 
	    (setq *cb-flag* t)
	    (format t "OK!! ~A ~%" y)
	    )
	(format t "~A ~%" y))
      )))

(defun wrench-z-cb (msg)
  (when msg
    (let ((z nil))
      (setq z (send msg :wrench :force :z))
      (if (< z -5)
          (progn 
            (setq *cb-flag* t)
            (format t "OK!! z: ~A ~%" z)
            )
        (format t "z: ~A ~%" z))
      )))


(print 3)
(setq *cube* (make-cube 10 50 50))
(send *cube* :set-color :red)
(send *cube* :locate #f(500 0 1000) :world)

(warn "please run (recognition) or (transfer-all)~%")

(setq *end-flag* nil)
(setq *first-flag* t)
(setq *fail-flag* nil)

(defun recognition ()
  (setq found-obj nil)
  (setq cnt 0)
  (ros::unsubscribe *bbox-topic-name*)
  (until found-obj
	 (print 4)
	 (x::window-main-one) ;; IRT viewerの視点を変えられる。見にくければ変えよう

	 (setq msg (one-shot-subscribe *bbox-topic-name* jsk_recognition_msgs::BoundingBoxArray :timeout 2000))
	 (when msg
	   (object-pose-cb msg)

	   ;; 中身が空なら抜ける
	   (unless (send *msg* :boxes) 
	     (progn
	       (setq *end-flag* t)
	       (return-from recognition)
	       ))
	   ;; 中身が0だったらカウントする
	   (if (= *width* 0)
	       (progn
		 (setq cnt (+ cnt 1))
		 ))
	   ;; カウントが５以上になったら抜ける
	   (if (>= cnt 5)
	       (progn
	       (setq *end-flag* t)
	       (return-from recognition)
	       ))
	   )
	 ;; メッセージが来ていなかったら抜ける
	 (unless msg
	   (progn
	     (setq *end-flag* t)
	     (return-from recognition)
	     ))
	 )

  
  ;; modelを作る
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/carrot-test-new-type.l")
  (setq *carrot* (carrot :w  *width* :l *length* :h *height*))
  (send *carrot* :newcoords (send obj-coord :copy-worldcoords))
  (send *carrot* :translate (float-vector (- (/ *width* 2) 20) 0 0))
  (send *carrot* :rotate (deg2rad 180) :x)
  (send *carrot* :cut)

  (objects (list *carrot* *pr2* *cutting-board* *scene*))
  (send *irtviewer* :look-all
	(geo::make-bounding-box 
	 (flatten (send-all (send *pr2* :bodies) :vertices))))
  (send *irtviewer* :draw-objects)
  
  (warn "please run (grasp-carrot) or (now-devel) ~%")
  )

;; cut funcs
(defun set-carrot-cut (&rest args &key (w 160) (l 40) (h 40) &allow-other-keys)
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/carrot-test-new-type.l")

  (setq *width* w)
  (setq *length* l)
  (setq *height* h)
  
  (setq *carrot* (carrot :w w :l l :h h))
  (send *carrot* :transform (make-coords :pos (float-vector 500.0 8500.0 (+ 30850.0 (/ h 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (send *carrot* :cut)
  
  (objects (list *kitchen* *pr2* *cutting-board* *carrot*))
  (send *irtviewer* :look-all
	(geo::make-bounding-box 
	 (flatten (send-all (send *pr2* :bodies) :vertices))))
  
  (warn "please run (grasp-carrot) ~%")
  )


(defun grasp-carrot ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 250) :world)
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis nil
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;少し前に
  (send *arrow* :newcoords (make-coords :pos (send (send *pr2* :larm :end-coords) :worldpos)))
  (send *arrow* :translate #f(-200 50 50) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; 人参の掴む所に
  (send *arrow* :newcoords (send *carrot* :copy-worldcoords))
  ;; (send *arrow* :translate (float-vector (+ (/ *width* -2) 20) 0 0))
  (send *arrow* :translate (float-vector (* (+ (/ *width* -2) 20) 2) 0 0))
  (send *arrow* :rotate (deg2rad 70) :y)

  ;; (send *arrow* :translate #f(-10 -20 -10) :world)

  ;;gripperを開く
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate #f(0 -100 100) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 100 -100) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;gripperを閉じる
  (send *ri* :start-grasp :larm :wait t)

  (send *ri* :start-grasp :larm :wait t :gain 0.05)  
 
  (warn "please run  (set-knife-hor) ~%")
  )

(defun set-knife-hor ()
  (setq *knife* (knife))
  (send *knife* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  
  (send *knife* :translate #f(20 0 0))
  
  (send *knife* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *knife*)
  (send *ri* :start-grasp :rarm :wait t :gain 100)
  
  (objects (list *scene* *pr2* *cutting-board* *carrot* *knife*))
  (send *irtviewer* :look-all
	(geo::make-bounding-box 
	 (flatten (send-all (send *pr2* :bodies) :vertices))))
  
  (warn "please run (touch-test-set) ~%")
  )

(defun touch-test-set ()
  
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis nil
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)


  ;; 少し上に包丁を
  (send *arrow* :newcoords (send *cut-point-1* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 -40 (* *height* 1)))
  
  ;;調整
  (send *arrow* :translate (float-vector 0 adj 0))

  ;; 少し上にするために
  (setq offset 10)
 
  (send *arrow* :translate (float-vector 0 0 offset))  
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  

  (send *arrow* :translate (float-vector 0 0 (* offset -1)))  
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (touch-test) , (touch-test-2) or (touch-test-3) ~%")
  )

(defun touch-test ()
  (setq interval 10)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  ;; (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)
  
  (until *cb-flag*
    (print 4)
    (send *arrow* :translate (float-vector 0 0 (* interval -1)))
    (send *pr2* :rarm :inverse-kinematics
  	  *arrow*
  	  :move-target (car (send *knife* :attention))
  	  :rotation-axis t
  	  :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)

    (setq msg (one-shot-subscribe *topic-name* geometry_msgs::WrenchStamped))
    (wrench-y-cb msg)
    
    ;; (ros::spin-once)
    ;; (ros::sleep)
    )
  
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  
  (warn "you can retry (cut-test), (continue-cut 4) or you want to finish please run (finish-pose)  ~%")
  ;; (warn "please run (slide-knife) ~%")
  (warn "please run (up-knife) ~%")
  )

(defun touch-test-4 ()
  (setq interval 10)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)

  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i (+ (round (/ (* *height* 2) interval)) 1))
    (send *arrow* :translate (float-vector 0 0 (* interval -1)))
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :move-target (car (send *knife* :attention))
          :rotation-axis t
          :debug-view nil)

    (setq av (send *pr2* :angle-vector))

    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )

  (send *ri* :angle-vector-sequence avs tms)

  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
            (ros::spin-once)
            (if *cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      
      (ros::unsubscribe "/right_endeffector/wrench")
      
      (warn "please run (up-knife) ~%")
      (return-from touch-test-4 t))
    )
  
  (ros::unsubscribe "/right_endeffector/wrench")
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (warn "fail cancel !! ~%")  
  (warn "please run (up-knife) ~%")  
  )


(defun up-knife ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (setq interval 10)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  ;; (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb-2)
    
  (until *cb-flag*
    (print 4)
    (send *arrow* :translate (float-vector 0 0 (* interval 1)))
    (send *pr2* :rarm :inverse-kinematics
  	  *arrow*
  	  :move-target (car (send *knife* :attention))
  	  :rotation-axis t
  	  :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)

    (setq msg (one-shot-subscribe *topic-name* geometry_msgs::WrenchStamped))
    (wrench-y-cb-2 msg)
    
    ;; (ros::spin-once)
    ;; (ros::sleep)
    )

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (warn "please run (slide-knife) ~%")  
  )

(defun up-knife-4 ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (setq interval 5)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb-2)
    
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i (+ (* (round (/ *height* interval)) 2) 1))
    (send *arrow* :translate (float-vector 0 0 (* interval 1)) :world)
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :move-target (car (send *knife* :attention))
          :rotation-axis t
          :debug-view t)

    (setq av (send *pr2* :angle-vector))

    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )

  (send *ri* :angle-vector-sequence avs tms)

  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
            (ros::spin-once)
            (if *cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      
      (ros::unsubscribe "/right_endeffector/wrench")

      (warn "please run (slide-knife) ~%")  
      (return-from up-knife-4 t))
    )

  (ros::unsubscribe "/right_endeffector/wrench")
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))


  (warn "fail cancel !! ~%")  
  (warn "please run (slide-knife) ~%")  
  )

(defun slide-knife-set ()
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis nil
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)


  ;; 少し上に包丁を
  (send *arrow* :newcoords (send *cut-point-1* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 -40 40))
  
  ;;調整
  (send *arrow* :translate (float-vector 0 adj 0))

  ;; 少し上にするために
  (setq offset 10)
 
  (send *arrow* :translate (float-vector 0 0 offset))  
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  

  (send *arrow* :translate (float-vector 0 0 (* offset -1)))  
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (slide-knife) or (slide-knife-4) ~%")
  )

(defun slide-knife ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  ;; 少し上げる
  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 adj2) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  ;; (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-z-cb)
  
  (until *cb-flag*
    (print 4)
    (send *arrow* :translate #f(0 -5 0) :world)
    (send *pr2* :rarm :inverse-kinematics
  	  *arrow*
  	  :move-target (car (send *knife* :attention))
  	  :rotation-axis t
  	  :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)
    
    (setq msg (one-shot-subscribe *topic-name* geometry_msgs::WrenchStamped))
    (wrench-z-cb msg)

    ;; (ros::spin-once)
    ;; (ros::sleep)
    )

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (warn "please run (set-cut-1) ~%")  
  )

(defun slide-knife-4 ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  ;; 少し上げる
  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 adj2) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-z-cb)

  (setq interval 5)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i (+ (round (/ 50 interval)) 1))
    (send *arrow* :translate (float-vector 0 (* interval -1) 0) :world)
    (send *pr2* :rarm :inverse-kinematics
          *arrow*
          :move-target (car (send *knife* :attention))
          :rotation-axis t
          :debug-view t)

    (setq av (send *pr2* :angle-vector))

    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )

  (send *ri* :angle-vector-sequence avs tms)

  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
            (ros::spin-once)
            (if *cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      
      (ros::unsubscribe "/right_endeffector/wrench")

      (warn "please run (set-cut-1) or (cut-all)~%")  
      (return-from slide-knife-4 t))
    )

  (ros::unsubscribe "/right_endeffector/wrench")
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (warn "fail cancel !! ~%")  
  (warn "please run (set-cut-1) or (cut-all)~%")  
  )


(defun cut-all ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  
  ;; 薄切りする間隔
  (setq tmp 15)
  
  (setq acc-y (elt (send (send (car (send *knife* :attention)) :copy-worldcoords) :worldpos) 1))
  (setq now-y (elt (send (send *cut-point-1* :copy-worldcoords) :worldpos) 1))
  (setq adj (- now-y acc-y))
  
  (setq l-y (+ (elt (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos) 1) 20))
  (setq leng (- acc-y l-y))
  
  ;; (dotimes (i (- (round (/ leng tmp)) 1))
  (dotimes (i (round (/ leng tmp)) )
    (setq adj (+ adj tmp))
    (cut-test)
    )
  )
  

(defun set-cut-1 ()
  (setq acc-y (elt (send (send (car (send *knife* :attention)) :copy-worldcoords) :worldpos) 1))
  (setq now-y (elt (send (send *cut-point-1* :copy-worldcoords) :worldpos) 1))
  (setq adj (+ (- now-y acc-y) 15))
  (warn "please run (cut-test) ~%")  
  )

(defun set-cut-2 ()
  (setq adj (+ adj 10))
  (warn "please run (cut-test) ~%")  
  )

(defun cut-test ()
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis nil
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)


  ;; 少し上に包丁を

  (send *arrow* :newcoords (send *cut-point-1* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 (* *height* 1)))

  ;;調整
  ;; (send *arrow* :translate #f(0 10 0))
  (send *arrow* :translate (float-vector 0 adj 0))

  ;; 少し上にするために
  (setq offset 50)
 
  (send *arrow* :translate (float-vector 0 0 offset))  
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 (* offset -0.5)))  
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 (* offset -0.5)))  
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq avs (list))
  (setq tms (list))
  
  (setq interval 10)
  (dotimes (i (+ (round (/ *height* interval)) 1))
    (send *arrow* :translate (float-vector (* interval 2) 0 (/ interval -2)))
    (send *pr2* :rarm :inverse-kinematics
  	  *arrow*
  	  :move-target (car (send *knife* :attention))
  	  :rotation-axis t
  	  :debug-view nil)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))

    (send *arrow* :translate (float-vector (* interval -2) 0 (/ interval -2)))
    (send *pr2* :rarm :inverse-kinematics
  	  *arrow*
  	  :move-target (car (send *knife* :attention))
  	  :rotation-axis t
  	  :debug-view nil)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    
    )

  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))  
  
  (warn "you can retry (cut-test), (continue-cut 4) or you want to finish please run (finish-pose)  ~%")
  (warn "or please run (set-cut-2) ~%")
  )

(defun continue-cut (num)
  (setq interval 10)
  (dotimes (i num)
    (send *arrow* :translate (float-vector (* interval 2) 0 (/ interval -2)))
    (send *pr2* :rarm :inverse-kinematics
	  *arrow*
	  :move-target (car (send *knife* :attention))
	  :rotation-axis t
	  :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)

    (send *arrow* :translate (float-vector (* interval -2) 0 (/ interval -2)))
    (send *pr2* :rarm :inverse-kinematics
	  *arrow*
	  :move-target (car (send *knife* :attention))
	  :rotation-axis t
	  :debug-view t)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation))
  (warn "you can retry (cut-test), (continue-cut 4) or you want to finish please run (finish-pose)  ~%")
  )

(defun avoid-pose ()
  (send *pr2* :angle-vector (send *ri* :state :potantio-vector))
  
  ;; 包丁を上に上げる
  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector -30 30 50) :world)
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 50) :world)
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 50) :world)
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (setq *rav1* #f(-16.0652 5.94641 -77.1102 -121.467 184.962 -106.138 -192.692))
  (send *pr2* :rarm :angle-vector *rav1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (setq *rav0* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav0*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (warn "please run (reset-larm)~%")  
  )

(defun reset-larm ()
  ;; release carrot
  (send *pr2* :larm :end-coords :dissoc *carrot*)
  (send *ri* :stop-grasp :larm :wait t)

  ;; 左手を少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view t)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 少し上にして水平に
  (setq *lav1* #f(16.6222 -20.2483 123.957 -51.9842 -42.7912 -65.3348 -437.304))
  (send *pr2* :larm :angle-vector *lav1*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手前にする
  (setq *lav2* #f(41.8129 -20.2467 85.9536 -82.3235 -13.8272 -47.9804 -458.658))
  (send *pr2* :larm :angle-vector *lav2*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq *lav3* #f(75.8217 52.0712 108.49 -109.796 -2.86542 -9.47056 -401.362))
  (send *pr2* :larm :angle-vector *lav3*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)  

  (warn "please run (change-peeler)~&")
  )


(defun now-devel ()
  (set-carrot)
  (grasp-carrot)
  (set-knife-hor)
  (cut-test)
  (avoid-pose)
  (reset-larm)
  )


(defun now-test ()
  (grasp-carrot)
  (set-knife-hor)
  (send *ri* :start-grasp :rarm :gain 100)
  (touch-test-set)
  (touch-test)
  ;; (touch-test-4) ;; angel-vector-sequenceを使ったバージョン．
  (up-knife)
  (slide-knife)
  )


(defun exec-all ()
  (grasp-carrot)
  (grasp-knife-hor)
  (cut-test)
  (finish-pose)
  (put-carrot)
  (reset-larm)
  (change-peeler)
  )

(defun now-cut ()
  (recognition)
  (grasp-carrot)
  (set-knife-hor)
  (touch-test-set)
  (touch-test)
  (up-knife)
  (slide-knife)
  (cut-all)
  (avoid-pose)
  (reset-larm)
  )
