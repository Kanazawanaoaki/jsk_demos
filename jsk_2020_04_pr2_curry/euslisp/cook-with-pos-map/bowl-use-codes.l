(defun bowl-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/tool-use-codes.l")
  
  ;; set objects
  (send *spatula* :newcoords (send *spatula-coords-1* :copy-worldcoords)) ;; spatula on the cutting board
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/measuring-cup-73b2.l")
  (setq *mcup* (measuring-cup-73b2))
  (send *mcup* :newcoords (send *mcup-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/cooking-pot-73b2.l")
  (setq *pot* (cooking-pot))
  (send *pot* :newcoords (send *pot-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/bowl-1.l")
  (setq *bowl-1* (bowl-1))
  (send *bowl-1* :newcoords (send *bowl-1-coords* :copy-worldcoords))

  (load "package://jsk_2020_04_pr2_curry/euslisp/model/bowl-2.l")
  (setq *bowl-2* (bowl-2))
  (send *bowl-2* :newcoords (send *bowl-2-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/bowl-3.l")
  (setq *bowl-3* (bowl-3))
  (send *bowl-3* :newcoords (send *bowl-3-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/bowl-4.l")
  (setq *bowl-4* (bowl-4))
  (send *bowl-4* :newcoords (send *bowl-4-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/dispenser.l")
  (setq *oil-dispenser* (dispenser))
  (send *oil-dispenser* :newcoords (send *oil-dispenser-coords* :copy-worldcoords))
  
  (objects (list *pr2* *scene* *spatula* *mcup* *ladle* *pot* *bowl-1* *bowl-2* *bowl-3* *bowl-4* *oil-dispenser*))
  (update-view)
  
  ;; def bowl grasp coords
  (setq *bowl-1-grasp-coords* (make-coords :pos (float-vector 383 8425 30889) :rpy (float-vector 2.892 1.01 1.404))) 
  (setq *bowl-2-grasp-coords* (make-coords :pos (float-vector 344 8616 30880) :rpy (float-vector 3.016 0.995 1.718)))
  (setq *bowl-2-grasp-set-coords* (make-coords :pos (float-vector 558.94 8455.526 30890.992) :rpy (float-vector -2.649 1.102 1.301)))
  (setq *bowl-2-grasp-set-larm-coords* (make-coords :pos (float-vector 550.455 8389.4 30870.472) :rpy (float-vector 3.006 0.965 1.642)))
  
  (setq *bowl-3-grasp-coords* (make-coords :pos (float-vector 672 7632 30873) :rpy (float-vector -2.152 1.02 1.606)))
  (setq *bowl-4-grasp-coords* (make-coords :pos (float-vector 567 7824 30920) :rpy (float-vector -2.624 1.195 2.113)))
  
  (move-to-kitchen-irt)
  )

(bowl-init)


;; add for sense rec
(setq *x-thre* -10)

(ros::roseus "bowl_transfer_test" :anonymous t)
(setq *topic-name* "/right_endeffector/wrench")
(ros::load-ros-manifest "geometry_msgs")
(setq *cb-flag* nil)
(defun wrench-x-cb (msg)
  (when msg
    (let ((x nil))
      (setq x (send msg :wrench :force :x))
      (if (< x *x-thre*)
          (progn 
            (setq *cb-flag* t)
            (format t "OK!! x: ~A ~%" x)
            )
        (format t "x: ~A ~%" x))
      )))


(warn "If you use real robot, run (update-pos) ~%")
(warn "please run (now-set-bowls) or (set-bowl-1) ~%")

;; def util-funcs
(defun reset-rarm ()
  (setq *rav0* (float-vector -25.6468 7.87241 -48.2704 -85.3763 253.675 -77.8887 -147.102))
  (send *pr2* :rarm :angle-vector *rav0*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  
  (setq *rav1* (float-vector -20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (setq *rav3* (float-vector -75.0 50.0 -110.0 -110.0 20.0 -10.0 -10.0))
  (send *pr2* :rarm :angle-vector *rav3*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun reset-larm ()
  ;; 左手を少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view nil)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; 少し上にして水平に
  (setq *lav1* (float-vector 16.6498 -20.1996 123.812 -51.9785 -42.6397 -65.2851 -0.059116))
  (send *pr2* :larm :angle-vector *lav1*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; 手前にする
  (setq *lav2* (float-vector 41.8129 -20.2467 85.9536 -82.3235 -13.8272 -47.9804 -0.0))
  (send *pr2* :larm :angle-vector *lav2*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (setq *lav3* (float-vector 75.8217 52.0712 108.49 -109.796 -2.86542 -9.47056 -0.0))
  (send *pr2* :larm :angle-vector *lav3*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)  
  
  (setq *lav4* (float-vector 75.0 50.0 110.0 -110.0 -20.0 -10.0 -10.0))
  (send *pr2* :larm :angle-vector *lav4*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  
  )

(defun before-recieve-larm ()
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
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 600 8361 31167) :rpy (float-vector 1.571 1.047 1.571)))
  ;; (send *pr2* :larm :inverse-kinematics
  ;; 	(send *arrow* :copy-worldcoords)
  ;; 	:rotation-axis t
  ;; 	:debug-view *debug-flag*)
  (send *pr2* :larm :angle-vector #f(30.046 -16.1647 77.4608 -67.7082 57.0472 -86.8259 -43.9204))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  )

(defun put-bowl-larm ()
  ;; (send *arrow* :translate (float-vector 0 0 200) :world) ;; がしてある状態で使う
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :larm :wait t)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view nil)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


(defun before-recieve-rarm ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 250) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis nil
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;少し前に
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 600 8739 31167) :rpy (float-vector -1.571 1.047 1.571)))
  ;; (send *pr2* :rarm :inverse-kinematics
  ;; 	(send *arrow* :copy-worldcoords)
  ;; 	:rotation-axis t
  ;; 	:debug-view *debug-flag*)
  (send *pr2* :rarm :angle-vector #f(-37.8868 -20.239 -85.7141 -64.0592 312.721 -87.1625 -148.994))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun put-bowl-rarm ()
  ;; (send *arrow* :translate (float-vector 0 0 200) :world) ;; がしてある状態で使う
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm :wait t)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation) 
  )

(defun grasp-bowl-larm ()
  (before-recieve-larm)

  (send *ri* :stop-grasp :larm :wait t)
  
  ;; ボウルの位置
  (send *arrow* :newcoords (send *target* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :larm :wait t)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  )

(defun grasp-bowl-rarm ()
  (before-recieve-rarm)
  
  (send *ri* :stop-grasp :rarm :wait t)
  
  ;; ボウルの位置
  (send *arrow* :newcoords (send *target* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :rarm :wait t)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  )


;; bowl funcs
(defun recieve-bowl-1 ()
  (before-recieve-larm)
  
  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "ボウル１を握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :larm :wait t)

  (warn "please run (put-bowl-1) ~%")
  )

(defun put-bowl-1 ()
  ;; ボウル１を置く位置
  (send *arrow* :newcoords (send *bowl-1-grasp-coords* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)

  (put-bowl-larm)
  )

(defun recieve-bowl-2 ()
  (before-recieve-rarm)
  
  (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :speak-jp "ボウル２を握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t)

  (warn "please run (put-bowl-2) ~%")
  )

(defun put-bowl-2 ()
  ;; ボウル２を置く位置
  (send *arrow* :newcoords (send *bowl-2-grasp-coords* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)

  (put-bowl-rarm)  
  )


(defun recieve-bowl-3 ()
  (before-recieve-larm)
  
  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "ボウル３を握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :larm :wait t)

  (warn "please run (put-bowl-3) ~%")
  )

(defun recieve-bowl-4 ()
  (before-recieve-larm)
  
  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "ボウル４を握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :larm :wait t)

  (warn "please run (put-bowl-4) ~%")
  )


(defun put-bowl-3 ()
  (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  (send *pr2* :larm :angle-vector *larm1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; ボウル３を置く位置
  (send *arrow* :newcoords (send *bowl-3-grasp-coords* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)

  (put-bowl-larm)  
  )

(defun put-bowl-4 ()
  (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  (send *pr2* :larm :angle-vector *larm1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; ボウル４を置く位置
  (send *arrow* :newcoords (send *bowl-4-grasp-coords* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)

  (put-bowl-larm)  
  )

(defun grasp-bowl-3 ()
  ;; ボウル１の位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send *bowl-3-grasp-coords* :copy-worldcoords))
  
  (grasp-bowl-larm)

  (warn "please run (transfer-to-pot) ~%")  
  )

(defun grasp-bowl-4 ()
  ;; ボウル１の位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send *bowl-4-grasp-coords* :copy-worldcoords))
  
  (grasp-bowl-larm)

  (warn "please run (transfer-to-pot) ~%")  
  )


(defun grasp-bowl-2 ()
  ;; ボウル２の位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send *bowl-2-grasp-coords* :copy-worldcoords))
  
  (grasp-bowl-rarm)
  
  (warn "please run (move-bowl-2-set) ~%")
  )

(defun move-bowl-2-set ()
  (send *pr2* :rarm :move-end-pos (float-vector 100 0 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  ;; ボウル２を置く位置 set
  (send *arrow* :newcoords (send *bowl-2-grasp-set-coords* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  
  (put-bowl-rarm)  
  )


(defun grasp-bowl-2-set ()
  ;; ボウル２の位置 set
  (setq *target* (make-coords))
  (send *target* :newcoords (send *bowl-2-grasp-set-larm-coords* :copy-worldcoords))
  
  (grasp-bowl-larm)

  (warn "please run (transfer-to-pot) ~%")  
  )

(defun put-bowl-2-set ()
  ;; ボウル２の位置 set
  (send *arrow* :newcoords (send *bowl-2-grasp-set-larm-coords* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  
  (put-bowl-larm)
  )

(defun grasp-bowl-1 ()
  ;; ボウル１の位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send *bowl-1-grasp-coords* :copy-worldcoords))
  
  (grasp-bowl-larm)

  (warn "please run (transfer-to-pot) ~%")  
  )

(defun grasp-bowl-2-set-rarm ()
  ;; ボウル２の位置 set
  (setq *target* (make-coords))
  (send *target* :newcoords (send *bowl-2-grasp-set-coords* :copy-worldcoords))
  
  (grasp-bowl-rarm)
  
  (warn "please run (put-bowl-2) ~%")  
  )

;; transfer funcs
(defun transfer-to-pot ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 550.911 8325.179 31085.843) :rpy (float-vector 2.561 1.128 2.104))) ;; for eng2 model
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos (float-vector 0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos (float-vector 0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos (float-vector 0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  (send *pr2* :larm :angle-vector *larm1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (setq *larm2* (float-vector 35.0371 5.51912 50.9811 -60.5584 159.61 -110.561 -25.9414))
  (send *pr2* :larm :angle-vector *larm2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 463.549 8018.53 31099.284) :rpy (float-vector -1.743 0.802 -1.842))) ;; for end2 model
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 463.549 1518.534 1099.284) :rpy (float-vector -1.743 0.802 -1.842)))
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 465 8005 31130) :rpy (float-vector -1.571 0.436 -1.571))) ;; for eng2 model
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 465 1505 1130) :rpy (float-vector -1.571 0.436 -1.571))) 
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (after-transfer) ~%")  
  )

(defun after-transfer ()
  (setq *larm2* (float-vector 35.0371 5.51912 50.9811 -60.5584 159.61 -110.561 -25.9414))
  (send *pr2* :larm :angle-vector *larm2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  (send *pr2* :larm :angle-vector *larm1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos (float-vector 0 100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos (float-vector 0 100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos (float-vector 0 100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (put-bowl-1) or (put-bowl-2-set) ~%")  
  )


(defun transfer-to-pot-left ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 609.875 7802.164 31145.744) :rpy (float-vector 2.719 0.798 1.816))) ;; for eng2 model
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos (float-vector -100 100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  (send *pr2* :larm :angle-vector *larm1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (setq *larm2* (float-vector 35.0371 5.51912 50.9811 -60.5584 159.61 -110.561 -25.9414))
  (send *pr2* :larm :angle-vector *larm2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 463.549 8018.53 31099.284) :rpy (float-vector -1.743 0.802 -1.842))) ;; for end2 model
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 465 8005 31130) :rpy (float-vector -1.571 0.436 -1.571))) ;; for eng2 model
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (after-transfer-left) ~%")
  )

(defun after-transfer-left ()
  (setq *larm2* (float-vector 35.0371 5.51912 50.9811 -60.5584 159.61 -110.561 -25.9414))
  (send *pr2* :larm :angle-vector *larm2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  (send *ri* :wait-interpolation)

  (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  (send *pr2* :larm :angle-vector *larm1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos (float-vector 100 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (put-bowl-3) or (put-bowl-4) ~%")  
  )


;; spatula funcs
(defun squeeze-test-set ()
  (send *ri* :start-grasp :rarm :gain 30 :wait t)
  
  (setq *rav0* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav0*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (make-coords :pos (float-vector 600 8550 31145) :rpy (float-vector -3.048 -0.062 -1.634)))
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 550 8400 31150) :rpy (float-vector -1.603 0.03 -0.018)))
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:move-target (car (send *spatula* :attention))
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 500 8200 31080) :rpy (float-vector -1.603 0.03 -0.018)))
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:move-target (car (send *spatula* :attention))
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate #f(0 70 -60) :world)
  (send *arrow* :rotate (deg2rad -90) :z)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:move-target (car (send *spatula* :attention))
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (squeeze-test) ~%")
  )

(defun squeeze-test ()
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate (float-vector 0 50 -50) :world)
  (send *arrow* :rotate (deg2rad -90) :z)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:move-target (elt (send *spatula* :attention) 1) ;;(car (send *spatula* :attention))
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 15)
    (send *arrow* :translate (float-vector 0 -10 0) :world)
    (send *pr2* :rarm :inverse-kinematics
	  (send *arrow* :copy-worldcoords)
	  :move-target (elt (send *spatula* :attention) 1) ;;(car (send *spatula* :attention))
	  :rotation-axis t
	  :debug-view nil)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )
  (send *ri* :angle-vector-sequence avs tms)
  
  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-x-cb)
  
  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
            (ros::spin-once)
            (if *cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      (warn "cancel!!! ~%")
      )
    )
  
  (ros::unsubscribe "/right_endeffector/wrench")
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (elt (send *spatula* :attention) 1) :copy-worldcoords))
  
  (setq avs (list))
  (setq tms (list))

  ;; tmp 
  (setq height (- (elt (send (send *arrow* :copy-worldcoords) :worldpos) 2) 30960))
  
  (send *arrow* :translate (float-vector 0 0 (* height -0.5)) :world)
  (send *arrow* :rotate (deg2rad 10) :y)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:move-target (elt (send *spatula* :attention) 1) ;;(car (send *spatula* :attention))
  	:rotation-axis t
  	:debug-view nil)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 800)))
  
  (send *arrow* :translate (float-vector 0 40 (* height -0.3)) :world)
  (send *arrow* :rotate (deg2rad 10) :y)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:move-target (elt (send *spatula* :attention) 1) ;;(car (send *spatula* :attention))
  	:rotation-axis t
  	:debug-view nil)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 800)))
  
  (send *arrow* :translate (float-vector 0 40 (* height -0.3)) :world)
  (send *arrow* :rotate (deg2rad 10) :y)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:move-target (elt (send *spatula* :attention) 1) ;;(car (send *spatula* :attention))
  	:rotation-axis t
  	:debug-view nil)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 800)))
    
  ;; (send *arrow* :translate #f(0 0 -60) :world)
  ;; (send *arrow* :rotate (deg2rad 10) :y)
  ;; (send *pr2* :rarm :inverse-kinematics
  ;; 	(send *arrow* :copy-worldcoords)
  ;; 	:move-target (elt (send *spatula* :attention) 1) ;;(car (send *spatula* :attention))
  ;; 	:rotation-axis t
  ;; 	:debug-view nil)
  ;; (setq av (send *pr2* :angle-vector))
  ;; (setq avs (append avs (list av)))
  ;; (setq tms (append tms (list 800)))
  
  ;; (send *arrow* :translate #f(0 50 -40) :world)
  ;; (send *arrow* :rotate (deg2rad 10) :y)
  ;; (send *pr2* :rarm :inverse-kinematics
  ;; 	(send *arrow* :copy-worldcoords)
  ;; 	:move-target (elt (send *spatula* :attention) 1) ;;(car (send *spatula* :attention))
  ;; 	:rotation-axis t
  ;; 	:debug-view nil)
  ;; (setq av (send *pr2* :angle-vector))
  ;; (setq avs (append avs (list av)))
  ;; (setq tms (append tms (list 800)))

  ;; (send *arrow* :translate #f(0 40 -30) :world)
  ;; (send *arrow* :rotate (deg2rad 10) :y)
  ;; (send *pr2* :rarm :inverse-kinematics
  ;; 	(send *arrow* :copy-worldcoords)
  ;; 	:move-target (elt (send *spatula* :attention) 1) ;;(car (send *spatula* :attention))
  ;; 	:rotation-axis t
  ;; 	:debug-view nil)
  ;; (setq av (send *pr2* :angle-vector))
  ;; (setq avs (append avs (list av)))
  ;; (setq tms (append tms (list 800)))

  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send (elt (send *spatula* :attention) 1) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 30 30) :world)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
	:move-target (elt (send *spatula* :attention) 1)
  	:rotation-axis t
  	:debug-view nil)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)  
  
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate #f(0 60 -50) :world)
  (send *arrow* :rotate (deg2rad -90) :z)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:move-target (car (send *spatula* :attention))
  	:rotation-axis t
  	:debug-view nil)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


