(defun seasoning-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")
  
  ;; set objects
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/solt.l")
  (setq *solt* (solt))
  (send *solt* :newcoords (send *solt-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/dispenser.l")
  (setq *dispenser* (dispenser))
  (send *dispenser* :newcoords (send *dispenser-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/white-dish.l")
  (setq *white-dish* (white-dish))
  (send *white-dish* :newcoords (send *white-dish-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/red-cup.l")
  (setq *rcup* (red-cup))
  (send *rcup* :newcoords (send *rcup-seasoning-coords* :copy-worldcoords))

  (move-to-seasoning-irt)
  (objects (list *pr2* *scene* *solt* *dispenser* *white-dish* *rcup*))
  (update-view)
  )

(seasoning-init)

(warn "If you use real robot, run (update-pos) ~%")
(warn "please run (grasp-lever) ~%")


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
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 2340 9143 31227) :rpy (float-vector -0.71 0.472 0.601)))
  ;; (send *pr2* :larm :inverse-kinematics
  ;; 	(send *arrow* :copy-worldcoords)
  ;; 	:rotation-axis t
  ;; 	:debug-view *debug-flag*)
  (setq *lav1* #f(47.9671 -20.2483 82.2157 -82.6164 -293.759 -36.972 219.286))
  (send *pr2* :larm :angle-vector *lav1*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 2180 9400 31050) :rpy (float-vector 0.002 0.18 -0.086)))
  ;; (send *pr2* :larm :inverse-kinematics
  ;; 	(send *arrow* :copy-worldcoords)
  ;; 	:rotation-axis t
  ;; 	:debug-view t)
  (setq *lav2* #f(74.761 -20.2122 117.179 -115.102 -160.43 -37.4844 44.0878))
  (send *pr2* :larm :angle-vector *lav2*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  
  
  (setq *lav0* #f(75.0 50.0 110.0 -110.0 -20.0 -10.0 -10.0))
  (send *pr2* :larm :angle-vector *lav0*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  
  )

(defun veg-pose ()
  (send *pr2* :angle-vector #f(100.161 75.0006 49.9994 109.993 -109.995 -19.9972 -10.0007 -9.99948 -40.1721 59.1602 -68.2551 -119.512 165.852 -64.9736 -220.86 -0.005299 51.906))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


;; seasoning funcs
(defun set-solt ()
  (if (not (eql (send *solt* :parent) nil))
      (send (send *solt* :parent) :dissoc *solt*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *solt* :handle-handle0) :copy-worldcoords))
    (send local-cds :assoc *solt*)
    (send local-cds :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *solt*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :rarm :end-coords) :assoc *solt*)
  )

(defun set-dispenser ()
  (if (not (eql (send *dispenser* :parent) nil))
      (send (send *dispenser* :parent) :dissoc *dispenser*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *dispenser* :handle-handle0) :copy-worldcoords))
    (send local-cds :assoc *dispenser*)
    (send local-cds :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *dispenser*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :rarm :end-coords) :assoc *dispenser*)
  )

(defun set-rcup ()
  (if (not (eql (send *rcup* :parent) nil))
      (send (send *rcup* :parent) :dissoc *rcup*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *rcup* :handle-handle0) :copy-worldcoords))
    (send local-cds :assoc *rcup*)
    (send local-cds :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *rcup*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :rarm :end-coords) :assoc *rcup*)
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

(defun before-recieve-larm ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 250) :world)
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

(defun rarm-grasp-from-above ()
  (before-recieve-rarm)  
  
  ;; 掴む位置
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


(defun grasp-solt ()
  (send *ri* :stop-grasp :rarm :wait t)
  
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *solt* :handle-handle0) :copy-worldcoords))
  
  (rarm-grasp-from-above)

  (set-solt)
  )

(defun grasp-rcup ()
  (send *ri* :stop-grasp :rarm :wait t)
  
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *rcup* :handle-handle0) :copy-worldcoords))
  
  (rarm-grasp-from-above)

  (set-rcup)
  )

(defun grasp-dispenser ()
  (send *ri* :stop-grasp :rarm :wait t)
  
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *dispenser* :handle-handle0) :copy-worldcoords))
  
  (rarm-grasp-from-above)  

  (set-dispenser)
  )


