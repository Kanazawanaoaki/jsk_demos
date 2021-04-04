(defun cut-potato-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  
  ;; set cutting board
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/cutting-board.l")
  (setq *cutting-board* (cutting-board))
  (send *cutting-board* :newcoords (send *cutting-board-coords* :copy-worldcoords))
  
  ;; set global variables
  (setq adj 10)
  (setq adj2 5)
  
  
  (move-to-kitchen-irt)
  (objects (list *pr2* *scene* *cutting-board*))
  (update-view)  
  )

(cut-potato-init)

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
  (setq *boxes* (send msg :boxes))
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

(defun check-y-coords (bbox)
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

      (if (> (elt obj-pos 1) *tmp*)
          (progn
            (setq *tmp* (elt obj-pos 1))
            (setq *width* width)
            (setq *length* length)
            (setq *height* height)
            (setq *obj-coord* obj-coord)
            ))
      
      (print (list 'found? found-obj obj-pos)))
    obj-pos))

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
  )


(defun recognition-potato ()
  (recognition)

  (if (eql found-obj t)
      (progn 
    ;; modelを作る
    (load "package://jsk_2020_04_pr2_curry/euslisp/model/potato-new-type.l")
    (setq *potato* (potato :w  *width* :l *length* :h *height*))
    (send *potato* :newcoords (send *obj-coord* :copy-worldcoords))
    (send *potato* :rotate (deg2rad 180) :x)
    (send *potato* :cut)
    
    (objects (list *potato* *pr2* *cutting-board* *scene*))
    (send *irtviewer* :look-all
          (geo::make-bounding-box 
           (flatten (send-all (send *pr2* :bodies) :vertices))))
    (send *irtviewer* :draw-objects)
    
    (warn "please run (grasp-potato) or (now-devel) ~%")
    )
    )
  )

(defun recognition-right ()
  (recognition)
  
  (if (eql found-obj t)
      (progn 
    ;; yが最大のboxを使ってモデルを作る．
    (setq *tmp* 0)
    (dolist (i *boxes*)
      (check-y-coords i))
    
    ;; modelを作る
    (load "package://jsk_2020_04_pr2_curry/euslisp/model/potato-box-model.l")
    (setq *potato* (potato :w  *width* :l *length* :h *height*))
    (send *potato* :newcoords (make-coords :pos (send *obj-coord* :worldpos)))
    (send *potato* :rotate (deg2rad 90) :z :world)
    ;; (send *potato* :rotate (deg2rad 180) :x)
    (send *potato* :cut)
    
    (objects (list *potato* *pr2* *cutting-board* *scene*))
    (send *irtviewer* :look-all
          (geo::make-bounding-box 
           (flatten (send-all (send *pr2* :bodies) :vertices))))
    (send *irtviewer* :draw-objects)
    
    (warn "please run (grasp-potato) or (now-devel) ~%")
    )
    )
  )