(defun avoid-rarm ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 471 8105 31070) :rpy (float-vector -1.603 0.03 -0.018)))
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:move-target (car (send *spatula* :attention))
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (make-coords :pos (float-vector 550 8450 31150) :rpy (float-vector -1.603 0.03 -0.018)))
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:move-target (car (send *spatula* :attention))
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (make-coords :pos (float-vector 600 8600 31145) :rpy (float-vector -3.048 -0.062 -1.634)))
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq *rav0* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav0*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (after-transfer) ~%")
  )


;; mcup codes tmp
(defun set-mcup ()
  (if (not (eql (send *mcup* :parent) nil))
      (send (send *mcup* :parent) :dissoc *mcup*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *mcup* :handle-handle1) :copy-worldcoords))
    (send local-cds :assoc *mcup*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *mcup*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *mcup*)
  )

(defun grasp-mcup ()
  ;; mcupの位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *mcup* :handle-handle1) :copy-worldcoords))
  
  (grasp-bowl-larm)

  (set-mcup)
  
  (warn "please run (carry-mcup-pose) ~%")
  )

(defun put-mcup ()
  ;; mcupを置く位置
  (if (not (eql (send *mcup* :parent) nil))
      (send (send *mcup* :parent) :dissoc *mcup*))
  (send *mcup* :newcoords (send *mcup-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *mcup* :handle-handle1) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  
  (put-bowl-larm)
  )

(defun carry-mcup-pose ()
  (setq *lav-cm* #f(38.442 -20.2481 94.8038 -104.353 117.885 -64.3683 -258.356))
  (send *pr2* :larm :angle-vector *lav-cm*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 8000)
  (send *ri* :wait-interpolation)
  )

(defun transfer-mcup ()
  (set-mcup)
  
  ;; スライドさせて行く
  (send *pr2* :larm :move-end-pos #f(0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(100 0 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 移し始める座標
  (send *arrow* :newcoords (make-coords :pos (float-vector 510 8100 31080) :rpy (float-vector 3.14 0 0)))
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
	:move-target (car (send *mcup* :attention))
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  

  ;; 傾けていく
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 5)
    (send *arrow* :rotate (deg2rad 10) :y)
    (send *pr2* :larm :inverse-kinematics
          *arrow*
	  :move-target (car (send *mcup* :attention))
          :rotation-axis t
          :debug-view nil)
    
    (setq av (send *pr2* :angle-vector))
    
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  
  ;; 移し終わったかどうか等を判定する？
  
  (warn "please run (after-mcup) ~%")
  )

(defun after-mcup ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 510 8100 31080) :rpy (float-vector 3.14 0 0)))
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
	:move-target (car (send *mcup* :attention))
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 100 100) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (carry-mcup-pose)
  
  (warn "please run (put-mcup) ~%")
  )