(defun recieve-solt ()
  (before-recieve-rarm)  

  ;; 掴む位置
  (if (not (eql (send *solt* :parent) nil))
      (send (send *solt* :parent) :dissoc *solt*))
  (send *solt* :newcoords (send *solt-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *solt* :handle-handle0) :copy-worldcoords))

  (send *arrow* :translate #f(60 0 100) :world)

  (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :speak-jp "塩を握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t)

  (set-solt)
  )

(defun recieve-rcup ()
  (before-recieve-rarm)  

  ;; 掴む位置
  (if (not (eql (send *rcup* :parent) nil))
      (send (send *rcup* :parent) :dissoc *rcup*))
  (send *rcup* :newcoords (send *rcup-seasoning-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *rcup* :handle-handle0) :copy-worldcoords))

  (send *arrow* :translate #f(60 0 100) :world)
  
  (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :speak-jp "コップを握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t)

  (set-rcup)
  )

(defun recieve-dispenser ()
  (before-recieve-rarm)  

  ;; 掴む位置
  (if (not (eql (send *dispenser* :parent) nil))
      (send (send *dispenser* :parent) :dissoc *dispenser*))
  (send *dispenser* :newcoords (send *dispenser-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *dispenser* :handle-handle0) :copy-worldcoords))

  (send *arrow* :translate #f(60 0 100) :world)
  
  (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :speak-jp "コップを握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t)
  
  (set-dispenser)
  )

(defun put-object-rarm ()
  ;; arrowをhandle座標にしている前提．  
  (send *arrow* :translate #f(-80 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(80 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :move-gripper :rarm 0.08)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(-80 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 80) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


(defun put-solt ()
  ;; 掴む位置
  (if (not (eql (send *solt* :parent) nil))
      (send (send *solt* :parent) :dissoc *solt*))
  (send *solt* :newcoords (send *solt-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *solt* :handle-handle0) :copy-worldcoords))
  
  (put-object-rarm)
  )

(defun put-rcup ()
  ;; 掴む位置
  (if (not (eql (send *rcup* :parent) nil))
      (send (send *rcup* :parent) :dissoc *rcup*))
  (send *rcup* :newcoords (send *rcup-seasoning-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *rcup* :handle-handle0) :copy-worldcoords))
  
  (put-object-rarm)
  )

(defun put-dispenser ()
  ;;掴む位置
  (if (not (eql (send *dispenser* :parent) nil))
      (send (send *dispenser* :parent) :dissoc *dispenser*))
  (send *dispenser* :newcoords (send *dispenser-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *dispenser* :handle-handle0) :copy-worldcoords))
  
  (put-object-rarm)
  )

;; transfer codes
(defun transfer-cup-to-dish-set ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 2250 8900 31075) :rpy (float-vector 0 0 -1.571)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos #f(100 -100 100) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :rarm :move-end-pos #f(200 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; 移す動作をする位置の近くにする
  (send *arrow* :newcoords (send (send *white-dish* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(0 -50 120) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)

  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:move-target (send *rcup* :attention-attention0)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (warn "please run (transfer-cup-to-dish) ~%")
  )

(defun transfer-cup-to-dish ()
  (send *arrow* :newcoords (send (send *white-dish* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(0 -40 100) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)

  (dotimes (i 3)
    (send *arrow* :rotate (deg2rad -45) :x :world)
    (send *pr2* :rarm :inverse-kinematics
	  (send *arrow* :copy-worldcoords)
	  :move-target (send *rcup* :attention-attention0)
	  :rotation-axis t
	  :debug-view *debug-flag*)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)
    )
  
  (warn "please run (after-cup-to-dish) ~%")
  )

(defun after-cup-to-dish ()
  ;; 上にあげる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 150) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; 水平な姿勢にする
  (send *arrow* :newcoords (make-coords :pos (send (send (send *rcup* :attention-attention0) :copy-worldcoords) :worldpos)))
  (send *arrow* :rotate (deg2rad 90) :z :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:move-target (send *rcup* :attention-attention0)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos #f(-150 -100 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos #f(0 -200 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (put-rcup) ~%")
  )

(defun add-solt-set ()
  (send *pr2* :rarm :move-end-pos #f(0 100 0) :world)  
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  ;; 移す動作をする位置の近くにする
  (send *arrow* :newcoords (send (send *white-dish* :attention-attention0) :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :y) 
  (send *arrow* :translate #f(0 -50 100) :world)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:move-target (send *solt* :attention-attention0)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (add-solt) ~%")
  )

(defun add-solt ()
  (set-solt)
  
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  
  (send *arrow* :newcoords (send (send *white-dish* :attention-attention0) :copy-worldcoords))
  (send *arrow* :rotate (deg2rad -90) :y) 
  (send *arrow* :translate #f(0 -50 100) :world)
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:move-target (send *solt* :attention-attention0)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 3)
    (send *arrow* :rotate (deg2rad -45) :x :world)
    (send *pr2* :rarm :inverse-kinematics
	  (send *arrow* :copy-worldcoords)
	  :move-target (send *solt* :attention-attention0)
	  :rotation-axis t
	  :debug-view nil)
    (send *viewer* :draw-objects)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 200)))
    )
  
  (dotimes (i 3)
    (send *arrow* :rotate (deg2rad 45) :x :world)
    (send *pr2* :rarm :inverse-kinematics
  	  (send *arrow* :copy-worldcoords)
  	  :move-target (send *solt* :attention-attention0)
  	  :rotation-axis t
  	  :debug-view nil)
    (send *viewer* :draw-objects)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 200)))
    )

  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  
  (warn "please run (after-add-solt) ~%")
  )

