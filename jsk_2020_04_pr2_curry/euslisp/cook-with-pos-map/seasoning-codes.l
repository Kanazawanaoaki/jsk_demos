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
  )

(defun grasp-rcup ()
  (send *ri* :stop-grasp :rarm :wait t)
  
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *rcup* :handle-handle0) :copy-worldcoords))
  
  (rarm-grasp-from-above)
  )

(defun grasp-dispenser ()
  (send *ri* :stop-grasp :rarm :wait t)
  
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *dispenser* :handle-handle0) :copy-worldcoords))
  
  (rarm-grasp-from-above)  
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
  (send *arrow* :translate #f(60 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(-60 0 -100) :world)
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
  (send *arrow* :translate #f(60 0 100) :world)
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
(defun transfer-cup-to-dish ()

  )

(defun add-solt ()

  )

(defun add-mayo ()

  )