(defun recieve-mcup ()
  (carry-mcup-pose)

  ;; mcupを受け取る
  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "軽量カップを握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :larm :wait t)
  
  (set-mcup)
  
  (warn "please run (put-mcup) ~%")
  )


;; oil-dispenser codes
(defun set-oil-dispenser ()
  (if (not (eql (send *oil-dispenser* :parent) nil))
      (send (send *oil-dispenser* :parent) :dissoc *oil-dispenser*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *oil-dispenser* :handle-handle0) :copy-worldcoords))
    (send local-cds :assoc *oil-dispenser*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *oil-dispenser*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *oil-dispenser*)
  )

(defun recieve-oil-dispenser ()
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
  (send *arrow* :newcoords (make-coords :pos (float-vector 600 8361 31167) :rpy (float-vector 3.14 0 0)))
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  ;; (send *pr2* :larm :angle-vector #f(30.046 -16.1647 77.4608 -67.7082 57.0472 -86.8259 -43.9204))
  (setq *tmp* (send *pr2* :larm :angle-vector))
  
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  
  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "軽量カップを握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :larm :wait t)

  (set-oil-dispenser)  
  )

(defun put-oil-dispenser ()
  ;; oil-dispenserを置く位置
  (if (not (eql (send *oil-dispenser* :parent) nil))
      (send (send *oil-dispenser* :parent) :dissoc *oil-dispenser*))
  (send *oil-dispenser* :newcoords (send *oil-dispenser-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *oil-dispenser* :handle-handle0) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  
  (put-bowl-larm)
  )

(defun grasp-oil-dispenser ()
  ;; oil-dispenserの位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *oil-dispenser* :handle-handle0) :copy-worldcoords))
  
  (grasp-bowl-larm)
  
  (set-oil-dispenser)
  )


