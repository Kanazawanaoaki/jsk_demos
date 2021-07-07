;; ros init
(ros::roseus "potato_rec_test" :anonymous t)
(ros::load-ros-manifest "jsk_recognition_msgs")
(setq *l* (instance ros::transform-listener :init))


(load "potato-cut-quarter-box.l")


;; define cb
(defun object-pose-cb (msg)
  (setq *msg* msg)
  (setq *boxes* (send msg :boxes))
  (setq *bbox* (car (send msg :boxes)))
  ;; (print 1)
  (when *bbox*
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

(defun check-y-coords-min (bbox)
  (let ((cam-coords nil))
    (setq tm2 (send *l* :get-latest-common-time "base_footprint" "head_mount_kinect_rgb_optical_frame"))    
    (setq *dim* (send bbox :dimensions))
    (setq width (* (send *dim* :x) 1000))
    (setq length (* (send *dim* :y) 1000))
    (setq height (* (send *dim* :z) 1000))
    (setq *pose* (send bbox :pose))
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
      (setq found-obj t)

      (if (< (elt obj-pos 1) *tmp*)
          (progn
            (setq *tmp* (elt obj-pos 1))
            (setq *width* width)
            (setq *length* length)
            (setq *height* height)
            (setq *obj-coord* obj-coord)
            ))
      
      (print (list 'found? found-obj obj-pos)))
    obj-pos))

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


  ;; yが最小のboxを使ってモデルを作る．
  (setq *tmp* 1000000)
  (dolist (i *boxes*)
    (check-y-coords-min i))

  ;; ikを解く
  (load "models/arrow-object.l")
  (setq *arrow* (arrow))
  (send *arrow* :newcoords (send *obj-coord* :copy-worldcoords))

  ;; (load "../../model/potato-new-type.l")
  ;; (load "../../model/potato-half-model.l")
  (load "../../model/potato-box-model.l")

  (setq *potato* (potato :w  *width* :l *length* :h *height*))
  (send *potato* :newcoords (make-coords :pos (send *obj-coord* :worldpos)))
  (send *potato* :rotate (deg2rad 90) :z :world)
  ;; (send *potato* :rotate (deg2rad 180) :x)
  (send *potato* :cut)

  (objects (list *potato* *pr2* *cutting-board* *kitchen*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))
  (send *irtviewer* :draw-objects)
  
  (warn "please run (grasp-potato) or (now-devel)~%")
  )

(recognition)

(setq *topic-name* "/right_endeffector/wrench")


(defun now-devel ()
  ;; (set-potato :w *width* :l *length* :h *height*)
  ;; (grasp-potato)
  (grasp-knife-hor)
  (cut-test)
  (finish-pose)
  )



(defun now-test ()
  ;; (set-potato :w *width* :l *length* :h *height*)
  ;; (grasp-potato)
  (set-knife-hor)
  (cut-test)
  (finish-pose)
  )


(defun exec-all ()
  ;; (set-potato :w *width* :l *length* :h *height*)
  ;; (grasp-potato)
  (grasp-knife-hor)
  (cut-test)
  (finish-pose)
  )

(defun now-cut ()
  (set-knife-hor)
  (cut-test)
  (avoid-pose)
  )

(defun now-cut-with-sense ()
  (grasp-potato)
  (set-knife-hor)

  (fail-check)
  (if (eql *fail-flag* t)
      (progn
    ;; (reset-larm)
    (setq adj (- adj 20))
    ))

  (touch-test-set)
  (touch-test)
  (up-knife)
  (slide-knife)

  (set-cut-1)

  ;; (if (eql *fail-flag* nil)
  ;;     (progn
  ;;     (reset-larm)
  ;;     ))
  (reset-larm)
  
  (before-cut)
  (grasp-potato)
  (cut-cut)
  
  (after-cut)
  (reset-larm)
  (avoid-pose)
  )
