#!/usr/bin/env roseus

;; detect_cans_in_fridge_201202/euslisp/main.l を参考に書いていく

;; load pr2-interface.l
(require :pr2-interface "package://pr2eus/pr2-interface.l")


;; load scene for kinematics simulater
(require :pr2-move "package://jsk_demo_common/euslisp/pr2-move.l")


;; define move method for kinematics simulater
(defun go-to-spot (&key (wait t) (spot-name "fridge-front-spot"))
  (let ((co (send *scene* :spot "/eng2/7f/room73B2-fridge-front")))
    (send co :translate (float-vector 0 0 0) :world)
    (if (send *ri* :simulation-modep)
        (setq co (send *room73b2* :spot spot-name)))
    (cond
     ((equal wait t)
      (send *ri* :move-to co)
      )
     (t
      (send *ri* :move-to-send co)
      ))
    t
    ))



;; robot initialize
(pr2-init)
(setq *robot* *pr2*)

;; set room73b2
(load "models/room73b2-scene.l")
(room73b2)

;; set arrow
(load "models/arrow-object.l")
(setq *axis* (arrow))

;; set kettle
(setq *kettle* (send *room73b2* :object "room73b2-kettle"))  
(if (send *kettle* :parent) (send (send *kettle* :parent) :dissoc *kettle*))
(send *kettle* :rotate (deg2rad -180) :z :world) 

;; set cup
(setq *cup* (send *room73b2* :object "room73b2-mug-cup"))
(if (send *cup* :parent) (send (send *cup* :parent) :dissoc *cup*))


;; set 73b2
(if (send *ri* :simulation-modep)
    (progn
      (send *ri* :objects (send *room73b2* :objects))
      ))

;; IRT viewer
(objects (list *robot* *room73b2* *axis*))


(format t ";; please run (go-to-cook) , (exec-all) or (now-devel)~%")

;; キッチンまで行く
(defun go-to-cook ()
  (send *robot* :move-to (send *room73b2* :spot "cook-spot") :world)
  (send *ri* :go-pos 1.1 0 90)
  (go-to-spot :wait t :spot-name "cook-spot")
  
  (send *robot* :torso_lift_joint :joint-angle 325)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (send *irtviewer* :look-all
	(geo::make-bounding-box
	 (flatten (send-all (send *robot* :bodies) :vertices))))
  
  (format t ";; please run (pick-up-kettle)~%"))

