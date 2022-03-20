(defun peel-potato-init ()
  ;; init
  (load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/tool-use-codes.l")
  
  ;; set cutting board
  (load "package://jsk_2021_10_soup_from_boil/euslisp/model/cutting-board.l")
  (setq *cutting-board* (cutting-board))
  (send *cutting-board* :newcoords (send *cutting-board-coords* :copy-worldcoords))
  
  ;; set global variables
  (setq adj 0)
  (setq adj2 0)

  
  (move-to-kitchen-irt)
  (objects (list *pr2* *scene* *cutting-board*))
  (update-view)  
  )

(peel-potato-init)

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
(setq *y-thre* -11)

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

;; add for rosservice
(ros::load-ros-manifest "std_srvs")
(ros::wait-for-service "after_stow_data_collection/save_request")
(setq req (instance std_srvs::TriggerRequest :init))


(defun rossrv-test ()
  (setq res (ros::service-call "after_stow_data_collection/save_request" req t))
  )

(defun look-at-left-hand ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :head :look-at (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  )



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

  
  ;; ikを解く
  (load "package://jsk_2021_10_soup_from_boil/euslisp/model/potato-new-type.l")
  (setq *potato* (potato :w  *width* :l *length* :h *height*))
  (send *potato* :newcoords (send *obj-coord* :copy-worldcoords))
  (send *potato* :rotate (deg2rad 180) :x)

  (objects (list *potato* *pr2* *cutting-board* *scene*))
  (send *irtviewer* :look-all
        (geo::make-bounding-box 
         (flatten (send-all (send *pr2* :bodies) :vertices))))
  (send *irtviewer* :draw-objects)
  
  (warn "please run (grasp-target) or (now-devel) ~%")
  )


;; def util-funcs

;; peel funcs
(defun set-potato-peel (&rest args &key (w 90) (l 60) (h 60) &allow-other-keys)
  (load "package://jsk_2021_10_soup_from_boil/euslisp/model/potato-new-type.l")
  
  (setq *width* w)
  (setq *length* l)
  (setq *height* h)
  
  (setq *potato* (potato :w w :l l :h h))
  (send *potato* :transform (make-coords :pos (float-vector 500.0 8500.0 (+ 30850.0 (/ h 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  
  (objects (list *potato* *pr2* *cutting-board* *scene*))
  (send *irtviewer* :look-all
        (geo::make-bounding-box 
         (flatten (send-all (send *pr2* :bodies) :vertices))))
  
  (setq interval *height*)
  
  (warn "please run (grasp-potato-peel) ~%")
  )

(defun grasp-potato-peel ()
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
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
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
  (send *arrow* :translate #f(-20 0 0))
  (send *arrow* :rotate (deg2rad 45) :y)
  
  (send *arrow* :translate #f(-10 -15 -5) :world)
  
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
  (send (send *pr2* :larm :end-coords) :assoc *potato*)
  ;; (send *ri* :start-grasp :larm :wait t :gain 0.05)
  (send *ri* :start-grasp :larm :wait t :gain 0.1)
  
  ;; (warn "please run  (set-potato-1) ~%")
  (warn "please run (set-peeler) or (grasp-peeler) ~%")
  )

(defun set-potato ()
  ;; 左手を上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 50) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; じゃがいもを位置に．
  (send *pr2* :larm :inverse-kinematics
        (send *p-arrow* :copy-worldcoords)
        :move-target *potato*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  )

(defun before-set ()
  ;; 左手を上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 50) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun set-peeler ()
  ;; ピーラーをセットする．
  (setq *peeler* (peeler))
  (send *peeler* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *peeler* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *peeler*)

  (objects (list *potato* *pr2* *cutting-board* *scene* *peeler*))
  (send *irtviewer* :look-all
        (geo::make-bounding-box 
         (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (peel-test) ~%")
  )

(defun set-potato-peeler ()
  ;; ピーラーをセットする．
  (load "package://jsk_2021_10_soup_from_boil/euslisp/model/potato-peeler.l")
  (setq *potato-peeler* (peeler))
  
  ;; (setq *potato-peeler* (potato-peeler)) ;;絶対こっちの方がよい！！
  (send *potato-peeler* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *potato-peeler* :rotate (deg2rad 90) :x)
  (send *pr2* :rarm :end-coords :assoc *potato-peeler*)

  (objects (list *potato* *pr2* *cutting-board* *scene* *potato-peeler*))
  (send *irtviewer* :look-all
        (geo::make-bounding-box 
         (flatten (send-all (send *pr2* :bodies) :vertices))))

  (warn "please run (peel-test) ~%")
  )

(defun peel-test (peeler)  
  (look-at-left-hand)
  
  ;; 右手を上げる
  (setq *c* (make-coords))
  (send *c* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *c* :translate #f(0 0 200) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *c* :copy-worldcoords)
        :rotation-axis nil
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; 剥く位置
  (send *c* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *c* :translate #f(0 15 0) :world)
  (send *c* :rotate (deg2rad -90) :z :world)

  (send *c* :translate (float-vector 0 0 (* 1 *height*)) :world)
  (send *c* :rotate (deg2rad 30) :y)
  (send *c* :translate (float-vector 0 80 80) :world)

  ;;調整
  (send *c* :translate (float-vector 0 adj 0))

  (send *c* :translate (float-vector adj2 0 0))
  
  (send *pr2* :rarm :inverse-kinematics
        *c*
        :move-target (car (send peeler :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *c* :translate (float-vector 0 -80 -80) :world)
  (send *pr2* :rarm :inverse-kinematics
        *c*
        :move-target (car (send peeler :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (setq *tmp-rav-0* (send *pr2* :rarm :angle-vector))
  
  ;; 皮剥き始める所
  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)
  
  (setq interval 10)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i (+ (round (/ (* *height* 2) interval)) 1))
    (send *c* :translate (float-vector 0 0 (* interval -1)) :world)
    (send *pr2* :rarm :inverse-kinematics
          *c*
          :move-target (car (send peeler :attention))
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
      
      ;; 剥き終わり
      (send *c* :rotate (deg2rad -30) :y)
      (send *c* :translate (float-vector (* (+ *width* 20) -1) 0 0) )
      (send *c* :rotate (deg2rad 30) :y)
      
      (send *pr2* :rarm :inverse-kinematics
            *c*
            :move-target (car (send peeler :attention))
            :rotation-axis t
            :debug-view *debug-flag*)
      (send *viewer* :draw-objects)
      (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
      (send *ri* :wait-interpolation)
      
      (ros::unsubscribe "/right_endeffector/wrench")
      
      (warn "you can retry (peel-test) or (finish-pose-peel) , (set-carrot-2)~%")
      (return-from peel-test t))
    )
  
  ;; 剥き終わり
  (send *c* :rotate (deg2rad -30) :y)
  (send *c* :translate (float-vector (* (+ *width* 20) -1) 0 0) )
  (send *c* :rotate (deg2rad 30) :y)
  
  (send *pr2* :rarm :inverse-kinematics
        *c*
        :move-target (car (send peeler :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (ros::unsubscribe "/right_endeffector/wrench")
  
  (warn "fail cancel !! ~%")
  (warn "you can retry (peel-test) or (finish-pose-peel) , (set-carrot-2)~%")
  )

(defun set-potato-1 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  ;; (set-potato)
  
  (before-set)
  (setq *pav1* #f(21.8662 -20.2347 104.555 -67.1948 27.259 -58.1598 -118.836))
  (send *pr2* :larm :angle-vector *pav1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (look-at-left-hand)
  (rossrv-test)
  (warn "please run  (set-potato-1-2) ~%")  
  )

(defun set-potato-1-2 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 500.0 8500.0 (+ 30850.0 (/ *height* 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  ;; (set-potato)
  
  (before-set)
  ;; (setq *pav1-2* #f(14.7437 5.84814 101.3 -45.7347 41.7277 -59.5476 -104.019))
  (setq *pav1-2* #f(22.1415 6.1184 100.613 -45.0089 41.1581 -65.3866 -98.0152))  
  (send *pr2* :larm :angle-vector *pav1-2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run  (peel-test-1) ~%")  
  )

(defun peel-test-1 ()
  (peel-test *potato-peeler*)
  ;; (rossrv-test)
  (warn "please run  (set-potato-1) ~%")  
  )

(defun set-potato-2 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 45) :y :world)
  ;; (set-potato)

  (before-set)
  (setq *pav2* #f(29.3712 -13.1062 93.1349 -89.4342 85.5752 -27.4285 -135.344))
  (send *pr2* :larm :angle-vector *pav2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (look-at-left-hand)
  (rossrv-test)
  (warn "please run  (peel-test-2) ~%")  
  )

(defun peel-test-2 ()
  (peel-test *potato-peeler*)
  (rossrv-test)
  (warn "please run  (set-potato-3) ~%")  
  )

(defun set-potato-3 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 90) :y :world)
  ;; (set-potato)

  (before-set)
  (setq *pav3* #f(28.2884 -16.5343 112.289 -98.9554 214.712 -30.3283 -233.037))
  (send *pr2* :larm :angle-vector *pav3*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (look-at-left-hand)
  (rossrv-test)
  (warn "please run  (peel-test-3) ~%")  
  )

(defun peel-test-3 ()
  (peel-test *potato-peeler*)
  (rossrv-test)
  (warn "please run  (set-potato-4) ~%")  
  )

(defun set-potato-4 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 135) :y :world)
  ;; (set-potato)

  (before-set)
  (setq *pav4* #f(28.498 4.8861 102.801 -88.3915 266.768 -43.3077 -225.862))
  (send *pr2* :larm :angle-vector *pav4*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (look-at-left-hand)
  (rossrv-test)
  (warn "please run  (peel-test-4) ~%")  
  )

(defun peel-test-4 ()
  (peel-test *potato-peeler*)
  (rossrv-test)
  (warn "please run  (set-potato-5) ~%")  
  )

(defun set-potato-5 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad -45) :y :world)
  ;; (set-potato)

  (before-set)
  (setq *pav5* #f(12.5442 -3.77784 81.0746 -39.5933 393.521 -101.403 -148.152))
  (send *pr2* :larm :angle-vector *pav5*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (look-at-left-hand)
  (rossrv-test)
  (warn "please run  (peel-test-5) ~%")  
  )

(defun peel-test-5 ()
  (peel-test *potato-peeler*)
  (rossrv-test)
  (warn "please run  (set-potato-6) ~%")  
  )

(defun set-potato-6 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad -90) :y :world)
  ;; (set-potato)

  (before-set)
  (setq *pav6* #f(8.25878 1.00486 91.3279 -28.0434 360.012 -114.592 -178.33))
  (send *pr2* :larm :angle-vector *pav6*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (look-at-left-hand)
  (rossrv-test)
  (warn "please run  (peel-test-6) ~%")  
  )

(defun peel-test-6 ()
  (peel-test *potato-peeler*)
  (rossrv-test)
  (warn "please run  (set-potato-7) ~%")  
  )

(defun set-potato-7 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad -135) :y :world)
  ;; (set-potato)

  (before-set)
  (setq *pav7* #f(7.81475 -3.27512 135.609 -38.5965 295.801 -113.625 -200.663))
  (send *pr2* :larm :angle-vector *pav7*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (look-at-left-hand)
  (rossrv-test)
  (warn "please run  (peel-test-7) ~%")  
  )

(defun peel-test-7 ()
  (peel-test *potato-peeler*)
  (rossrv-test)
  (warn "please run  (set-potato-8) ~%")  
  )

(defun set-potato-8 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 180) :y :world)
  ;; (set-potato)

  (before-set)
  (setq *pav8* #f(17.7551 -2.60738 124.713 -66.1764 283.114 -86.6007 -219.59))
  (send *pr2* :larm :angle-vector *pav8*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (look-at-left-hand)
  (rossrv-test)
  (warn "please run  (peel-test-8) ~%")  
  )

(defun peel-test-8 ()
  (peel-test *potato-peeler*)
  (rossrv-test)
  (warn "please run  (finish-pose-peel) ~%")  
  )


(defun finish-pose-peel ()
  ;; 手を少し上に
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(100 0 150) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; set pose
  (send *arrow* :newcoords (make-coords :pos #f(800.191 8689.104 30866.677) :rpy #f(-2.341 -0.222 -0.482)))
  (send *pr2* :rarm :inverse-kinematics
        *arrow*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)

  (warn "please run (put-potato)~%")
  )

(defun put-potato ()
  (send *pr2* :larm :end-coords :assoc *potato*)

  ;; 置く
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 500.0 8450.0 (+ 30850.0 (/ *height* 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  
  (send *p-arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *p-arrow* :copy-worldcoords)
        :move-target *potato*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *p-arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *p-arrow* :copy-worldcoords)
        :move-target *potato*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; release potato
  (send *pr2* :larm :end-coords :dissoc *potato*)
  (send *ri* :stop-grasp :larm :wait t)

  (warn "please run (reset-larm)~&")
  )

(defun regrasp-potato ()
  (send *pr2* :larm :end-coords :assoc *potato*)

  ;; 置く
  (send *p-arrow* :newcoords (make-coords :pos (float-vector 500.0 8450.0 (+ 30850.0 (/ *height* 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  
  (send *p-arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *p-arrow* :copy-worldcoords)
        :move-target *potato*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *p-arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *p-arrow* :copy-worldcoords)
        :move-target *potato*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; release potato
  (send *pr2* :larm :end-coords :dissoc *potato*)
  (send *ri* :stop-grasp :larm :wait t)
  
  ;; regrasp potato
  (send *pr2* :larm :end-coords :assoc *potato*)
  (send *ri* :start-grasp :larm :wait t)
  
  ;; (send *ri* :start-grasp :larm :wait t :gain 0.05)
  (send *ri* :start-grasp :larm :wait t :gain 0.1)
  
  ;; set potato
  (send *p-arrow* :newcoords (make-coords :pos (float-vector 500.0 8450.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (set-potato)
  
  (warn "please run (set-potato-2)~&")
  )

(defun reset-larm ()
  ;; 左手を少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 少し上にして水平に
  (send *arrow* :newcoords (make-coords :pos (send *arrow* :worldpos)))
  (send *arrow* :translate #f(0 0 50) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手前にする
  (send *arrow* :newcoords (make-coords :pos (send (send *pr2* :larm :end-coords) :worldpos)))
  (send *arrow* :translate #f(140 -100 90) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos #f(800.191 8310.896 30866.677) :rpy #f(2.341 -0.222 -0.133)))
  (send *pr2* :larm :inverse-kinematics
        *arrow*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 8000)
  (send *ri* :wait-interpolation)  
  )

(defun check-potato-1 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (set-potato)
  (warn "please run (set-potato-1-2) or (check-potato-2) ~%")  
  )

(defun check-potato-2 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 30) :world)
  (set-potato)
  (warn "please run (peel-test) or (check-potato-3) ~%")  
  )

(defun check-potato-3 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 60) :world)
  (set-potato)
  (warn "please run (peel-test) or (check-potato-4) ~%")  
  )

(defun check-potato-4 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 90) :world)
  (set-potato)
  (warn "please run (peel-test) or (check-potato-5) ~%")  
  )

(defun check-potato-5 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 120) :world)
  (set-potato)
  (warn "please run (peel-test) or (check-potato-6) ~%")  
  )

(defun check-potato-6 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 150) :world)
  (set-potato)
  (warn "please run (peel-test) or (check-potato-7) ~%")  
  )

(defun check-potato-7 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 180) :world)
  (set-potato)
  (warn "please run (peel-test) or (check-potato-8) ~%")  
  )

(defun check-potato-8 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 210) :world)
  (set-potato)
  (warn "please run (peel-test) or (check-potato-9) ~%")  
  )

(defun check-potato-9 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 240) :world)
  (set-potato)
  (warn "please run (peel-test) or (check-potato-10) ~%")  
  )

(defun check-potato-10 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 270) :world)
  (set-potato)
  (warn "please run (peel-test) or (check-potato-11) ~%")  
  )

(defun check-potato-11 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 300) :world)
  (set-potato)
  (warn "please run (peel-test) or (check-potato-12) ~%")  
  )

(defun check-potato-12 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 330) :world)
  (set-potato)
  (warn "please run (peel-test) or (put-potato) ~%")  
  )

;; set for failure
(defun fail-check ()
  (setq *fail-flag* nil)
  (setq gripper-len (send *ri* :state :gripper :larm :position))
  (if (< gripper-len 10)
      (setq *fail-flag* t))
  )

(defun now-set ()
  (recognition)
  (grasp-potato-peel)
  (put-potato)
  (reset-larm)
  )

;; rotate funcs
(defun grasp-potato-rotate ()
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
  (send *arrow* :rotate (deg2rad 90) :y)
  
  (send *arrow* :translate #f(-10 -15 0) :world)
  
  ;;gripperを開く
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;gripperを閉じる
  (send *ri* :start-grasp :larm :wait t)
  (send (send *pr2* :larm :end-coords) :assoc *potato*)
  (send *ri* :start-grasp :larm :wait t :gain 0.05)
  
  (warn "please run  (rotate-potato) ~%")
  )

(defun rotate-potato ()
  ;; 左手を上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; じゃがいもを位置に．
  (send *arrow* :newcoords (make-coords :pos (float-vector 500.0 8500.0 (+ 30850.0 (/ *height* 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (send *arrow* :rotate (deg2rad 180) :z :world)

  (send *arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target *potato*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target *potato*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :stop-grasp :larm)
  (send (send *pr2* :larm :end-coords) :dissoc *potato*)
  
  ;; 左手を上げる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run  (reset-larm) ~%")
  )


;; now funcs
(defun now-devel ()
  (set-potato-peel)
  (grasp-potato-peel)
  (set-peeler)
  (set-potato-1)
  (set-potato-1-2)
  (peel-test-1)
  (set-potato-2)
  (peel-test-2)
  (set-potato-3)
  (peel-test-3)
  (set-potato-4)
  (peel-test-4)
  (finish-pose-peel)
  (put-potato)
  (reset-larm)
  )



(defun now-test ()
  ;; (set-potato-peel :w *width* :l *length* :h *height*)
  (grasp-potato-peel)
  (set-potato-1)
  (set-peeler)
  (peel-test)
  (set-potato-2)
  (peel-test-2)
  (set-potato-3)
  (peel-test-3)
  (set-potato-4)
  (peel-test-4)
  (finish-pose-peel)
  (put-potato)
  (reset-larm)
  )


(defun exec-all ()
  ;; (set-potato-peel :w *width* :l *length* :h *height*)
  (grasp-potato-peel)
  (set-potato-1)
  (grasp-peeler)
  (peel-test)
  (set-potato-2)
  (peel-test-2)
  (set-potato-3)
  (peel-test-3)
  (set-potato-4)
  (peel-test-4)
  (finish-pose-peel)
  (put-potato)
  (reset-larm)
  )

(defun now-peel ()
  (recognition)
  (grasp-potato-peel)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (now-set)
        (return-from now-peel)))
  ;; (set-peeler)
  (set-potato-peeler)
  (set-potato-1)
  (set-potato-1-2)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (now-set)
        (return-from now-peel)))
  (setq adj (+ adj 10))
  (peel-test-1)
  (setq adj (- adj 10))
  (set-potato-1)
  (set-potato-2)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-2)
  (set-potato-3)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-3)
  (set-potato-4)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-4)
  (set-potato-5)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-5)
  (set-potato-6)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-6)
  (set-potato-7)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-7)
  (set-potato-8)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-8)
  (finish-pose-peel)
  (put-potato)
  (reset-larm)  
  )

(defun now-peel-old ()
  (recognition)
  (grasp-potato-peel)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/potato-fail-set.l")
        (now-set)
        (return-from now-peel)))
  (set-peeler)
  (set-potato-1)
  (set-potato-1-2)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/potato-fail-set.l")
        (now-set)
        (return-from now-peel)))
  (setq adj (+ adj 10))
  (peel-test-1)
  (setq adj (- adj 10))
  (set-potato-1)
  (set-potato-2)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/potato-fail-set.l")
        (now-set)
        (return-from now-peel)))
  (peel-test-2)
  (set-potato-3)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/potato-fail-set.l")
        (now-set)
        (return-from now-peel)))
  (peel-test-3)
  (set-potato-4)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/potato-fail-set.l")
        (now-set)
        (return-from now-peel)))
  (peel-test-4)
  (set-potato-5)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/potato-fail-set.l")
        (now-set)
        (return-from now-peel)))
  (peel-test-5)
  (set-potato-6)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/potato-fail-set.l")
        (now-set)
        (return-from now-peel)))
  (peel-test-6)
  (set-potato-7)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/potato-fail-set.l")
        (now-set)
        (return-from now-peel)))
  (peel-test-7)
  (set-potato-8)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/potato-fail-set.l")
        (now-set)
        (return-from now-peel)))
  (peel-test-8)
  (finish-pose-peel)
  (put-potato)
  (reset-larm)  
  )

(defun now-rotate ()
  (recognition)
  (grasp-potato-rotate)
  (rotate-potato)
  (reset-larm)
  )
