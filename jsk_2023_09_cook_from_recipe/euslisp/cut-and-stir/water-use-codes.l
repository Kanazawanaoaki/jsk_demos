#!/usr/bin/env roseus

(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/bowl-use-kitchen-codes.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/73b2-kitchen-coords.l")

;; set global variable
(setq *debug-flag* t)
(setq *s-time* 3)

(setq *cb-flag* nil)

;; set objects
(unless (boundp '*veg*)
  (progn
    (setq *veg* (make-cube 100 50 40))
    (send *veg* :set-color :green)
    ))

;; offset cds for tmp
(unless (boundp '*sink-offset-cds*)
  (progn
    (setq *sink-offset-cds* (make-coords))
    ))

(defun water-init (&key (use-cds-offset t))
  ;; init
  ;; (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/bowl-use-kitchen-codes.l")
  ;; (setq *sink-spot* (make-coords :pos (float-vector 1110 9100 30000) :rpy (float-vector pi 0 0))) ;; sink

  ;; set objects

  ;; set global coords
  (setq *faucet-orig-coords* (make-coords :pos #f(776.855 -17.7464 1000.0) :rpy #f(-0.008 0.0 0.0))) ;; for without rec
  (if use-cds-offset
      (setq *faucet-coords* (set-offset-cds *faucet-orig-coords* *sink-offset-cds*))
    (setq *faucet-coords* (send *faucet-orig-coords* :copy-worldcoords))
    )

  (setq *sink-sink-end-1* (make-coords :pos #f(575.0 145.0 1000.0) :rpy #f(0.017 0.0 0.0))) ;; for check
  (setq *sink-sink-end-2* (make-coords :pos #f(505.0 55.0 1000.0) :rpy #f(0.017 0.0 0.0))) ;; for check

  ;; (move-to-sink-irt)
  ;; (objects (list *veg* *pr2* *scene* *mcup* *rcup*))
  ;; (update-view)

  (objects (list *veg* *pr2* *mcup* *rcup*))
  )

(water-init)

(warn "If you use real robot, run (update-pos) ~%")
(warn "please run (grasp-lever) ~%")


;; TODO seiri


;; check mizukumi rec
(ros::roseus "bowl_transfer_test" :anonymous t)
(ros::load-ros-manifest "geometry_msgs")

(setq *mizukumi-flag* nil)
;; (setq *mizukumi-thre* -2) ;; mcup
(setq *mizukumi-thre* 1) ;; rcup

(defun check-mizukumi ()
  (let (msg force z)
    ;; virtual force の値を取得する
    (setq msg (one-shot-subscribe "/left_endeffector/wrench" geometry_msgs::WrenchStamped))
    (setq force (send msg :wrench :force))

    (setq *vec* (float-vector (send force :x) (send force :y) (send force :Z)))

    ;; 変換する
    (send *pr2* :angle-vector (send *ri* :state :potentiove-vector))
    (setq *t-vec* (send (send *pr2* :larm :end-coords) :rotate-vector *vec*)) ;;これで変換できる
    (setq z (elt *t-vec* 2))
    (format t "z force is ~A ~%" z)

    ;; 判定する
    (if (< z *mizukumi-thre*)
        (progn
          (setq *mizukumi-flag* t)
          (warn "mizukumi seikou ~%")
	  (send *ri* :speak-jp "水をくめています")
          )
      (send *ri* :speak-jp "水をくめていません")
      )
    )
  )

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

;; Add from
(defun sink-lever-rec ()
  (let ((rec-coords)
        (rec-to-target-offset)
        (grasp-cds))
    ;; (setq rec-to-target-offset (make-coords :pos #f(330.658 123.566 236.368) :rpy #f(-1.215 0.72 0.426))) ;; v1 ik fail
    (setq rec-to-grasp-offset (make-coords :pos #f(336.154 125.843 243.1) :rpy #f(-1.204 0.722 0.445)))
    (setq rec-to-faucet-offset (make-coords :pos #f(342.957 118.145 345.331) :rpy #f(0.018 1.503 -3.13)))

    ;; rec sink landmark
    (reset-cook-pose :head-p 30 :arm :rarm)
    (unix::sleep 1)
    (setq rec-coords (k4a-check-detection "/point_pose_sink/ObjectDetection"))
    ;; (setq hoge (send rec-coords :copy-worldcoords))
    (format t "point_pose_sink result: ~A ~%" rec-coords)

    (setq grasp-cds (calc-coords-from-rel rec-coords rec-to-grasp-offset))
    (setq faucet-cds (calc-coords-from-rel rec-coords rec-to-faucet-offset))
    (publish-cds-tf-list (list grasp-cds faucet-cds))
    (setq *faucet-rec-coords* (send faucet-cds :copy-worldcoords))

    grasp-cds))

(defun sink-lever-test (&key (use-cds-offset nil) (with-rec t))
  (let (
        ;; (wait-rav-1 #f(-41.4059 32.4107 -50.5582 -112.849 -176.587 -63.8396 38.962)) ;; 手前の姿勢
        ;; (wait-rav-2 #f(-24.8704 3.91558 -78.0752 -40.0538 -31.1184 -40.1947 20.8712)) ;; 奥の姿勢
        (wait-rav-1 #f(-15.8895 46.2354 -3.87426 -115.597 190.444 -68.0734 -1.41295)) ;; 手前の姿勢 for upper
        (wait-rav-2 #f(-8.79278 18.6346 3.39867 -41.8748 246.993 -69.8632 31.6097)) ;; 奥の姿勢
        (rec-lever-cds)
        )

    (when with-rec
      (setq rec-lever-cds (sink-lever-rec))
      (reset-cook-pose :head-p 50 :arm :rarm)
      )

    (send *pr2* :rarm :angle-vector wait-rav-1)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
    (send *ri* :wait-interpolation)

    (send *pr2* :rarm :angle-vector wait-rav-2)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
    (send *ri* :wait-interpolation)

    (send *ri* :move-gripper :rarm 0.03 :effort (* 2000 0.03) :wait t)

    ;; set
    ;; off
    (if with-rec
        (setq target-coords (send rec-lever-cds :copy-worldcoords))
      (progn
        (setq now-coords (make-coords :pos #f(877.466 -25.883 1012.658) :rpy #f(0.794 0.215 -1.428)))
        (if use-cds-offset
            (setq target-coords (set-offset-cds now-coords *sink-offset-cds*))
          (setq target-coords (send now-coords :copy-worldcoords)))
        ))
    (send *pr2* :rarm :inverse-kinematics
          (send target-coords :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)

    (send *ri* :start-grasp :rarm :wait t)

    ;; on
    (if with-rec
        (progn
          (setq off-on-rel (make-coords :pos #f(0.634896 -34.6435 -12.8812) :rpy #f(0.207 0.246 0.267)))
          (setq target-coords (calc-coords-from-rel target-coords off-on-rel))
          )
      (progn
        ;; (setq now-coords (make-coords :pos #f(893.597 -17.28 1043.267) :rpy #f(0.539 0.466 -1.373)))
        (setq now-coords (make-coords :pos #f(895.364 -32.896 1044.233) :rpy #f(0.556 0.444 -1.265)))
        (if use-cds-offset
            (setq target-coords (set-offset-cds now-coords *sink-offset-cds*))
          (setq target-coords (send  now-coords :copy-worldcoords)))
        ))
    (send *pr2* :rarm :inverse-kinematics
          (send target-coords :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)

    (unix:sleep 1) ;; TODO なにか処理

    ;; off
    (if with-rec
        (setq target-coords (send rec-lever-cds :copy-worldcoords))
      (progn
        (setq now-coords (make-coords :pos #f(877.466 -25.883 1012.658) :rpy #f(0.794 0.215 -1.428)))
        (if use-cds-offset
            (setq target-coords (set-offset-cds now-coords *sink-offset-cds*))
          (setq target-coords (send  now-coords :copy-worldcoords)))
        ))
    (send *pr2* :rarm :inverse-kinematics
          (send target-coords :copy-worldcoords)
          :rotation-axis t
          :debug-view nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)

    (send *ri* :move-gripper :rarm 0.03 :effort (* 2000 0.03) :wait t)

    (send *pr2* :rarm :angle-vector wait-rav-2)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
    (send *ri* :wait-interpolation)

    (send *pr2* :rarm :angle-vector wait-rav-1)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
    (send *ri* :wait-interpolation)
    ))



(defun grasp-lever (&rest args &key (adjust 0) &allow-other-keys)
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

  (setq *tmp* (send *arrow* :copy-worldcoords)) ;; TODO 座標ベースにしたい

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
  (send *arrow* :translate (float-vector 0 adjust 0) :world)

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

(defun before-lever ()
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
  )

(defun grasp-lever-tmp (&rest args &key (adjust 0) &allow-other-keys)
  ;;グリッパを微妙に開く
  (send *ri* :move-gripper :rarm 0.05)

  ;; 水道のレバーの位置
  (send *arrow* :newcoords (send *fauset-lever-rarm-coords* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 adjust 0) :world)
  
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
  ;; (send *arrow* :translate (float-vector 0 0 20) :world)
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
  (send *arrow* :newcoords (send *fauset-lever-rarm-coords* :copy-worldcoords))

  (send *arrow* :translate #f(20 0 -50) :world)

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
  (send *ri* :move-gripper :rarm 0.04)

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

(defun release-lever-tmp ()
  ;;グリッパを微妙に開く
  (send *ri* :move-gripper :rarm 0.04)

  (send *arrow* :newcoords (send *fauset-lever-rarm-coords* :copy-worldcoords))
  (send *arrow* :translate #f(100 60 20) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )


;; measuring cup funcs
(defun mcup-water-set ()
  (carry-mcup-pose)
  
  ;; スライドさせて行く
  (send *pr2* :larm :move-end-pos #f(0 100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 0 -100) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
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
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  

  (send *arrow* :translate #f(-100 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *mcup* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)  
  
  (send *arrow* :translate #f(0 100 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *mcup* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (grasp-lever) ~%")
  )

(defun slide-mcup ()
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
  )

(defun after-mcup-water ()
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

;; add for rcup
(defun rcup-water-set ()
  (carry-rcup-pose)
  
  ;; スライドさせて行く
  (send *pr2* :larm :move-end-pos #f(0 100 0) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :larm :move-end-pos #f(0 0 -100) :world)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; 蛇口の位置
  (send *arrow* :newcoords (send *fauset-coords* :copy-worldcoords))
  (send *arrow* :translate #f(0 -100 0) :world)
  (send *arrow* :translate #f(100 0 100) :world)
  
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *rcup* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  

  (send *arrow* :translate #f(-100 0 -100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *rcup* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)  
  
  (send *arrow* :translate #f(0 100 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *rcup* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (grasp-lever) ~%")
  )

(defun slide-rcup ()
  ;; 蛇口の位置
  (send *arrow* :newcoords (send *fauset-coords* :copy-worldcoords))
  (send *arrow* :translate #f(0 -100 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *rcup* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)  
  )

(defun rcup-nigasu ()
  (send *arrow* :newcoords (send (elt (send *rcup* :attention) 1) :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 10) :y)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *rcup* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (unix:sleep 1)

  (send *arrow* :rotate (deg2rad -10) :y)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *rcup* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  )

(defun after-rcup-water ()
  ;; 蛇口の位置
  (send *arrow* :newcoords (send *fauset-coords* :copy-worldcoords))
  (send *arrow* :translate #f(0 -100 0) :world)
  (send *arrow* :translate #f(100 0 100) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :move-target (elt (send *rcup* :attention) 1)
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
  
  (carry-rcup-pose)

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
  (set-veg)
  
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
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 3)
    (send *pr2* :larm :move-end-pos #f(0 0 30) :world)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    
    (send *pr2* :larm :move-end-pos #f(0 0 -30) :world)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  
  (warn "please return to kitchen spot! ~%")
  )



(defun vegs-carry-pose ()
  (setq *lav-vc* #f(35.2692 -2.67452 58.1589 -95.2169 65.0479 -80.0523 -157.341))
  (send *pr2* :larm :angle-vector *lav-vc*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 8000)
  (send *ri* :wait-interpolation)
  
  (warn "please go to kitchen spot !! ~%")  
  )


;; now funcs
(defun now-devel ()
  (set-mcup)
  (carry-mcup-pose)
  (mcup-water-set)

  (grasp-lever)
  (water-on)

  ;; 本当はここで認識をする
  (unix:sleep 3)

  (water-off)
  (release-lever)

  (slide-mcup)
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


(defun now-devel-wash-veg ()
  (wash-veg-set)

  (grasp-lever)
  (water-on)

  (unix:sleep 3)

  (slide-mcup)
  (water-off)
  (release-lever)

  (after-wash-veg-set)
  )


(defun now-fetch-water (&rest args &key (sleep-time 1) &allow-other-keys)
  (after-move)
  (set-mcup)
  (mcup-water-set)

  (grasp-lever)
  (water-on)

  ;; 本当はここで認識をする
  (unix:sleep sleep-time)

  (slide-mcup)
  (water-off)
  (release-lever)

  (after-mcup-water)
  )

(defun now-fetch-water-with-fail-detection-old (&rest args &key (sleep-time 1) &allow-other-keys)
  (after-move)
  (set-mcup)
  (mcup-water-set)

  (grasp-lever)

  ;; 失敗を検知する
  (grasp-fail-detection :g-thre 10)
  (if (equal *fail-flag* t) ;; 一度失敗したらもう一度挑戦する
      (progn
        (release-lever)
        (grasp-lever :adjust -20)
        (grasp-fail-detection :g-thre 10)
        (if (equal *fail-flag* t) ;; 二度失敗したら人に助けてもらう
            (progn
              (release-lever)
              (send *ri* :speak-jp "水道の操作に失敗しました，水を汲んで合図をして下さい")
              (ok-wait)

              (slide-mcup)
              (after-mcup-water)

              (return-from now-fetch-water-with-fail-detection)))
        ))

  (water-on)

  ;; 本当はここで認識をする
  (unix:sleep sleep-time)

  (slide-mcup)
  (water-off)
  (release-lever)

  (after-mcup-water)
  )

(defun now-fetch-water-with-fail-detection (&rest args &key (sleep-time 1) &allow-other-keys)
  (after-move)
  (set-mcup)
  (mcup-water-set)

  (before-lever)
  (grasp-lever-tmp)

  ;; 失敗を検知する
  (grasp-fail-detection :g-thre 10)
  (if (equal *fail-flag* t) ;; 一度失敗したらもう一度挑戦する
      (progn
        (release-lever-tmp)
        (grasp-lever-tmp :adjust -20)
        (grasp-fail-detection :g-thre 10)
        (if (equal *fail-flag* t) ;; 二度失敗したら人に助けてもらう
            (progn
              (release-lever-tmp)
              (reset-rarm)
              (send *ri* :speak-jp "水道の操作に失敗しました，水を汲んで合図をして下さい")
              (ok-wait)

              (slide-mcup)
              (after-mcup-water)

              (return-from now-fetch-water-with-fail-detection)))
        ))

  (water-on)

  ;; 本当はここで認識をする
  (unix:sleep sleep-time)

  (slide-mcup)
  (water-off)
  (release-lever-tmp)
  (reset-rarm)

  (after-mcup-water)
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
  (now-devel-wash-veg)
  )

(defun tmp-devel ()
  (unix:sleep 1)
  (wash-veg-set)
  
  (grasp-lever)
  (water-on)
  
  (unix:sleep 3)
  
  (water-off)
  (release-lever)
  )

(defun now-wash-veg (&rest args &key (sleep-time 3) &allow-other-keys)
  (after-move)
  (wash-veg-set)
  
  (grasp-lever)
  (water-on)
  
  (unix:sleep sleep-time)
  
  (water-off)
  (release-lever)
  
  (after-wash-veg-set)
  (after-wash)
  (vegs-carry-pose)
  )


(defun tmp-exec ()
  (after-wash)
  (vegs-carry-pose)
  )


;; tmp red-cup
(defun now-fetch-water-rcup-with-fail-detection (&rest args &key (sleep-time 1) &allow-other-keys)
  (after-move)
  (set-rcup)
  (rcup-water-set)
  
  (before-lever)
  (grasp-lever-tmp)
  
  ;; 失敗を検知する
  (unix:sleep 1) ;; tmp  
  (grasp-fail-detection :g-thre 10)
  (if (equal *fail-flag* t) ;; 一度失敗したらもう一度挑戦する
      (progn
        (release-lever-tmp)
        (grasp-lever-tmp :adjust -20)
        (unix:sleep 1) ;; tmp  
        (grasp-fail-detection :g-thre 10)
        (if (equal *fail-flag* t) ;; 二度失敗したら人に助けてもらう
            (progn
              (release-lever-tmp)
              (reset-rarm)
              (send *ri* :speak-jp "水道の操作に失敗しました，水を汲んで合図をして下さい")
              (ok-wait)
              
              (slide-rcup)
              (rcup-nigasu)
              (after-rcup-water)
              
              (return-from now-fetch-water-rcup-with-fail-detection)))
        ))

  (water-on)

  ;; 本当はここで認識をする
  ;; (unix:sleep sleep-time)
  (unix:sleep 3)

  (slide-rcup)
  (water-off)
  (release-lever-tmp)
  (reset-rarm)

  (rcup-nigasu)
  (after-rcup-water)
  )



(defun now-set-rcup-water ()
  (after-move)
  (set-rcup)
  (rcup-water-set)
  (warn "please run (now-on-water)")
  )
