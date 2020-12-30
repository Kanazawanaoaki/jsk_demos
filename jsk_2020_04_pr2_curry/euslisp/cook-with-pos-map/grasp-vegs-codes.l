(defun grasp-vegs-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")
  

  ;; set global coodes
  (setq *potato-stand-coords* (make-coords :pos (float-vector 310.071 8313.284 30937.902) :rpy (float-vector 3.142 0 0)))
  (setq *carrot-stand-coords* (make-coords :pos (float-vector 309.029 8399.786 30942.039) :rpy (float-vector 3.142 0 0)))
  (setq *onion-stand-coords* (make-coords :pos (float-vector 314.539 8479.935 30946.933) :rpy (float-vector 3.142 0 0)))
  
  ;; set objscts
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/cutting-board.l")
  (setq *cutting-board* (cutting-board))
  (send *cutting-board* :newcoords (send *cutting-board-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/potato-new-type.l")
  (setq *potato* (potato :w 90 :l 60 :h 60))
  ;; (send *potato* :transform (make-coords :pos (float-vector 310.071 8313.284 30937.902) :rpy (float-vector 3.142 0 0)))
  (send *potato* :newcoords (send *potato-stand-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/carrot-ellipsoid-model.l")
  (setq *carrot* (carrot :w 140 :l 50 :h 50))
  ;; (send *carrot* :transform (make-coords :pos (float-vector 309.029 8399.786 30942.039) :rpy (float-vector 3.142 0 0)))
  (send *carrot* :newcoords (send *carrot-stand-coords* :copy-worldcoords))
  
  (setq *onion* (make-cube 100 50 40))
  (send *onion* :set-color :green)
  ;; (send *onion* :transform (make-coords :pos (float-vector 314.539 8479.935 30946.933) :rpy (float-vector 3.142 0 0)))
  (send *onion* :newcoords (send *onion-stand-coords* :copy-worldcoords))
  
  (move-to-kitchen-irt)
  (objects (list *pr2* *scene* *cutting-board* *potato* *carrot* *onion*))
  (update-view)  
  )

(grasp-vegs-init)

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

;; ;; add for rosservice
;; (ros::load-ros-manifest "std_srvs")
;; (ros::wait-for-service "after_stow_data_collection/save_request")
;; (setq req (instance std_srvs::TriggerRequest :init))


;; (defun rossrv-test ()
;;   (setq res (ros::service-call "after_stow_data_collection/save_request" req t))
;;   )

;; (defun look-at-left-hand ()
;;   (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
;;   (send *pr2* :head :look-at (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos))
;;   (send *viewer* :draw-objects)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
;;   (send *ri* :wait-interpolation)
;;   )


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
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/potato-new-type.l")
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
(defun reset-larm ()
  ;; 左手を少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view nil
        :stop 20)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; 少し上にして水平に
  ;; (setq *lav1* (float-vector 16.6498 -20.1996 123.812 -51.9785 -42.6397 -65.2851 -0.059116))
  ;; (send *pr2* :larm :angle-vector *lav1*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 509.999 8489.998 31189.999) :rpy (float-vector 1.571 0.0 1.349)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; 手前にする
  ;; (setq *lav2* (float-vector 41.8129 -20.2467 85.9536 -82.3235 -13.8272 -47.9804 -0.0))
  ;; (send *pr2* :larm :angle-vector *lav2*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 660.0 8390.0 31290.0) :rpy (float-vector 1.571 0.0 1.722)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; (setq *lav3* (float-vector 75.8217 52.0712 108.49 -109.796 -2.86542 -9.47056 -0.0))
  ;; (send *pr2* :larm :angle-vector *lav3*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 800.188 8310.893 30866.671) :rpy (float-vector 2.341 -0.222 0.589)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)  
  
  (setq *lav4* (float-vector 75.0 50.0 110.0 -110.0 -20.0 -10.0 -10.0))
  (send *pr2* :larm :angle-vector *lav4*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  
  )

;; def funcs
(defun set-vegs-model (veg)
  (if (not (eql (send veg :parent) nil))
      (send (send veg :parent) :dissoc veg))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send veg :copy-worldcoords))
    (send local-cds :translate #f(-20 0 0))
    (send local-cds :rotate (deg2rad 45) :y)
    (send local-cds :assoc veg)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc veg)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc veg)
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
  
  ;; (send *arrow* :translate #f(-10 -15 -5) :world)
  
  ;;gripperを開く
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate #f(100 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(-100 0 -100) :world)
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
  
  (set-vegs-model *potato*)
  
  (warn "please run (after-grasp-vegs) ~%")
  )


(defun grasp-carrot ()
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
  (send *arrow* :newcoords (send *carrot* :copy-worldcoords))
  (send *arrow* :translate #f(-20 0 0))
  (send *arrow* :rotate (deg2rad 45) :y)
  
  ;; (send *arrow* :translate #f(-10 -15 -5) :world)
  
  ;;gripperを開く
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate #f(100 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(-100 0 -100) :world)
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
  
  (set-vegs-model *carrot*)
  
  (warn "please run (after-grasp-vegs) ~%")
  )

(defun grasp-onion ()
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
  (send *arrow* :newcoords (send *onion* :copy-worldcoords))
  (send *arrow* :translate #f(-20 0 0))
  (send *arrow* :rotate (deg2rad 45) :y)
  
  ;; (send *arrow* :translate #f(-10 -15 -5) :world)
  
  ;;gripperを開く
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :translate #f(100 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(-100 0 -100) :world)
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
  
  (set-vegs-model *onion*)
  
  (warn "please run (after-grasp-vegs) ~%")
  )

(defun after-grasp-vegs ()
  ;; 左手を少しあげる
  (send *pr2* :larm :move-end-pos #f(100 0 100) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 0 100) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (vegs-carry-pose) ~%")  
  )

(defun vegs-carry-pose ()
  (setq *lav-cm* #f(38.442 -20.2481 94.8038 -104.353 117.885 -64.3683 -258.356))
  (send *pr2* :larm :angle-vector *lav-cm*)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 604.833 8300.101 31079.393) :rpy (float-vector 3.141 0.75 0.0)))
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 8000)
  (send *ri* :wait-interpolation)

  (warn "please go to sink spot !! ~%")  
  )

(defun put-carrot-on-board ()
  (set-vegs-model *carrot*)
  
  (send *arrow* :newcoords (send (make-coords :pos (float-vector 500.0 8450.0 30870.0) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target *carrot*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target *carrot*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; release carrot
  (send *pr2* :larm :end-coords :dissoc *carrot*)
  (send *ri* :stop-grasp :larm :wait t)

  (warn "please run (reset-larm) ~%")  
  )

(defun put-potato-on-board ()
  (set-vegs-model *potato*)

  (send *arrow* :newcoords (send (make-coords :pos (float-vector 500.0 8450.0 30870.0) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
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

  ;; release potato
  (send *pr2* :larm :end-coords :dissoc *potato*)
  (send *ri* :stop-grasp :larm :wait t)

  (warn "please run (reset-larm) ~%")  
  )

(defun put-onion-on-board ()
  (set-vegs-model *onion*)
  
  (send *arrow* :newcoords (send (make-coords :pos (float-vector 500.0 8450.0 30870.0) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target *onion*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target *onion*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; release onion
  (send *pr2* :larm :end-coords :dissoc *onion*)
  (send *ri* :stop-grasp :larm :wait t)

  (warn "please run (reset-larm) ~%")  
  )



(defun put-carrot-on-stand ()
  (set-vegs-model *carrot*)
  
  (send *arrow* :newcoords (send *carrot-stand-coords* :copy-worldcoords))
  (send *arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target *carrot*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target *carrot*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; release carrot
  (send *pr2* :larm :end-coords :dissoc *carrot*)
  (send *ri* :stop-grasp :larm :wait t)  

  (warn "please run (reset-larm) ~%")  
  )

(defun put-potato-on-stand ()
  (set-vegs-model *potato*)
    
  (send *arrow* :newcoords (send *potato-stand-coords* :copy-worldcoords))
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
  
  ;; release potato
  (send *pr2* :larm :end-coords :dissoc *potato*)
  (send *ri* :stop-grasp :larm :wait t)  

  (warn "please run (reset-larm) ~%")  
  )

(defun put-onion-on-stand ()
  (set-vegs-model *onion*)
  
  (send *arrow* :newcoords (send *onion-stand-coords* :copy-worldcoords))
  (send *arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target *onion*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target *onion*
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; release onion
  (send *pr2* :larm :end-coords :dissoc *onion*)
  (send *ri* :stop-grasp :larm :wait t)  

  (warn "please run (reset-larm) ~%")  
  )


;; defun now-funcs
(defun now-grasp-potato ()
  (grasp-potato)
  (after-grasp-vegs)
  (vegs-carry-pose)
  )

(defun now-grasp-carrot ()
  (grasp-carrot)
  (after-grasp-vegs)
  (vegs-carry-pose)  
  )

(defun now-grasp-onion ()
  (grasp-onion)
  (after-grasp-vegs)
  (vegs-carry-pose)
  )


(defun now-put-potato-on-board ()
  (put-potato-on-board)
  (reset-larm)
  )

(defun now-put-carrot-on-board ()
  (put-carrot-on-board)
  (reset-larm)
  )

(defun now-put-onion-on-board ()
  (put-onion-on-board)
  (reset-larm)
  )

(defun now-put-potato-on-stand ()
  (put-potato-on-stand)
  (reset-larm)
  )

(defun now-put-carrot-on-stand ()
  (put-carrot-on-stand)
  (reset-larm)
  )

(defun now-put-onion-on-stand ()
  (put-onion-on-stand)
  (reset-larm)
  )