(defun pick-up-kettle ()
  ;; やかんを持つ
  (send *axis* :newcoords (send *kettle* :copy-worldcoords))
  (send *axis* :transform (car (send *kettle* :handle)))
  (send *axis* :rotate (deg2rad -90) :y :world)
  
  (send *robot* :head :look-at (send *kettle* :worldpos))
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (send *robot* :larm :inverse-kinematics                                              
	*axis*
	:rotation-axis :t
	:debug-view t)  
  (send *ri* :angle-vector (send *robot* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send (send *robot* :larm :end-coords :parent) :assoc *axis*)
  (send (send *robot* :larm :end-coords :parent) :assoc *kettle*)
  (send *ri* :start-grasp :larm :wait t)

  (send *robot* :larm :move-end-pos #f(50 0 100) :world
	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (send *robot* :larm :move-end-pos #f(50 0 50) :world
	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (setq *move-pose* (send *robot* :angle-vector))
  (format t ";; please run (go-to-sink)~%"))

(defun go-to-sink ()
  ;; シンクまで移動する
  (send *robot* :move-to (send *room73b2* :spot "/eng2/7f/room73B2-sink-front")  :world)
  (go-to-spot :wait t :spot-name "/eng2/7f/room73B2-sink-front")
  
  (send *robot* :move-to (make-coords :pos #f(300 -150 0)))
  (send *ri* :go-pos 0.3 -0.15 0)
  
  (format t ";; please run (pour-water)~%"))

(defun pour-water ()
  ;; やかんに水を入れる
  (setq *now-rpy* (car (send (send (send *robot* :larm :end-coords) :worldcoords) :rpy-angle)))
  (send *robot* :larm :inverse-kinematics
	(make-coords :pos #f(370 2580 900) :rpy *now-rpy*)
	:rotation-axis :t
	:debug-view t)
  (send *robot* :rarm :inverse-kinematics
	(make-coords :pos #f(200 2580 950) :rpy *now-rpy*)
	:rotation-axis :z
	:debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *robot* :rarm :move-end-pos #f(0 0 50) :world
	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (unix:sleep 1) ;;本来は中身をみて一定の量になったら終了する。時間指定も有り。

  (send *robot* :rarm :move-end-pos #f(0 0 -50) :world
	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (send *robot* :angle-vector *move-pose*)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (format t ";; please run (go-to-cook2)~%")
  )

;; コンロの前に行く
(defun go-to-cook2 ()
  (send *robot* :move-to (send *room73b2* :spot "cook-spot") :world)
  (go-to-spot :wait t :spot-name "cook-spot")
  
  (send *robot* :torso_lift_joint :joint-angle 325)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  (format t ";; please run (put-kettle)~%"))


;; やかんを置く
(defun put-kettle ()
  (setq *now-rpy* (car (send (send (send *robot* :larm :end-coords) :worldcoords) :rpy-angle))) 
  (send *robot* :larm :inverse-kinematics
        (make-coords :pos #f(500 1500 1020) :rpy *now-rpy*)
        :rotation-axis :t
        :debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send (send *robot* :larm :end-coords :parent) :dissoc *kettle*)
  (send (send *robot* :larm :end-coords :parent) :dissoc *axis*)
  (send *ri* :stop-grasp :larm :wait t)

  (send *robot* :larm :move-end-pos #f(40 0 0) :world
	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *robot* :angle-vector *move-pose*)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (format t ";; please run (put-on-stove)~%"))

;; コンロをつける
(defun put-on-stove ()
  (send *robot* :rarm :inverse-kinematics
        (make-coords :pos #f(660 1550 710) :rpy #f(3.142 0 -1.571))
        :rotation-axis :t
        :debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *robot* :angle-vector *move-pose*)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (format t ";; please run (prepare-tea)~%"))


;; お茶orコーヒーorカップラーメンを用意する
(defun prepare-tea ()
  ;; お茶のパックを引き出しから出して、セットする

  (format t ";; please run (wait-boil)")
  )

;; お湯が湧くのを待つ（音認識）
(defun wait-boil ()
  (unix:sleep 2) ;; 本当は音がなったらとかにする。
  (format t ";; please run (turn-off-stove)~%")
  )

;; コンロを消す
(defun turn-off-stove ()
  (send *robot* :rarm :inverse-kinematics
        (make-coords :pos #f(660 1550 710) :rpy #f(3.142 0 -1.571))
        :rotation-axis :t
        :debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)


  (send *robot* :angle-vector *move-pose*)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (format t ";; please run (pick-up-kettle2)~%")
  )

;; やかんを持つ
(defun pick-up-kettle2 ()
  (send *axis* :move-to (send *kettle* :copy-worldcoords) :world)
  (send *axis* :transform (car (send *kettle* :handle)))
  (send *axis* :rotate (deg2rad -90) :y :world)
  
  (send *robot* :head :look-at (send *kettle* :worldpos))
  
  (send *robot* :larm :inverse-kinematics                                              
	*axis*
	:rotation-axis :z
	:debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send (send *robot* :larm :end-coords :parent) :assoc *kettle*)
  (send (send *robot* :larm :end-coords :parent) :assoc *axis*)
  (send *ri* :start-grasp :larm :wait t)
   
  (send *robot* :larm :move-end-pos #f(0 70 50) :world
  	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (format t ";; please run (pour-hot-water)~%"))

;; コップにお湯を入れる
(defun pour-hot-water ()
  (send *robot* :larm :inverse-kinematics
        (make-coords :pos #f(497.704 1550 930) :rpy #f( -3.14 0 0.7))
        :move-target *kettle*
	:rotation-axis :t
        :debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (unix:sleep 1) ;;本当は認識して注げたかを確認する。

  (send *robot* :larm :inverse-kinematics                                          
        (make-coords :pos #f(500.164 1569.706 875.318) :rpy #f( -3.141 0.001 0))
        :move-target *kettle*
	:rotation-axis :t                                           
        :debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (format t ";; please run (put-kettle2)~%"))

;; やかんを戻す
(defun put-kettle2 ()
  (setq *now-rpy* (car (send (send (send *robot* :larm :end-coords) :worldcoords) :rpy-angle))) 
  (send *robot* :larm :inverse-kinematics                                          
        (make-coords :pos #f(500 1500 1020) :rpy *now-rpy*)
        :rotation-axis :t                                            
        :debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send (send *robot* :larm :end-coords :parent) :dissoc *kettle*)
  (send (send *robot* :larm :end-coords :parent) :dissoc *axis*)  
  (send *ri* :stop-grasp :larm :wait t)

  (send *robot* :larm :move-end-pos #f(40 0 0) :world
	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *robot* :angle-vector *move-pose*)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (format t ";; please run (pick-up-cup)~%"))

;; コップをつかむ
(defun pick-up-cup ()
  (send *robot* :reset-pose)
  (send *robot* :torso_lift_joint :joint-angle 325)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *axis* :newcoords (send *cup* :copy-worldcoords))
  (send *axis* :transform (car (send *cup* :handle)))
  (send *robot* :head :look-at (send *cup* :worldpos))
  
  (send *robot* :rarm :inverse-kinematics                                              
	*axis*
	:rotation-axis :t
	:debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (send (send *robot* :rarm :end-coords :parent) :assoc *cup*)
  (send (send *robot* :rarm :end-coords :parent) :assoc *axis*)
  (send *ri* :start-grasp :rarm :wait t)

  (send *robot* :rarm :move-end-pos #f(100 -100 100) :world
  	:debug-view t :look-at-target t)  
  (send *robot* :rarm :move-end-pos #f(100 -100 100) :world
  	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (format t ";; please run (go-to-desk)~%"))

;; 机まで持っていく
(defun go-to-desk ()
  (setq *desk-spot* (make-coords :pos #f(3470 -1900 0) :rpy #f(-1.57 0 0)))
  (send *robot* :move-to *desk-spot* :world)
  (send *ri* :go-pos 0 1.5 90)
  (send *ri* :go-pos 0 2.5 0)
  (send *ri* :move-to *desk-spot*)
  
  (send *robot* :rarm :inverse-kinematics
	(make-coords :pos #f(3470 -2500 700) :rpy #f(1.571 0 0))
	:move-target *cup*
	:rotation-axis :t
	:debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (send (send *robot* :rarm :end-coords :parent) :dissoc *cup*)
  (send (send *robot* :rarm :end-coords :parent) :dissoc *axis*)
  (send *ri* :stop-grasp :rarm :wait t)

  (send *robot* :rarm :move-end-pos #f(-50 0 0) :world                    
	:debug-view t :look-at-target t)
  (send *robot* :reset-pose)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (format t ";; please enjoy tea!~%"))                                            


(defun exec-all ()
  (go-to-cook)
  (pick-up-kettle)
  (go-to-sink)
  (pour-water)
  (go-to-cook2)
  (put-kettle)
  (put-on-stove)
  (prepare-tea)
  (wait-boil)
  (turn-off-stove)
  (pick-up-kettle2)
  (pour-hot-water)
  (put-kettle2)
  (pick-up-cup)
  (go-to-desk)
  )

(defun now-devel ()
  (go-to-cook)
  (pick-up-kettle)
  (go-to-sink)
  (pour-water)
  (go-to-cook2)
  (put-kettle)
  (put-on-stove)
  )
