;; ros init
(ros::roseus "carrot_rec_test" :anonymous t)
(ros::load-ros-manifest "jsk_recognition_msgs")
(setq *l* (instance ros::transform-listener :init))


(load "carrot-cut-test-with-sense-test-two.l")


;; define cb
(defun object-pose-cb (msg)
  (setq *msg* msg)
  (setq *bbox* (car (send msg :boxes)))
  ;; (print 1)
  (when msg
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
              (setq found-obj t))
	(print (list 'found? found-obj obj-pos)))
      obj-pos)))


(defun recognition ()
  ;; トピックなどを定義
  (setq *topic-name* "/segmentation_decomposer/boxes")

  (setq found-obj nil)
  (setq obj-pos #f(0 0 0))
  (setq obj-coord (make-coords :pos #f(0 0 0)))
  (print 0)

  ;; subscribeして認識
  (ros::unsubscribe *topic-name*)
  ;; (ros::subscribe *topic-name* jsk_recognition_msgs::BoundingBoxArray #'object-pose-cb 1)
  (setq *b* (instance ros::transform-broadcaster :init))

  (print 3)
  (setq *cube* (make-cube 10 50 50))
  (send *cube* :set-color :red)
  (send *cube* :locate #f(500 0 1000) :world)
  (objects (list *cube* *pr2*))

  (setq found-obj nil)
  (until found-obj
	 (print 4)
	 
	 (x::window-main-one) ;; IRT viewerの視点を変えられる。見にくければ変えよう

	 (setq msg (one-shot-subscribe *topic-name* jsk_recognition_msgs::BoundingBoxArray))
	 (object-pose-cb msg)
	 
	 ;; (ros::spin-once)
	 ;; (ros::sleep)
	 )


  ;; ikを解く
  (load "models/arrow-object.l")
  (setq *arrow* (arrow))
  (send *arrow* :newcoords (send obj-coord :copy-worldcoords))

  (load "../../model/carrot-test-new-type.l")
  (setq *carrot* (carrot :w  width :l length :h height))
  (send *carrot* :newcoords (send obj-coord :copy-worldcoords))
  (send *carrot* :translate (float-vector (- (/ width 2) 20) 0 0))
  (send *carrot* :rotate (deg2rad 180) :x)
  (send *carrot* :cut)
  (objects (list *carrot* *pr2* *cutting-board* *kitchen*))
  (send *irtviewer* :look-all
	(geo::make-bounding-box 
	 (flatten (send-all (send *pr2* :bodies) :vertices))))
  (send *irtviewer* :draw-objects)


  (setq interval height)

  (warn "please run (grasp-carrot) or (now-devel)~%")
  )

(recognition)

(setq *topic-name* "/right_endeffector/wrench")



(defun now-devel ()
  (grasp-carrot)
  (grasp-knife-hor)
  (cut-test)
  (finish-pose)
  (put-carrot)
  (reset-larm)
  (change-peeler)
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
  (grasp-carrot)
  (set-knife-hor)
  ;; (send *ri* :start-grasp :rarm :gain 100)
  (touch-test-set)
  (touch-test)
  (up-knife)
  (slide-knife)
  (cut-all)
  (avoid-pose)
  (reset-larm)
  )