(defun recognition-right-set ()
  (recognition)

  (if (eql found-obj t)
      (progn 
    ;; yが最大のboxを使ってモデルを作る．
    (setq *tmp* 0)
    (dolist (i *boxes*)
      (check-y-coords i))
    
    ;; modelを作る
    (load "package://jsk_2020_04_pr2_curry/euslisp/model/potato-half-model.l")
    
    (setq hoge *width*)
    (setq *width* (+ (* *height* 2) 30))
    (setq *height* hoge)
    
    (setq *potato* (potato :w  *width* :l *length* :h *height*))
    (send *potato* :newcoords (make-coords :pos (send *obj-coord* :worldpos)))
    (send *potato* :rotate (deg2rad 90) :z :world)
    ;; (send *potato* :rotate (deg2rad 180) :x)
    (send *potato* :cut)

    (send p4 :dissoc p7)
    (send p7 :translate #f(0 0 -100) :world)
    (send p4 :dissoc p8)
    (send p8 :translate #f(0 0 -100) :world)  

    (send p4 :dissoc p1)

    (send p4 :translate #f(0 0 -100) :world)
    (send *viewer* :draw-objects)

    ;; test
    (send p1 :translate (float-vector (/ (- *width* 30) -4) 0 0))

    (objects (list *potato* *pr2* *cutting-board* *scene*))
    (send *irtviewer* :look-all
          (geo::make-bounding-box 
           (flatten (send-all (send *pr2* :bodies) :vertices))))
    (send *irtviewer* :draw-objects)

    (warn "please run (grasp-potato) or (now-devel) ~%")
    )
    )
  )

(defun recognition-right-rotate ()
  (recognition)
  
  (if (eql found-obj t)
      (progn 
    ;; yが最大のboxを使ってモデルを作る．
    (setq *tmp* 0)
    (dolist (i *boxes*)
      (check-y-coords i))

    ;; modelを作る
    (load "package://jsk_2020_04_pr2_curry/euslisp/model/potato-half-model.l")
    
    (setq hoge *width*)
    (setq *width* (+ (* *height* 2) 30))
    (setq *height* hoge)

    (setq *potato* (potato :w  *width* :l *length* :h *height*))
    (send *potato* :newcoords (send *obj-coord* :copy-worldcoords))

    (send *potato* :rotate (deg2rad 180) :x)
    (send *potato* :cut)


    (send p4 :dissoc p7)
    (send p7 :translate #f(0 0 -100) :world)
    (send p4 :dissoc p8)
    (send p8 :translate #f(0 0 -100) :world)  

    (send p4 :dissoc p1)

    (send p4 :translate #f(0 0 -100) :world)
    (send *viewer* :draw-objects)

    (send p1 :rotate (deg2rad -90) :y)
    (send p1 :translate (float-vector 0 0 (* -0.25 (- *width* 30))) :world)

    (objects (list *potato* *pr2* *cutting-board* *scene*))
    (send *irtviewer* :look-all
          (geo::make-bounding-box 
           (flatten (send-all (send *pr2* :bodies) :vertices))))
    (send *irtviewer* :draw-objects)
    )
    )
  )
  
(defun recognition-left ()
  (recognition)
  
  (if (eql found-obj t)
      (progn 
    ;; yが最小のboxを使ってモデルを作る．
    (setq *tmp* 1000000)
    (dolist (i *boxes*)
      (check-y-coords-min i))
    
    ;; modelを作る
    (load "package://jsk_2020_04_pr2_curry/euslisp/model/potato-new-type.l")
    (setq *potato* (potato :w  *width* :l *length* :h *height*))
    (send *potato* :newcoords (send *obj-coord* :copy-worldcoords))
    (send *potato* :rotate (deg2rad 90) :z :world)
    ;; (send *potato* :rotate (deg2rad 180) :x)
    (send *potato* :cut)
    
    (objects (list *potato* *pr2* *cutting-board* *scene*))
    (send *irtviewer* :look-all
          (geo::make-bounding-box 
           (flatten (send-all (send *pr2* :bodies) :vertices))))
    (send *irtviewer* :draw-objects)
    
    (warn "please run (grasp-potato) or (now-devel) ~%")
    )
    )
  )

(defun recognition-left-rotate ()
  (recognition)
  
  (if (eql found-obj t)
      (progn 
    ;; yが最小のboxを使ってモデルを作る．
    (setq *tmp* 1000000)
    (dolist (i *boxes*)
      (check-y-coords-min i))
    
    ;; modelを作る
    (load "package://jsk_2020_04_pr2_curry/euslisp/model/potato-half-model.l")
    
    (setq hoge *width*)
    (setq *width* (+ (* *height* 2) 30))
    (setq *height* hoge)

    (setq *potato* (potato :w  *width* :l *length* :h *height*))
    (send *potato* :newcoords (send *obj-coord* :copy-worldcoords))

    (send *potato* :rotate (deg2rad 180) :x)
    (send *potato* :cut)


    (send p4 :dissoc p7)
    (send p7 :translate #f(0 0 -100) :world)
    (send p4 :dissoc p8)
    (send p8 :translate #f(0 0 -100) :world)  

    (send p4 :dissoc p1)

    (send p4 :translate #f(0 0 -100) :world)
    (send *viewer* :draw-objects)
    
    (send p1 :rotate (deg2rad -90) :y)
    (send p1 :translate (float-vector 0 0 (* -0.25 (- *width* 30))) :world)
    
    (objects (list *potato* *pr2* *cutting-board* *scene*))
    (send *irtviewer* :look-all
          (geo::make-bounding-box 
           (flatten (send-all (send *pr2* :bodies) :vertices))))
    (send *irtviewer* :draw-objects)
    )
    )
  )


;; add for rosservice
(ros::load-ros-manifest "std_srvs")
(ros::wait-for-service "after_stow_data_collection/save_request")
(setq req (instance std_srvs::TriggerRequest :init))


(defun rossrv-test ()
  (setq res (ros::service-call "after_stow_data_collection/save_request" req t))
  )

(defun look-at-arrow ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :head :look-at (send (send *arrow* :copy-worldcoords) :worldpos))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  )


;; cut funcs
(defun set-potato-cut (&rest args &key (w 160) (l 40) (h 40) &allow-other-keys)
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/potato-new-type.l")
  
  (setq *width* w)
  (setq *length* l)
  (setq *height* h)
  
  (setq *potato* (potato :w w :l l :h h))
  (send *potato* :transform (make-coords :pos (float-vector 500.0 8500.0 (+ 30850.0 (/ h 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (send *potato* :cut)
  
  (objects (list *scene* *pr2* *cutting-board* *potato*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))
  
  (warn "please run (grasp-potato) ~%")
  )

(defun grasp-potato ()  
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 250) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis nil
    :debug-view *debug-flag*)
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
      :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; じゃがいもの掴む所に
  (send *arrow* :newcoords (send *potato* :copy-worldcoords))
  (send *arrow* :translate #f(0 -20 0) :world)
  (send *arrow* :rotate (deg2rad 70) :y)
  
  (send *arrow* :translate #f(-10 -10 -5) :world)
  
  ;;gripperを開く
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate #f(0 -100 100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 100 -100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;gripperを閉じる
  (send *ri* :start-grasp :larm :wait t)

  (send *ri* :start-grasp :larm :wait t :gain 0.05)  

  (look-at-left-hand)
  (rossrv-test)
  (warn "please run  (set-knife-hor) ~%")
  )

(defun set-knife-hor ()
  (setq *knife* (knife))
  (send *knife* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *knife* :translate #f(20 0 0))
  (send *knife* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *knife*)

  (send *ri* :start-grasp :rarm :wait t :gain 100)
  
  (objects (list *scene* *pr2* *cutting-board* *potato* *knife*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))
  
  (warn "please run (touch-test-set) ~%")
  )


(defun cut-test ()
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis nil
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (send *kp* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 (* *cut-height* 1)))
  
  ;;調整
  (send *arrow* :translate (float-vector 0 adj 0))

  ;; 少し上にするために
  (setq offset 50)
  
  (look-at-arrow)
  (rossrv-test)
  
  (send *arrow* :translate (float-vector 0 0 offset))  
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 (* offset -0.5)))  
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 (* offset -0.5)))  
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (setq avs (list))
  (setq tms (list))
  
  (setq interval 10)
  (dotimes (i (+ (round (/ *cut-height* interval)) 1))
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

  (rossrv-test)
  
  (warn "you can retry (cut-test), (continue-cut 4) or you want to finish please run (finish-pose)  ~%")
  )

(defun cut-test-m ()
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis nil
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (send *kp* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 (* *cut-height* 1)))
  
  ;;調整
  (send *arrow* :translate (float-vector 0 adj 0))

  ;; 少し上にするために
  (setq offset 50)
  
  (look-at-arrow)
  (rossrv-test)
  
  (send *arrow* :translate (float-vector 0 0 offset))  
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 (* offset -0.5)))  
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 (* offset -0.5)))  
  (send *pr2* :rarm :inverse-kinematics
	*arrow*
	:move-target (car (send *knife* :attention))
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
    
  ;; 室岡さんの切るやつ
  ;; (send *pkki* :cut-once *arrow* *height* :controller :nn)
  ;; (send *pkki* :cut-once *arrow* (- (elt (send (send *knife* :attention-attention0) :worldpos) 2) 30880) :controller :nn)
  (send *pkki* :cut-once *arrow* 30892 :controller :nn) ;; 新しいVer.用

  (warn "you can retry (cut-test), (continue-cut 4) or you want to finish please run (finish-pose)  ~%")
  )

(defun cut-test-point-3 ()
  (setq *kp* (arrow))
  (send *kp* :newcoords (send *cut-point-3* :copy-worldcoords))
  (setq *cut-height* *height*)
  
  ;; (cut-test)
  (cut-test-m)
  )

(defun cut-test-point-1 ()
  (setq *kp* (arrow))
  (send *kp* :newcoords (send *cut-point-1* :copy-worldcoords))
  (setq *cut-height* (* *height* 0.5))
  
  ;; (cut-test)
  (cut-test-m)
  )    

    
(defun continue-cut (num)
  (setq interval 10)
  (dotimes (i num)
    (send *arrow* :translate (float-vector (* interval 2) 0 (/ interval -2)))
    (send *pr2* :rarm :inverse-kinematics
      *arrow*
      :move-target (car (send *knife* :attention))
      :rotation-axis t
      :debug-view *debug-flag*)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)

    (send *arrow* :translate (float-vector (* interval -2) 0 (/ interval -2)))
    (send *pr2* :rarm :inverse-kinematics
      *arrow*
      :move-target (car (send *knife* :attention))
      :rotation-axis t
      :debug-view *debug-flag*)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation))
  (warn "you can retry (cut-test), (continue-cut 4) or you want to finish please run (finish-pose)  ~%")
  )

(defun put-potato ()
  (send *pr2* :larm :end-coords :assoc *potato*)
  
  ;; 上に上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; 置く
  (send *arrow* :move-to (make-coords :pos (float-vector 500.0 8400.0 30850.0) :rot #2f((1.0 0.0 0.0) (0.0 0.0 -1.0) (0.0 1.0 0.0))) :world)

  (send *arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target *cut-point-3*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target *cut-point-3*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; release carrot
  (send *pr2* :larm :end-coords :dissoc *potato*)
  (send *ri* :stop-grasp :larm :wait t)
  
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
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
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector -30 30 50) :world)
  (send *pr2* :rarm :inverse-kinematics
        *arrow*
        :move-target (car (send *knife* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 50) :world)
  (send *pr2* :rarm :inverse-kinematics
        *arrow*
        :move-target (car (send *knife* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (car (send *knife* :attention)) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 50) :world)
  (send *pr2* :rarm :inverse-kinematics
        *arrow*
        :move-target (car (send *knife* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  ;; (setq *rav1* #f(-16.0652 5.94641 -77.1102 -121.467 184.962 -106.138 -192.692))
  ;; (send *pr2* :rarm :angle-vector *rav1*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 673.153 8524.978 31130.399) :rpy (float-vector 3.141 0.122 -1.571)))
  (send *pr2* :rarm :inverse-kinematics
        *arrow*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  ;; (setq *rav0* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  ;; (send *pr2* :rarm :angle-vector *rav0*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 628.029 8828.539 31050.217) :rpy (float-vector -3.14 0.18 -0.086)))
  (send *pr2* :rarm :inverse-kinematics
        *arrow*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (warn "please run (reset-larm)~%")  
  )

(defun reset-larm ()
  ;; 左手を少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 少し上にして水平に
  ;; (setq *lav1* #f(16.6222 -20.2483 123.957 -51.9842 -42.7912 -65.3348 -437.304))
  ;; (send *pr2* :larm :angle-vector *lav1*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 510.0 8489.999 31190.001) :rpy (float-vector 1.571 0.0 0.0)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手前にする
  ;; (setq *lav2* #f(41.8129 -20.2467 85.9536 -82.3235 -13.8272 -47.9804 -458.658))
  ;; (send *pr2* :larm :angle-vector *lav2*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 660.0 8390.0 31290.0) :rpy (float-vector 1.571 0.0 0.0)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; (setq *lav3* #f(75.8217 52.0712 108.49 -109.796 -2.86542 -9.47056 -401.362))
  ;; (send *pr2* :larm :angle-vector *lav3*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 800.188 8310.893 30866.671) :rpy (float-vector 2.341 -0.222 -0.133)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)  

  (warn "please run (change-peeler)~&")
  )


;; right set funcs
(defun grasp-potato-right-set ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 250) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis nil
    :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 左手を少し前に
  (send *arrow* :newcoords (make-coords :pos (send (send *pr2* :larm :end-coords) :worldpos)))
  (send *arrow* :translate #f(-200 50 50) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; じゃがいもの掴む所に
  (send *arrow* :newcoords (send p1 :copy-worldcoords))
  (send *arrow* :translate (float-vector (/ (- *width* 30) 4) 0 0))
  (send *arrow* :rotate (deg2rad 180) :y)

  (send *arrow* :translate #f(-10 -10 -5) :world)

  ;;gripperを開く
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate #f(0 -100 100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 100 -100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;gripperを閉じる
  (send *ri* :start-grasp :larm :wait t)
     
  (warn "please run  (put-potato-right-set) ~%")
  )


(defun put-potato-right-set ()
  (send *pr2* :larm :end-coords :assoc p1)
  
  ;; 上に上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 置く
  (send *arrow* :move-to (make-coords :pos (float-vector 500.0 8550.0 30850.0) :rot #2f((1.0 0.0 0.0) (0.0 0.0 -1.0) (0.0 1.0 0.0))) :world)
  (send *arrow* :rotate (deg2rad -90) :y :world)

  (send *arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target p1
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target p1
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; release potato
  (send *pr2* :larm :end-coords :dissoc p1)
  (send *ri* :stop-grasp :larm :wait t)

  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (reset-larm)~&")
  )


;; right rotate
(defun grasp-potato-right-rotate ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 250) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis nil
    :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 左手を少し前に
  (send *arrow* :newcoords (make-coords :pos (send (send *pr2* :larm :end-coords) :worldpos)))
  (send *arrow* :translate #f(-200 50 50) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; じゃがいもの掴む所に
  (send *arrow* :newcoords (send p1 :copy-worldcoords))
  (send *arrow* :translate (float-vector (/ (- *width* 30) 4) 0 0))
  (send *arrow* :rotate (deg2rad 180) :y)
  
  (send *arrow* :translate #f(-10 -10 -5) :world)

  ;;gripperを開く
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate #f(0 -100 100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(0 100 -100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;gripperを閉じる
  (send *ri* :start-grasp :larm :wait t)
     
  (warn "please run  (put-potato) ~%")
  )


(defun put-potato-right-rotate ()
  (send *pr2* :larm :end-coords :assoc p1)
  
  ;; 上に上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; 置く
  (send *arrow* :move-to (make-coords :pos (float-vector 500.0 8550.0 30850.0) :rot #2f((1.0 0.0 0.0) (0.0 0.0 -1.0) (0.0 1.0 0.0))) :world)
  (send *arrow* :rotate (deg2rad -90) :y :world)

  (send *arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target p1
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target p1
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; release carrot
  (send *pr2* :larm :end-coords :dissoc p1)
  (send *ri* :stop-grasp :larm :wait t)

  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (reset-larm)~&")
  )

;; left rotate
(defun grasp-potato-left-rotate ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 250) :world)
  (send *pr2* :larm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis nil
    :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 左手を少し前に
  (send *arrow* :newcoords (make-coords :pos (send (send *pr2* :larm :end-coords) :worldpos)))
  (send *arrow* :translate #f(-200 50 50) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; じゃがいもの掴む所に
  (send *arrow* :newcoords (send p1 :copy-worldcoords))
  (send *arrow* :translate (float-vector (/ (- *width* 30) 4) 0 0))
  (send *arrow* :rotate (deg2rad 180) :y)

  (send *arrow* :translate #f(-10 -10 -5) :world)

  ;;gripperを開く
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate #f(0 -100 100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 100 -100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;gripperを閉じる
  (send *ri* :start-grasp :larm :wait t)
     
  (warn "please run  (put-potato) ~%")
  )


(defun put-potato-left-rotate ()
  (send *pr2* :larm :end-coords :assoc p1)
  
  ;; 上に上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 置く
  (send *arrow* :move-to (make-coords :pos (float-vector 500.0 8350.0 30850.0) :rot #2f((1.0 0.0 0.0) (0.0 0.0 -1.0) (0.0 1.0 0.0))) :world)
  (send *arrow* :rotate (deg2rad -90) :y :world)
  
  (send *arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target p1
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target p1
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; release carrot
  (send *pr2* :larm :end-coords :dissoc p1)
  (send *ri* :stop-grasp :larm :wait t)

  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (reset-larm)~&")
  )



;; now funcs
(defun now-devel ()
  (set-potat-cut)
  (grasp-potato)
  (set-knife-hor)
  (cut-test-point-3)
  (avoid-pose)
  (put-potato)
  (reset-larm)
  )

;; 半分に切る
(defun now-cut-half ()
  (recognition-potato)
  (grasp-potato)
  (set-knife-hor)
  (cut-test-point-3)
  (avoid-pose)
  (put-potato)
  (reset-larm)
  )

;; 右半分を立てる
(defun now-right-set ()
  (recognition-right-set)
  (grasp-potato-right-set)
  (put-potato-right-set)
  (reset-larm)
  )

;; 右半分を回転する
(defun now-right-rotate ()
  (recognition-right-rotate)
  (grasp-potato-right-rotate)
  (put-potato-right-rotate)
  (reset-larm)
  )

;; 右半分を切る
(defun now-cut-right ()
  (recognition-right)
  (set-knife-hor)
  (cut-test-point-1)
  (avoid-pose)
  )

;; 左半分を回転させる
(defun now-left-rotate ()
  (recognition-left-rotate)
  (grasp-potato-left-rotate)
  (put-potato-left-rotate)
  (reset-larm)
  )
    
;; 左半分を切る
(defun now-cut-left ()
  (recognition-left)
  (set-knife-hor)
  (cut-test-point-1)
  (avoid-pose)
  )

(defun demo-cut-tmp ()
  (update-pos)
  (now-cut-half)
  (now-right-set)
  (now-right-rotate)
  (now-cut-right)
  (now-left-rotate)
  (now-cut-left)
  )
