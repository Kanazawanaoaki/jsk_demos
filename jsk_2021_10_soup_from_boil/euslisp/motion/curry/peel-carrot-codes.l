(defun peel-carrot-init ()
  ;; init
  (load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/peel-potato-codes.l")
  
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

(peel-carrot-init)

(warn "If you use real robot, run (update-pos) ~%")
(warn "please run (now-transfer) or (now-transfer-bowl-1) ~%")

;; add for rec
(setq *y-thre* -10)

(defun recognition ()
  (setq found-obj nil)
  (setq cnt 0)
  (ros::unsubscribe *bbox-topic-name*)
  (until found-obj
     (print 4)
     (x::window-main-one) ;; IRT viewerの視点を変えられる。見にくければ変えよう

     (setq msg (one-shot-subscribe *bbox-topic-name* jsk_recognition_msgs::BoundingBoxArray :timeout 2000))
     (when msg
       (setq *width* 0)
       (setq *length* 0)
       (setq *height* 0)
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
             (send *ri* :speak-jp "認識に失敗しました") ;; 失敗しました．
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
  (load "package://jsk_2021_10_soup_from_boil/euslisp/model/carrot-ellipsoid-model.l")
  (setq *carrot* (carrot :w  *width* :l *length* :h *height*))
  (send *carrot* :newcoords (send *obj-coord* :copy-worldcoords))
  (send *carrot* :rotate (deg2rad 180) :x)
  
  (objects (list *carrot* *pr2* *cutting-board* *scene*))
  (send *irtviewer* :look-all
    (geo::make-bounding-box 
     (flatten (send-all (send *pr2* :bodies) :vertices))))
  (send *irtviewer* :draw-objects)
  
  (warn "please run (grasp-target) or (now-devel) ~%")
  )

;; def util-funcs

;; transfer funcs for carrot
(defun set-carrot-peel (&rest args &key (w 90) (l 60) (h 60) &allow-other-keys)
  (load "package://jsk_2021_10_soup_from_boil/euslisp/model/carrot-ellipsoid-model.l")
  
  (setq *width* w)
  (setq *length* l)
  (setq *height* h)
  
  (setq *carrot* (carrot :w w :l l :h h))
  (send *carrot* :transform (make-coords :pos (float-vector 500.0 8500.0 (+ 30850.0 (/ h 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  
  (objects (list *carrot* *pr2* *cutting-board* *scene*))
  (send *irtviewer* :look-all
	(geo::make-bounding-box 
	 (flatten (send-all (send *pr2* :bodies) :vertices))))
  
  (setq interval *height*)
  
  (warn "please run (grasp-carrot-peel) ~%")
  )

(defun grasp-carrot-peel ()
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
  
  ;; 人参の掴む所に
  (send *arrow* :newcoords (send *carrot* :copy-worldcoords))
  (send *arrow* :translate #f(-30 0 0))
  
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
  (send (send *pr2* :larm :end-coords) :assoc *carrot*)
  ;; (send *ri* :start-grasp :larm :wait t :gain 0.05)
  (send *ri* :start-grasp :larm :wait t :gain 0.1)
  
  ;; (warn "please run  (set-carrot-1) ~%")
  (warn "please run (set-peeler) or (grasp-peeler) ~%")
  )

(defun set-carrot ()
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
  
  ;; 人参を位置に．
  (send *pr2* :larm :inverse-kinematics
	(send *p-arrow* :copy-worldcoords)
	:move-target *carrot*
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
  
  (objects (list *carrot* *pr2* *cutting-board* *scene* *peeler*))
  (send *irtviewer* :look-all
	(geo::make-bounding-box 
	 (flatten (send-all (send *pr2* :bodies) :vertices))))
  
  (warn "please run (peel-test) ~%")
  )

;; (defun set-carrot-1 ()
;;   (setq *p-arrow* (arrow))
;;   (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
;;   ;; (set-carrot)

;;   (before-set)
;;   (setq *cav1* #f(22.3152 -20.2206 104.497 -67.2575 27.1601 -58.4014 241.489))
;;   (send *pr2* :larm :angle-vector *cav1*)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
;;   (send *ri* :wait-interpolation)
  
;;   (rossrv-test)
;;   (warn "please run  (set-carrot-1-2) ~%")  
;;   )

;; (defun set-carrot-1-2 ()
;;   (setq *p-arrow* (arrow))
;;   (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 500.0 8500.0 (+ 30850.0 (/ *height* 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
;;   ;; (set-carrot)

;;   (before-set)
;;   (setq *cav1-2* #f(22.2375 6.99489 100.811 -44.1724 41.1502 -65.4659 263.167))
;;   (send *pr2* :larm :angle-vector *cav1-2*)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
;;   (send *ri* :wait-interpolation)
  
;;   (warn "please run  (peel-test-c-1) ~%")  
;;   )

(defun peel-test-c-1 ()
  (peel-test *peeler*)
  ;; (rossrv-test) :: tmp-imadake
  (warn "please run  (set-carrot-1) ~%")  
  )

;; (defun set-carrot-2 ()
;;   (setq *p-arrow* (arrow))
;;   (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
;;   (send *p-arrow* :rotate (deg2rad 45) :y :world)
;;   ;; (set-carrot)

;;   (before-set)
;;   (setq *cav2* #f(29.8664 -13.2655 93.323 -89.495 84.5614 -27.1668 225.645))
;;   (send *pr2* :larm :angle-vector *cav2*)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
;;   (send *ri* :wait-interpolation)
  
;;   (rossrv-test)
;;   (warn "please run  (peel-test-c-2) ~%")  
;;   )

(defun peel-test-c-2 ()
  (peel-test *peeler*)
  ;; (rossrv-test) :: tmp-imadake
  (warn "please run  (set-carrot-3) ~%")  
  )

;; (defun set-carrot-3 ()
;;   (setq *p-arrow* (arrow))
;;   (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
;;   (send *p-arrow* :rotate (deg2rad 90) :y :world)
;;   ;; (set-carrot)

;;   (before-set)
;;   (setq *cav3* #f(28.6469 21.8904 67.0654 -99.0555 145.509 -29.3133 238.125))
;;   (send *pr2* :larm :angle-vector *cav3*)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
;;   (send *ri* :wait-interpolation)
  
;;   (rossrv-test)
;;   (warn "please run  (peel-test-c-3) ~%")  
;;   )

(defun peel-test-c-3 ()
  (peel-test *peeler*)
  ;; (rossrv-test) :: tmp-imadake
  (warn "please run  (set-carrot-4) ~%")  
  )

;; (defun set-carrot-4 ()
;;   (setq *p-arrow* (arrow))
;;   (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
;;   (send *p-arrow* :rotate (deg2rad 135) :y :world)
;;   ;; (set-carrot)

;;   (before-set)
;;   (setq *cav4* #f(26.0117 33.9343 63.1475 -89.1481 -16.6711 -10.7218 446.063))
;;   (send *pr2* :larm :angle-vector *cav4*)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
;;   (send *ri* :wait-interpolation)
  
;;   (rossrv-test)
;;   (warn "please run  (peel-test-c-4) ~%")  
;;   )

(defun peel-test-c-4 ()
  (peel-test *peeler*)
  ;; (rossrv-test) :: tmp-imadake
  (warn "please run  (set-carrot-5) ~%")  
  )

;; (defun set-carrot-5 ()
;;   (setq *p-arrow* (arrow))
;;   (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
;;   (send *p-arrow* :rotate (deg2rad -45) :y :world)
;;   ;; (set-carrot)

;;   (before-set)
;;   (setq *cav5* #f(11.4967 -14.8606 117.229 -40.0273 0.832231 -97.5426 585.576))
;;   (send *pr2* :larm :angle-vector *cav5*)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
;;   (send *ri* :wait-interpolation)
  
;;   (rossrv-test)
;;   (warn "please run  (peel-test-c-5) ~%")  
;;   )

(defun peel-test-c-5 ()
  (peel-test *peeler*)
  ;; (rossrv-test) :: tmp-imadake
  (warn "please run  (set-carrot-6) ~%")  
  )

;; (defun set-carrot-6 ()
;;   (setq *p-arrow* (arrow))
;;   (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
;;   (send *p-arrow* :rotate (deg2rad -90) :y :world)
;;   ;; (set-carrot)

;;   (before-set)
;;   (setq *cav6* #f(8.78136 0.997566 91.3453 -28.5004 0.010485 -114.592 541.679))
;;   (send *pr2* :larm :angle-vector *cav6*)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
;;   (send *ri* :wait-interpolation)
  
;;   (rossrv-test)
;;   (warn "please run  (peel-test-c-6) ~%")  
;;   )

(defun peel-test-c-6 ()
  (peel-test *peeler*)
  ;; (rossrv-test) :: tmp-imadake
  (warn "please run  (set-carrot-7) ~%")  
  )

;; (defun set-carrot-7 ()
;;   (setq *p-arrow* (arrow))
;;   (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
;;   (send *p-arrow* :rotate (deg2rad -135) :y :world)
;;   ;; (set-carrot)

;;   (before-set)
;;   (setq *cav7* #f(8.34967 -3.13322 134.846 -38.6712 -63.4229 -113.639 519.101))
;;   (send *pr2* :larm :angle-vector *cav7*)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
;;   (send *ri* :wait-interpolation)
  
;;   (rossrv-test)
;;   (warn "please run  (peel-test-c-7) ~%")  
;;   )

(defun peel-test-c-7 ()
  (peel-test *peeler*)
  ;; (rossrv-test) :: tmp-imadake
  (warn "please run  (set-carrot-8) ~%")  
  )

;; (defun set-carrot-8 ()
;;   (setq *p-arrow* (arrow))
;;   (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
;;   (send *p-arrow* :rotate (deg2rad 180) :y :world)
;;   ;; (set-carrot)

;;   (before-set)
;;   (setq *pav8* #f(17.7551 -2.60738 124.713 -66.1764 283.114 -86.6007 -219.59))
;;   (send *pr2* :larm :angle-vector *pav8*)
;;   (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
;;   (send *ri* :wait-interpolation)
  
;;   (rossrv-test)
;;   (warn "please run  (peel-test-c-8) ~%")  
;;   )

(defun peel-test-c-8 ()
  (peel-test *peeler*)
  ;; (rossrv-test) :: tmp-imadaken
  (warn "please run  (finish-pose-peel) ~%")  
  )


(defun put-carrot ()
  (send *pr2* :larm :end-coords :assoc *carrot*)

  ;; 置く
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 500.0 8450.0 (+ 30850.0 (/ *height* 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  
  (send *p-arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
	(send *p-arrow* :copy-worldcoords)
	:move-target *carrot*
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *p-arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
	(send *p-arrow* :copy-worldcoords)
	:move-target *carrot*
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; release carrot
  (send *pr2* :larm :end-coords :dissoc *carrot*)
  (send *ri* :stop-grasp :larm :wait t)

  (warn "please run (reset-larm)~&")
  )

(defun regrasp-carrot ()
  (send *pr2* :larm :end-coords :assoc *carrot*)

  ;; 置く
  (send *p-arrow* :newcoords (make-coords :pos (float-vector 500.0 8450.0 (+ 30850.0 (/ *height* 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  
  (send *p-arrow* :translate #f(0 0 80) :world)
  (send *pr2* :larm :inverse-kinematics
	(send *p-arrow* :copy-worldcoords)
	:move-target *carrot*
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *p-arrow* :translate #f(0 0 -80) :world)
  (send *pr2* :larm :inverse-kinematics
	(send *p-arrow* :copy-worldcoords)
	:move-target *carrot*
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; release carrot
  (send *pr2* :larm :end-coords :dissoc *carrot*)
  (send *ri* :stop-grasp :larm :wait t)

  ;; regrasp carrot
  (send *pr2* :larm :end-coords :assoc *carrot*)
  (send *ri* :start-grasp :larm :wait t)

  ;; (send *ri* :start-grasp :larm :wait t :gain 0.05)
  (send *ri* :start-grasp :larm :wait t :gain 0.1)

  ;; set carrot
  (send *p-arrow* :newcoords (make-coords :pos (float-vector 500.0 8400.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (set-carrot)

  (warn "please run (set-carrot-2)~&")
  )

(defun check-carrot-1 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (set-carrot)
  (warn "please run (set-carrot-1-2) or (check-carrot-2) ~%")  
  )

(defun check-carrot-2 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 30) :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-3) ~%")  
  )

(defun check-carrot-3 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 60) :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-4) ~%")  
  )

(defun check-carrot-4 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 90) :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-5) ~%")  
  )

(defun check-carrot-5 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 120) :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-6) ~%")  
  )

(defun check-carrot-6 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 150) :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-7) ~%")  
  )

(defun check-carrot-7 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 180) :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-8) ~%")  
  )

(defun check-carrot-8 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 210) :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-9) ~%")  
  )

(defun check-carrot-9 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 240) :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-10) ~%")  
  )

(defun check-carrot-10 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 270) :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-11) ~%")  
  )

(defun check-carrot-11 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 300) :world)
  (set-carrot)
  (warn "please run (peel-test) or (check-carrot-12) ~%")  
  )

(defun check-carrot-12 ()
  (setq *p-arrow* (arrow))
  (send *p-arrow* :newcoords (send (make-coords :pos (float-vector 570.0 8500.0 31100) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))) :copy-worldcoords))
  (send *p-arrow* :rotate (deg2rad 330) :world)
  (set-carrot)
  (warn "please run (peel-test) or (put-carrot) ~%")  
  )

(defun now-set ()
  (recognition)
  (grasp-carrot-peel)
  (put-carrot)
  (reset-larm)
  )

;; rotate funcs
(defun grasp-carrot-rotate ()
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
  
  ;; 人参の掴む所に
  (send *arrow* :newcoords (send *carrot* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 90) :y)

  (send *arrow* :translate #f(-10 -20 0) :world)

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
  (send (send *pr2* :larm :end-coords) :assoc *carrot*)
  (send *ri* :start-grasp :larm :wait t :gain 0.05)
  
  (warn "please run  (rotate-carrot) ~%")
  )

(defun rotate-carrot ()
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

  ;; 人参を位置に．
  (send *arrow* :newcoords (make-coords :pos (float-vector 500.0 8500.0 (+ 30850.0 (/ height 2))) :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))))
  (send *arrow* :rotate (deg2rad 180) :z :world)
  
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

  (send *ri* :stop-grasp :larm)
  (send (send *pr2* :larm :end-coords) :dissoc *carrot*)

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
  ;; (set-carrot-peel :w *width* :l *length* :h *height*)
  (grasp-carrot-peel)
  (set-carrot-1)
  (grasp-peeler)
  (peel-test)
  (set-carrot-2)
  (peel-test-c-2)
  (set-carrot-3)
  (peel-test-c-3)
  (set-carrot-4)
  (peel-test-c-4)
  (finish-pose-peel)
  (put-carrot)
  (reset-larm)
  )



(defun now-test ()
  ;; (set-carrot-peel :w *width* :l *length* :h *height*)
  (grasp-carrot-peel)
  (set-carrot-1)
  (set-peeler)
  (peel-test)
  (set-carrot-2)
  (peel-test-c-2)
  (set-carrot-3)
  (peel-test-c-3)
  (set-carrot-4)
  (peel-test-c-4)
  (finish-pose-peel)
  (put-carrot)
  (reset-larm)
  )


(defun exec-all ()
  ;; (set-carrot-peel :w *width* :l *length* :h *height*)
  (grasp-carrot-peel)
  (set-carrot-1)
  (grasp-peeler)
  (peel-test)
  (set-carrot-2)
  (peel-test-c-2)
  (set-carrot-3)
  (peel-test-c-3)
  (set-carrot-4)
  (peel-test-c-4)
  (finish-pose-peel)
  (put-carrot)
  (reset-larm)
  )

(defun now-peel ()
  (recognition)
  (grasp-carrot-peel)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (now-set)
        (return-from now-peel)))
  (set-peeler)
  (set-potato-1)
  (set-potato-1-2)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (now-set)
        (return-from now-peel)))
  (setq adj (+ adj 10))
  (peel-test-c-1)
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
  (peel-test-c-2)
  (set-potato-3)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-c-3)
  (set-potato-4)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-c-4)
  (set-potato-5)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-c-5)
  (set-potato-6)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-c-6)
  (set-potato-7)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-c-7)
  (set-potato-8)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-c-8)
  (finish-pose-peel)
  (put-carrot)
  (reset-larm)  
  )

(defun now-peel-old ()
  (recognition)
  (grasp-carrot-peel)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
	(reset-larm)
	(load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/carrot-fail-set.l")
	(now-set)
	(return-from now-peel)))
  (set-peeler)
  (set-carrot-1)
  (set-carrot-1-2)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
	(reset-larm)
	(load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/carrot-fail-set.l")
	(now-set)
	(return-from now-peel)))
  (setq adj (+ adj 10))
  (peel-test-c-1)
  (setq adj (- adj 10))
  (set-carrot-1)
  (set-carrot-2)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
	(reset-larm)
	(finish-pose-peel)
	(load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/carrot-fail-set.l")
	(now-set)
	(return-from now-peel)))
  (peel-test-c-2)
  (set-carrot-3)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
	(reset-larm)
	(finish-pose-peel)
	(load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/carrot-fail-set.l")
	(now-set)
	(return-from now-peel)))
  (peel-test-c-3)
  (set-carrot-4)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
	(reset-larm)
	(finish-pose-peel)
	(load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/carrot-fail-set.l")
	(now-set)
	(return-from now-peel)))
  (peel-test-c-4)
  (set-carrot-5)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
	(reset-larm)
	(finish-pose-peel)
	(load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/carrot-fail-set.l")
	(now-set)
	(return-from now-peel)))
  (peel-test-c-5)
  (set-carrot-6)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
	(reset-larm)
	(finish-pose-peel)
	(load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/carrot-fail-set.l")
	(now-set)
	(return-from now-peel)))
  (peel-test-c-6)
  (set-carrot-7)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
	(reset-larm)
	(finish-pose-peel)
	(load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/carrot-fail-set.l")
	(now-set)
	(return-from now-peel)))
  (peel-test-c-7)
  (set-carrot-8)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
	(reset-larm)
	(finish-pose-peel)
	(load "package://jsk_2021_10_soup_from_boil/euslisp/motion/curry/fail-set/carrot-fail-set.l")
	(now-set)
	(return-from now-peel)))
  (peel-test-c-8)
  (finish-pose-peel)
  (put-carrot)
  (reset-larm)  
  )


(defun now-rotate ()
  (recognition)
  (grasp-carrot-rotate)
  (rotate-carrot)
  (reset-larm)
  )



(defun tmp-start ()
  (recognition)
  (grasp-carrot-peel)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (now-set)
        (return-from now-peel)))
  (set-peeler)
  (set-potato-1)
  (set-potato-1-2)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (now-set)
        (return-from now-peel)))
  (warn "please run (tmp-after) ~%")
  )

(defun tmp-after ()
  (send *ri* :speak-jp "皮むきを開始します")
  
  (setq adj (+ adj 10))
  (peel-test-c-1)
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
  (peel-test-c-2)
  (set-potato-3)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-c-3)
  (set-potato-4)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-c-4)
  (set-potato-5)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-c-5)
  (set-potato-6)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-c-6)
  (set-potato-7)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-c-7)
  (set-potato-8)
  (fail-check)
  (if (eql *fail-flag* t)
      (progn
        (reset-larm)
        (finish-pose-peel)
        (now-set)
        (return-from now-peel)))
  (peel-test-c-8)
  (finish-pose-peel)
  (put-carrot)
  (reset-larm)  
  )

