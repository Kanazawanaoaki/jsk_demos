(defun water-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-codes.l")
  
  ;; set objects
  (setq *veg* (make-cube 100 50 40))
  (send *veg* :set-color :green)
  
  ;; set global num
  (setq *s-time* 3)
  
  (move-to-sink-irt)
  
  (objects (list *veg* *pr2* *scene* *mcup*))
  (update-view)
  )

(water-init)

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
  (send *pr2* :larm :angle-vector #f(30.046 -16.1647 77.4608 -67.7082 57.0472 -86.8259 -43.9204))
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation) 
  )

;; water funcs
(defun grasp-lever ()
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
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :rarm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate (float-vector -200 50 40) :world)
  (send *arrow* :rotate (deg2rad -90) :z :world)
  (send *arrow* :rotate (deg2rad 90) :x)
  (send *arrow* :rotate (deg2rad 60) :x :world)

  (setq *tmp* (send *arrow* :copy-worldcoords))
  
  (send *pr2* :rarm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;;グリッパを微妙に開く
  (send *ri* :move-gripper :rarm 0.05)

  ;; 水道のレバーの位置
  (send *arrow* :newcoords (send *fauset-lever-rarm-coords* :copy-worldcoords))
  
  (send *arrow* :translate #f(100 60 20) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(-100 -60 -20) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :rarm :wait t)
  
  (warn "please run (water-on) ~%") 
  )

(defun water-on ()
  ;; こことかも実はモデルをつくって開ける閉める動作にした方が良いのかな？という感じはする．
  ;; レバーを掴んでいる状態から
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 30) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis nil
    :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (water-off) ~%") 
  )


(defun water-off ()
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 -40) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (release-lever) ~%")
  )