;; bowl model codes
(defun set-bowl-1-model ()
  (if (not (eql (send *bowl-1* :parent) nil))
      (send (send *bowl-1* :parent) :dissoc *bowl-1*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *bowl-1* :handle-handle0) :copy-worldcoords))
    (send local-cds :assoc *bowl-1*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *bowl-1*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *bowl-1*)
  )

(defun put-bowl-1-model ()
  ;; ボウル１を置く位置
  (if (not (eql (send *bowl-1* :parent) nil))
      (send (send *bowl-1* :parent) :dissoc *bowl-1*))
  (send *bowl-1* :newcoords (send *bowl-1-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *bowl-1* :handle-handle0) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  
  (put-bowl-larm)
  )

(defun grasp-bowl-1-model ()
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *bowl-1* :handle-handle0) :copy-worldcoords))
  
  (grasp-bowl-larm)
  
  (set-bowl-1-model)
  
  (warn "please run (transfer-bowl-1-to-pot) ~%")  
  )

(defun set-bowl-2-model ()
  (if (not (eql (send *bowl-2* :parent) nil))
      (send (send *bowl-2* :parent) :dissoc *bowl-2*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *bowl-2* :handle-handle0) :copy-worldcoords))
    (send local-cds :assoc *bowl-2*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *bowl-2*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *bowl-2*)
  )

