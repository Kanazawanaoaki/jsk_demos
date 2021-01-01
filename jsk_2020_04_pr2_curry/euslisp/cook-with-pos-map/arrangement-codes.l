(defun arrangement-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/ih-use-codes.l")
  
  ;; set objects
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/curry-dish.l")
  (setq *curry-dish* (curry-dish))
  (send *curry-dish* :newcoords (send *curry-dish-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/sato-rice.l")
  (setq *sato-rice* (sato-rice))
  (send *sato-rice* :newcoords (send *sato-rice-coords* :copy-worldcoords))
  
  (send *spatula* :newcoords (send *spatula-coords-a* :copy-worldcoords))
  (send *ladle* :newcoords (send *ladle-coords-a* :copy-worldcoords))
  
  ;; def global coords
  (move-to-arrange-irt)
  (objects (list *pr2* *scene* *spatula* *ladle* *pot* *curry-dish* *sato-rice*))
  (update-view)
  )

(arrangement-init)


;; util funcs
(defun reset-rarm ()
  )

(defun reset-larm ()
  )


(defun look-at-dish ()
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :head :look-at (send (send *curry-dish* :copy-worldcoords) :worldpos))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  )

(defun put-obj-larm ()
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

;; curry codes
(defun scoop-up-curry-1 ()
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 391.83 8092.564 30820) :rpy (float-vector -1.135 0.805 -1.056)))
  (send *arrow* :newcoords (make-coords :pos (float-vector 426 8039 30834) :rpy (float-vector -0.74 0.613 -1.132)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate #f(0 0 -30) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  )

(defun scoop-up-curry-2 ()
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 420 8065 30870) :rpy (float-vector -1.525 0.066 -0.424)))
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 473.293 8060.197 30859.318) :rpy (float-vector -0.608 0.452 -0.756)))
  ;; (send *arrow* :translate #f(0 0 -20) :world)
  (send *arrow* :translate #f(40 60 0) :world)  
  (send *pr2* :rarm :inverse-kinematics  
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun scoop-up-curry-3 ()
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 446.773 8053.785 30870) :rpy (float-vector -1.525 0.066 -0.424)))
  (send *arrow* :newcoords (make-coords :pos (float-vector 479 8064 30870) :rpy (float-vector -1.296 0.242 -0.152)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun scoop-up-curry ()
  (scoop-up-curry-1)
  (scoop-up-curry-2)
  (scoop-up-curry-3)
  
  (send *pr2* :rarm :move-end-pos #f(0 0 50) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (carry-curry-set) ~%")
  )

(defun carry-curry-set ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 489.77 8042.025 31004.991) :rpy (float-vector -1.621 0.06 0.033)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (warn "please run (carry-curry) ~%")
  )


(defun carry-curry ()
  (dotimes (i 2)
    (send *pr2* :rarm :move-end-pos #f(0 100 0) :world)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)
    )  
  (warn "please run (transfer-curry-set) ~%")
  )

(defun transfer-curry-set ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 504.422 8343.425 30917.724) :rpy (float-vector -1.367 0.118 -0.067)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (transfer-curry) ~%")
  )

(defun transfer-curry ()
  (send *arrow* :newcoords (send (elt (send *ladle* :attention) 1) :copy-worldcoords))
  
  (dotimes (i 9)
    (send *arrow* :rotate (deg2rad 10) :y :world)
    (send *pr2* :rarm :inverse-kinematics
          (send *arrow* :copy-worldcoords)
          :move-target (elt (send *ladle* :attention) 1)
          :rotation-axis t
          :debug-view *debug-flag*)
    (send *viewer* :draw-objects)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)
    )
  (warn "please run (after-transfer-curry) ~%")
  )