(defun release-lever ()
  ;;グリッパを微妙に開く
  (send *ri* :move-gripper :rarm 0.05)
  
  (send *arrow* :newcoords (send *fauset-lever-rarm-coords* :copy-worldcoords))
  (send *arrow* :translate #f(100 60 20) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (reset-rarm)
  )


;; measuring cup funcs
(defun mcup-water-set ()
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (carry-mcup-pose)

  ;; スライドさせて行く
  (send *pr2* :larm :move-end-pos #f(0 100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 0 -100) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 蛇口の位置
  (send *arrow* :newcoords (send *fauset-coords* :copy-worldcoords))
  (send *arrow* :translate #f(0 -100 0) :world)
  (send *arrow* :translate #f(100 0 100) :world)

  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
    :move-target (elt (send *mcup* :attention) 1)
      :rotation-axis t
      :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 8000)
  (send *ri* :wait-interpolation)  

  (send *arrow* :translate #f(-100 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
    :move-target (elt (send *mcup* :attention) 1)
      :rotation-axis t
      :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  
  
  (send *arrow* :translate #f(0 100 0) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
    :move-target (elt (send *mcup* :attention) 1)
      :rotation-axis t
      :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  

  (warn "please run (grasp-lever) ~%")
  )

(defun after-mcup-water ()
  ;; 蛇口の位置
  (send *arrow* :newcoords (send *fauset-coords* :copy-worldcoords))
  (send *arrow* :translate #f(0 -100 0) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
    :move-target (elt (send *mcup* :attention) 1)
      :rotation-axis t
      :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  
  
  (send *arrow* :translate #f(100 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
    :move-target (elt (send *mcup* :attention) 1)
      :rotation-axis t
      :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  

  (send *pr2* :larm :move-end-pos #f(0 0 100) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 -100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (carry-mcup-pose)

  (warn "please return to kitchen spot! ~%")
  )


;; wash vegitable funcs
(defun set-veg ()
  (if (not (eql (send *veg* :parent) nil))
      (send (send *veg* :parent) :dissoc *veg*))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send (send *veg* :copy-worldcoords) :rotate (deg2rad 30) :y))
    (send local-cds :assoc *veg*)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc *veg*)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc *veg*)
  )

(defun recieve-veg ()
  (before-recieve-larm)
  
  (send *veg* :newcoords (make-coords :pos (float-vector 450 9160 30870)))  
  (send *veg* :rotate (deg2rad 90) :z)
  (send *viewer* :draw-objects)  
  (send *arrow* :newcoords (send *veg* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 30) :y)
  
  (send *arrow* :translate #f(0 -100 80) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  
  
  (send *arrow* :translate #f(0 100 -80) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :rotation-axis t
      :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  
  
  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :speak-jp "野菜を握らせて下さい")
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :larm :wait t)
  (send *pr2* :larm :end-coords :assoc *veg*)

  (warn "please run (wash-veg-set) ~%")
  )

(defun veg-set ()
  ;; arrowが目標にセットされている想定
  (send *arrow* :translate #f(80 0 -40) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
    :move-target *veg*
      :rotation-axis t
      :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  
  
  (send *arrow* :translate #f(-80 0 40) :world)
  (send *pr2* :larm :inverse-kinematics
      (send *arrow* :copy-worldcoords)
      :move-target *veg*
      :rotation-axis :z
      :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun after-wash-veg-set ()
  (send *arrow* :newcoords (send *veg* :copy-worldcoords))
  (send *arrow* :translate #f(80 0 -40) :world)
  (send *pr2* :larm :inverse-kinematics
	(send *arrow* :copy-worldcoords)
	:move-target *veg*
	:rotation-axis t
	:debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  
  )

(defun wash-veg-set ()
  ;; 洗う位置
  (send *arrow* :newcoords (send *fauset-coords* :copy-worldcoords))
  (send *arrow* :translate #f(0 0 20) :world)
  (send *arrow* :rotate (deg2rad -90) :z)  
  
  (veg-set)
  
  (warn "please water on ~%")
  )

(defun rotate-veg-wash-1 ()
  (after-wash-veg-set)
  
  ;; 次に洗う位置
  (send *arrow* :newcoords (send *fauset-coords* :copy-worldcoords))
  (send *arrow* :translate #f(0 0 20) :world)
  (send *arrow* :rotate (deg2rad -90) :z)  
  (send *arrow* :rotate (deg2rad 90) :x)
  
  (veg-set)
  
  ;; (warn "please run (rotate-veg-wash-2) ~%")
  (warn "please run (after-wash) ~%")
  )

(defun rotate-veg-wash-2 () ;; 現状IKが解けない
  (after-wash-veg-set)
  
  ;; 次に洗う位置
  (send *arrow* :newcoords (send *fauset-coords* :copy-worldcoords))
  (send *arrow* :translate #f(0 0 20) :world)
  (send *arrow* :rotate (deg2rad -90) :z)  
  (send *arrow* :rotate (deg2rad -90) :x)
  
  (veg-set)
  
  (warn "please run (after-wash) ~%")
  )


(defun after-wash ()
  
  
  
  (warn "please return to kitchen spot! ~%")
  )


;; now funcs
(defun now-devel ()
  (set-mcup)
  (carry-mcup-pose)
  (mcup-water-set)
  
  (grasp-lever)
  (water-on)
  
  ;; 本当はここで認識をする
  (water-off)
  (release-lever)
  
  (after-mcup-water)
  )

(defun now-on-water ()
  (grasp-lever)
  (water-on)
  )

(defun now-off-water ()
  (water-off)
  (release-lever)
  )


(defun now-wash-veg ()
  (wash-veg-set)
  
  
  )


(defun tmp-water-test ()
  (set-pose)
  
  (grasp-lever)
  (water-on)
  
  (unix:sleep 3)
  
  (water-off)
  (release-lever)
  )

(defun tmp-wash-veg ()
  (recieve-veg)
  (wash-veg-set)
  )

(defun tmp-test ()
  (unix:sleep 1)
  (wash-veg-set)
  
  (grasp-lever)
  (water-on)
  
  (unix:sleep 3)
  
  (water-off)
  (release-lever)
  )