(defun set-bowl-2-model-rarm ()
  (if (not (eql (send *bowl-2* :parent) nil))
      (send (send *bowl-2* :parent) :dissoc *bowl-2*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *bowl-2* :handle-handle0) :copy-worldcoords))
    (send local-cds :assoc *bowl-2*)
    (send local-cds :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *bowl-2*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :rarm :end-coords) :assoc *bowl-2*)
  )

(defun put-bowl-2-model ()
  ;; ボウル２を置く位置
  (if (not (eql (send *bowl-2* :parent) nil))
      (send (send *bowl-2* :parent) :dissoc *bowl-2*))
  (send *bowl-2* :newcoords (send *bowl-2-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *bowl-2* :handle-handle0) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  
  (put-bowl-rarm)  
  )

(defun grasp-bowl-2-model () ;;右腕
  ;; ボウル２の位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *bowl-2* :handle-handle0) :copy-worldcoords))
  
  (grasp-bowl-rarm)
  
  (set-bowl-2-model-rarm)
  
  (warn "please run (move-bowl-2-set-model) ~%")  
  )

(defun move-bowl-2-set-model ()
  (send *pr2* :rarm :move-end-pos (float-vector 100 0 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  ;; ボウル２を置く位置 set
  (if (not (eql (send *bowl-2* :parent) nil))
      (send (send *bowl-2* :parent) :dissoc *bowl-2*))
  (send *bowl-2* :newcoords (send *bowl-2-set-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *bowl-2* :handle-handle0) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  
  (put-bowl-rarm)  
  )


(defun grasp-bowl-2-set-model () ;;左腕
  ;; ボウル２の位置 set
  (if (not (eql (send *bowl-2* :parent) nil))
      (send (send *bowl-2* :parent) :dissoc *bowl-2*))
  (send *bowl-2* :newcoords (send *bowl-2-set-coords* :copy-worldcoords))
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *bowl-2* :handle-handle0) :copy-worldcoords))
  
  (grasp-bowl-larm)

  (set-bowl-2-model)
  
  (warn "please run (transfer-bowl-2-to-pot) ~%")  
  )