(defun after-transfer-curry ()
  (send *pr2* :rarm :move-end-pos #f(0 0 100) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 3)
    (send *pr2* :rarm :move-end-pos #f(0 0 -40) :world)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    
    (send *pr2* :rarm :move-end-pos #f(0 0 40) :world)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  
  ;; avoid-pose的な姿勢になる．
  (send *arrow* :newcoords (make-coords :pos (float-vector 628.029 8528.539 31050.217) :rpy (float-vector -3.14 0.18 3.056)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  )

;; サトウのごはん
(defun set-sato-rice ()
  (if (not (eql (send *sato-rice* :parent) nil))
      (send (send *sato-rice* :parent) :dissoc *sato-rice*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *sato-rice* :handle-handle0) :copy-worldcoords))
    (send local-cds :assoc *sato-rice*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *sato-rice*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *sato-rice*)
  )


(defun recieve-sato-rice ()
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
  ;; (send *pr2* :larm :angle-vector #f(30.046 -16.1647 77.4608 -67.7082 57.0472 -86.8259 -43.9204))
  (send *arrow* :newcoords (make-coords :pos (float-vector 600.0 8061.0 31167.0) :rpy (float-vector 1.571 1.047 1.571)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 557 8260 31125) :rpy (float-vector 2.356 0.785 1.571)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  ;; ご飯を受け取る
  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "サトウのごはんを握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :larm :wait t)
  
  (set-sato-rice)
  )

(defun transfer-sato-set ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 557 8260 31125) :rpy (float-vector 2.356 0.785 1.571)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  ;; 移す位置
  (send *arrow* :newcoords (send (send *curry-dish* :attention-attention0) :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 90) :z)
  (send *arrow* :translate #f(0 -50 80) :world)
  
  (send *arrow* :rotate (deg2rad 30) :y)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (send *sato-rice* :attention-attention0)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :rotate (deg2rad 20) :y)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (send *sato-rice* :attention-attention0)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *arrow* :rotate (deg2rad 20) :y)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (send *sato-rice* :attention-attention0)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  )

(defun squeeze-sato-set ()
  (send *ri* :start-grasp :rarm :gain 30 :wait t)
  
  ;; (setq *rav0* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  ;; (send *pr2* :rarm :angle-vector *rav0*)
  (send *arrow* :newcoords (make-coords :pos (float-vector 628.029 8528.539 31050.217) :rpy (float-vector -3.14 0.18 -0.086)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
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
  
  ;; 書き出す最初の位置に
  (send *arrow* :newcoords (send (send *sato-rice* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(-110 0 0))
  (send *arrow* :newcoords (make-coords :pos (send (send *arrow* :copy-worldcoords) :worldpos)))
  (send *arrow* :rotate (deg2rad -90) :z)
  
  (send *arrow* :translate #f(-100 0 0))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (car (send *spatula* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  )

(defun squeeze-sato ()
  ;; 書き出す最初の位置に
  (send *arrow* :newcoords (send (send *sato-rice* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(-110 0 0))
  (send *arrow* :newcoords (make-coords :pos (send (send *arrow* :copy-worldcoords) :worldpos)))
  (send *arrow* :rotate (deg2rad -90) :z)
  
  (send *arrow* :translate #f(-100 0 0))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (car (send *spatula* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 15)
    (send *arrow* :translate (float-vector 10 0 0))
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
  
  (send *arrow* :newcoords (send (send *sato-rice* :attention-attention0) :copy-worldcoords))
  (send *arrow* :translate #f(-110 0 0))
  (send *arrow* :newcoords (make-coords :pos (send (send *arrow* :copy-worldcoords) :worldpos)))
  (send *arrow* :rotate (deg2rad -90) :z)
  (send *arrow* :translate #f(-100 0 0))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (car (send *spatula* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


(defun avoid-spatula-sato ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 550 8400 31150) :rpy (float-vector -1.603 0.03 -0.018)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (car (send *spatula* :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 600 8550 31145) :rpy (float-vector -3.048 -0.062 -1.634)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 628.029 8528.539 31050.217) :rpy (float-vector -3.14 0.18 -0.086)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun after-sato ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 557 8260 31125) :rpy (float-vector 2.356 0.785 1.571)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  ;; サトウのごはんを置く位置
  (if (not (eql (send *sato-rice* :parent) nil))
      (send (send *sato-rice* :parent) :dissoc *sato-rice*))
  (send *sato-rice* :newcoords (send *sato-rice-coords* :copy-worldcoords))
  (send *arrow* :newcoords (send (send *sato-rice* :handle-handle0) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  (put-obj-larm)
  )



(defun now-devel ()
  (set-pose)
  (recieve-sato-rice)
  (transfer-sato-set)
  (set-spatula)
  (squeeze-sato-set)
  (squeeze-sato)
  (avoid-spatula-sato)
  (after-sato)
  )


(defun tmp-set ()
  (update-pos)
  (set-ladle)
  )

(defun now-test ()
  (set-pose)
  (set-ladle)
  (grasp-pot-from-below)
  (look-at-pot)
  (mix-with-ladle-set)
  
  ;; (scoop-up-curry)
  
  ;; (mix-with-ladle)
  ;; (wait-pose-ladle)
  ;; (avoid-rarm-ladle)
  ;; (release-pot-from-below)
  )

(defun now-arrange-curry ()
  (set-ladle)
  (look-at-pot)
  (scoop-up-curry)
  (carry-curry-set)
  (carry-curry)
  
  (look-at-dish)
  
  (transfer-curry-set)
  (transfer-curry)
  (after-transfer-curry)
  )

(defun now-arrange-sato ()
  (recieve-sato-rice)
  (transfer-sato-set)
  (set-spatula)
  (squeeze-sato-set)
  (squeeze-sato)
  (avoid-spatula-sato)
  (after-sato)  
  )

(defun 

;; TODO 用意する　-with-dialogueも作りたい．
(defun now-set-sato ()
  ;; 右腕でサトウのごはんを受け取ってセットする
  (resieve-sato-rice-rarm)
  (put-sato-rice-rarm)
  (reset-rarm)
  )

(defun now-set-tools-a ()
  ;; ヘラとおたまを受け取ってセットする
  ()
  )



(defun set-tmp-pose ()
  (send *pr2* :rarm :angle-vector #f(-38.3949 -2.90787 -80.2822 -11.5856 -8.70289 -113.777 -356.552))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


(defun tmp-test ()
  (set-sato-rice)
  (transfer-sato-set)
  (set-spatula)
  (squeeze-sato)
  (set-tmp-pose)
  (after-sato)
  )