(defun after-add-solt ()
  ;; 上にあげる
  (send *pr2* :rarm :move-end-pos #f(0 0 150) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :rarm :move-end-pos #f(0 -100 0) :world)  
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (put-solt) ~%")
  )


(defun add-mayo-set ()
  (send *pr2* :rarm :move-end-pos #f(0 100 0) :world)  
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos #f(0 100 0) :world)  
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  ;; 移す動作をする位置の近くにする
  (send *arrow* :newcoords (send (send *white-dish* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 20) :world)
  (send *arrow* :rotate (deg2rad 90) :z)
  (send *arrow* :rotate (deg2rad -90) :x :world)
  
  (send *pr2* :rarm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:move-target (send *dispenser* :attention-attention0)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; 左腕をセットしておく
  (before-recieve-larm)
  
  (send *arrow* :newcoords (send (send *dispenser* :handle-handle0) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 50) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)
  (send *arrow* :rotate (deg2rad 180) :x)

  (send *arrow* :rotate (deg2rad 45) :z :world)
  
  (send *ri* :stop-grasp :larm :wait t)  
  
  (send *arrow* :translate #f(-50 50 80) :world)
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :larm :wait t)
  
  (send *arrow* :translate #f(50 -50 -80) :world)
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  
  (warn "please run (add-mayo) ~%")
  )

(defun add-mayo ()
  (send *ri* :move-gripper :rarm 0.04)
  (unix:sleep 3)
  (send *ri* :stop-grasp :rarm :wait t)
  
  (warn "please run (after-mayo) ~%")
  )

(defun after-mayo ()
  (if (not (eql (send *dispenser* :parent) nil))
      (send (send *dispenser* :parent) :dissoc *dispenser*))
  (send *pr2* :larm :end-coords :assoc *dispenser*)
  
  ;; 上にして持ち替える
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(-100 0 0) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 180) :x)
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (send (send (send *dispenser* :handle-handle0) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate #f(-100 0 0) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(100 0 0) :world)
  (send *pr2* :rarm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :start-grasp :rarm :wait t)

  (if (not (eql (send *dispenser* :parent) nil))
      (send (send *dispenser* :parent) :dissoc *dispenser*))
  (send *pr2* :rarm :end-coords :assoc *dispenser*)
  
  ;; 左腕を戻して右腕をputの前位置にする．
  (send *ri* :stop-grasp :larm :wait t)
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(-80 80 0) :world)
  (send *pr2* :larm :inverse-kinematics
  	(send *arrow* :copy-worldcoords)
  	:rotation-axis t
  	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (reset-larm)
  
  (send *pr2* :rarm :move-end-pos #f(0 0 100) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos #f(0 -100 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (put-dispenser) ~%")
  )


;; now funcs
(defun now-devel ()
  (veg-pose)
  (set-rcup)
  (now-transfer-vegs)
  )

(defun now-transfer-vegs ()
  (transfer-cup-to-dish-set)
  (transfer-cup-to-dish)
  (after-cup-to-dish)
  (put-rcup)
  )

(defun now-add-solt ()
  (grasp-solt)
  (add-solt-set)
  (add-solt)
  (after-add-solt)
  (put-solt)
  )

(defun now-add-mayo ()
  (grasp-dispenser)
  (add-mayo-set)
  (add-mayo)
  (after-mayo)
  (put-dispenser)
  )

(defun now-set-solt ()
  (recieve-solt)
  (put-solt)
  )

(defun now-set-mayo ()
  (recieve-dispenser)
  (put-dispenser)
  )

(defun now-set-seasoning ()
  (now-set-solt)
  (now-set-mayo)
  )

(defun tmp-test ()
  (set-pose)
  (now-add-mayo)
  )