(defun grasp-bowl-2-set-rarm-model () ;;右腕
  ;; ボウル２の位置 set
  (if (not (eql (send *bowl-2* :parent) nil))
      (send (send *bowl-2* :parent) :dissoc *bowl-2*))
  (send *bowl-2* :newcoords (send *bowl-2-set-coords* :copy-worldcoords))
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *bowl-2* :handle-handle0) :copy-worldcoords))
  
  (grasp-bowl-rarm)

  (set-bowl-2-model-rarm)
  
  (warn "please run (put-bowl-2-model) ~%")  
  )


(defun put-bowl-2-set-model ()
  ;; ボウル２の位置 set
  (if (not (eql (send *bowl-2* :parent) nil))
      (send (send *bowl-2* :parent) :dissoc *bowl-2*))
  (send *bowl-2* :newcoords (send *bowl-2-set-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *bowl-2* :handle-handle0) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  
  (put-bowl-larm)
  )

(defun set-bowl-3-model ()
  (if (not (eql (send *bowl-3* :parent) nil))
      (send (send *bowl-3* :parent) :dissoc *bowl-3*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *bowl-3* :handle-handle0) :copy-worldcoords))
    (send local-cds :assoc *bowl-3*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *bowl-3*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *bowl-3*)
  )

(defun put-bowl-3-model ()
  (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  (send *pr2* :larm :angle-vector *larm1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; ボウル３を置く位置
  (if (not (eql (send *bowl-3* :parent) nil))
      (send (send *bowl-3* :parent) :dissoc *bowl-3*))
  (send *bowl-3* :newcoords (send *bowl-3-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *bowl-3* :handle-handle0) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)

  (put-bowl-larm)  
  )

(defun grasp-bowl-3-model ()
  ;; ボウル３の位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *bowl-3* :handle-handle0) :copy-worldcoords))
  
  (grasp-bowl-larm)

  (set-bowl-3-model)
  
  (warn "please run (transfer-bowl-3-to-pot) ~%")  
  )

(defun set-bowl-4-model ()
  (if (not (eql (send *bowl-4* :parent) nil))
      (send (send *bowl-4* :parent) :dissoc *bowl-4*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *bowl-4* :handle-handle0) :copy-worldcoords))
    (send local-cds :assoc *bowl-4*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *bowl-4*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *bowl-4*)
  )

(defun put-bowl-4-model ()
  (setq *larm1* (float-vector 42.6232 6.188 43.7963 -57.5889 111.452 -100.941 -32.9738))
  (send *pr2* :larm :angle-vector *larm1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; ボウル４を置く位置
  (if (not (eql (send *bowl-4* :parent) nil))
      (send (send *bowl-4* :parent) :dissoc *bowl-4*))
  (send *bowl-4* :newcoords (send *bowl-4-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *bowl-4* :handle-handle0) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  
  (put-bowl-larm)  
  )

(defun grasp-bowl-4-model ()
  ;; ボウル４の位置
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *bowl-4* :handle-handle0) :copy-worldcoords))
  
  (grasp-bowl-larm)
  
  (set-bowl-4-model)
  
  (warn "please run (transfer-bowl-4-to-pot) ~%")  
  )


(defun transfer-to-pot-set ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 550.911 8325.179 31085.843) :rpy (float-vector 2.561 1.128 2.104))) ;; for eng2 model
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos (float-vector 0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos (float-vector 0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos (float-vector 0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  )

(defun transfer-to-pot-left-set ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 609.875 7802.164 31145.744) :rpy (float-vector 2.719 0.798 1.816))) ;; for eng2 model
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :larm :move-end-pos (float-vector -100 100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  )


(defun transfer-bowl-1-to-pot ()
  (set-bowl-1-model)
  
  (transfer-to-pot-set)
  
  ;; 注ぐ位置
  (send *arrow* :newcoords (send (send *pot* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(0 -50 120) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)
  
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:move-target (send *bowl-1* :attention-attention0)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (after-transfer) ~%")  
  )

(defun transfer-bowl-2-to-pot ()
  (set-bowl-2-model)
  
  (transfer-to-pot-set)
  
  ;; 注ぐ位置
  (send *arrow* :newcoords (send (send *pot* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(0 -50 120) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)
  
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:move-target (send *bowl-2* :attention-attention0)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (after-transfer) ~%")  
  )

(defun transfer-bowl-3-to-pot ()
  (set-bowl-3-model)
  
  (transfer-to-pot-left-set)
  
  ;; 注ぐ位置
  (send *arrow* :newcoords (send (send *pot* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(0 -50 120) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)
  
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:move-target (send *bowl-3* :attention-attention0)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (after-transfer-left) ~%")
  )

(defun transfer-bowl-4-to-pot ()
  (set-bowl-4-model)
  
  (transfer-to-pot-left-set)
  
  ;; 注ぐ位置
  (send *arrow* :newcoords (send (send *pot* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(0 -50 120) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)
  
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:move-target (send *bowl-4* :attention-attention0)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (after-transfer-left) ~%")
  )



;; now funcs
;; ボウル２をセット
(defun now-set-2 ()
  (recieve-bowl-2)
  (put-bowl-2)
  (reset-rarm)
  )

;; ボウル１をセット
(defun now-set-1 ()
  (recieve-bowl-1)
  (put-bowl-1)
  (reset-larm)
  )

(defun now-set-3 ()
  (recieve-bowl-3)
  (put-bowl-3)
  (reset-larm)
  )

(defun now-set-4 ()
  (recieve-bowl-4)
  (put-bowl-4)
  (reset-larm)
  )

;; ボウル１〜４をセット
(defun now-set-all ()
  (now-set-1)
  (now-set-2)
  (now-set-3)
  (now-set-4)
  )


;; ボウル２をまな板上に
(defun switch-bowl-2 ()
  (grasp-bowl-2)
  (move-bowl-2-set)
  (reset-rarm)
  )

(defun now-transfer ()
  (transfer-to-pot)

  ;; (grasp-spatula)
  (set-spatula) ;; ヘラは掴んでいる想定で行う
  (squeeze-test-set)
  (squeeze-test)
  (avoid-rarm)
  
  (after-transfer)
  )

(defun now-transfer-left ()
  (transfer-to-pot-left)

  ;; (grasp-spatula)
  (set-spatula) ;; ヘラは掴んでいる想定で行う
  (squeeze-test-set)
  (squeeze-test)
  (avoid-rarm)
  
  (after-transfer-left)
  )

(defun now-transfer-1 ()
  (grasp-bowl-1)
  (now-transfer)
  (put-bowl-1)
  (reset-larm)
  )

(defun now-transfer-2 ()
  (grasp-bowl-2-set)
  (now-transfer)
  (put-bowl-2-set)
  (reset-larm)
  )

(defun now-transfer-3 ()
  (grasp-bowl-3)
  (now-transfer-left)
  (put-bowl-3)
  (reset-larm)
  )

(defun now-transfer-4 ()
  (grasp-bowl-4)
  (now-transfer-left)
  (put-bowl-4)
  (reset-larm)
  )


(defun now-set-test ()
  (recieve-bowl-2)
  (put-bowl-2)
  (reset-rarm)

  (recieve-bowl-1)
  (put-bowl-1)
  (reset-larm)

  (recieve-bowl-3)
  (put-bowl-3)
  (reset-larm)

  (recieve-bowl-4)
  (put-bowl-4)
  (reset-larm)
  )

(defun transfer-all-test ()
  (switch-bowl-2)
  (now-transfer-2) ;; 玉ねぎ
  (now-transfer-4) ;; 肉
  (now-transfer-1) ;; 野菜
  (now-transfer-3) ;; カレールー
  )

(defun now-set-mcup ()
  (recieve-mcup)
  (put-mcup)
  )

(defun now-grasp-mcup ()
  (set-pose)
  (grasp-mcup)
  (carry-mcup-pose)
  
  (warn "please go to sink spot ~%")
  )

(defun now-pour-water ()
  (carry-mcup-pose)
  (transfer-mcup)
  (after-mcup)
  (put-mcup)
  (reset-larm)
  )


;; ボウル２をセット
(defun now-set-2-model ()
  (recieve-bowl-2)
  (put-bowl-2-model)
  (reset-rarm)
  )

;; ボウル１をセット
(defun now-set-1-model ()
  (recieve-bowl-1)
  (put-bowl-1-model)
  (reset-larm)
  )

(defun now-set-3-model ()
  (recieve-bowl-3)
  (put-bowl-3-model)
  (reset-larm)
  )

(defun now-set-4-model ()
  (recieve-bowl-4)
  (put-bowl-4-model)
  (reset-larm)
  )

;; ボウル１〜４をセット
(defun now-set-all-model ()
  (now-set-1-model)
  (now-set-2-model)
  (now-set-3-model)
  (now-set-4-model)
  )


;; ボウル２をまな板上に
(defun switch-bowl-2-model ()
  (grasp-bowl-2-model)
  (move-bowl-2-set-model)
  (reset-rarm)
  )

(defun now-transfer-left ()
  (transfer-to-pot-left)
  
  (set-spatula) ;; ヘラは掴んでいる想定で行う
  (squeeze-test-set)
  (squeeze-test)
  (avoid-rarm)
  
  (after-transfer-left)
  )

(defun now-transfer-1-model ()
  (grasp-bowl-1-model)
  
  (transfer-bowl-1-to-pot)
  (set-spatula) ;; ヘラは掴んでいる想定で行う
  (squeeze-test-set)
  (squeeze-test)
  (avoid-rarm)
  
  (after-transfer)
  (put-bowl-1-model)
  (reset-larm)
  )

(defun now-transfer-2-model ()
  (grasp-bowl-2-set-model)
  
  (transfer-bowl-2-to-pot)
  (set-spatula) ;; ヘラは掴んでいる想定で行う
  (squeeze-test-set)
  (squeeze-test)
  (avoid-rarm)
  
  (after-transfer)
  (put-bowl-2-set-model)
  (reset-larm)
  )

(defun now-transfer-3-model ()
  (grasp-bowl-3-model)

  (transfer-bowl-3-to-pot)
  (set-spatula) ;; ヘラは掴んでいる想定で行う
  (squeeze-test-set)
  (squeeze-test)
  (avoid-rarm)
  
  (after-transfer-left)
  (put-bowl-3-model)
  (reset-larm)
  )

(defun now-transfer-4-model ()
  (grasp-bowl-4-model)
  
  (transfer-bowl-4-to-pot)
  (set-spatula) ;; ヘラは掴んでいる想定で行う
  (squeeze-test-set)
  (squeeze-test)
  (avoid-rarm)
  
  (after-transfer-left)
  (put-bowl-4-model)
  (reset-larm)
  )
