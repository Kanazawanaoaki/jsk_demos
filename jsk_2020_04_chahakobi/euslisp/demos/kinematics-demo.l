#!/usr/bin/env roseus

;; ロボットシステムの資料を参考に書いていく (detect_cans_in_fridge_201202/euslisp/main.lも？)

;; load pr2-interface.l
(require :pr2-interface "package://pr2eus/pr2-interface.l")
;; robot initialize
(pr2-init)
(setq *robot* *pr2*)


;; set room73b2
(load "models/room73b2-scene.l")
(setq *room73b2* (room73b2))

;; set arrow
(load "models/arrow-object.l")
(setq *axis* (arrow))

;; set cup
(setq *cup* (send *room73b2* :object "room73b2-mug-cup"))
(if (send *cup* :parent) (send (send *cup* :parent) :dissoc *cup*))

;; set kettle
(setq *kettle* (send *room73b2* :object "room73b2-kettle"))  
(if (send *kettle* :parent) (send (send *kettle* :parent) :dissoc *kettle*))
(send *kettle* :locate #f(0 0 -500))

;; set tray
(setq *tray* (send *room73b2* :object "room73b2-tray"))  
(if (send *tray* :parent) (send (send *tray* :parent) :dissoc *tray*))
(send *tray* :locate #f(100 0 -500))

(load "model/kettle-body.l")
(setq *kettle-body* (kettle-body))
(send *kettle-body* :newcoords (make-coords :pos #f(500.0 1500.0 825.0) :rpy #f(-3.142 0.0 0.0)))
(load "model/kettle-lid.l")
(setq *kettle-lid* (kettle-lid))
(send *kettle-lid* :newcoords (make-coords :pos #f(500 1500 825) :rpy #f(-3.142 0 0)))
;; (send *kettle-body* :assoc *kettle-lid*)


(setq *obj-list* (send *room73b2* :objects))
(setq *obj-list* (append *obj-list* (list *kettle-body* *kettle-lid*)))

;; set 73b2
(if (send *ri* :simulation-modep)
    (progn
      (send *ri* :objects *obj-list*)
      ))

;; IRT viewer
(objects (list *robot* *room73b2* *axis* *kettle-body* *kettle-lid*))

(format t ";; please run (go-to-cook) , (exec-all) or (now-devel)~%")

;; set spots
(setq *cook-spot* (send *room73b2* :spot "cook-spot") )
(setq *sink-spot* (make-coords :pos #f(1055 2600 0) :rpy #f(3.14 0 0))) 
(setq *desk-spot* (make-coords :pos #f(3470 -1900 0) :rpy #f(-1.57 0 0)))

;; set points
(setq *water-point* (make-coords :pos #f(340.0 2580.0 880.0) :rpy #f(3.14 0 0)))                
(setq *faucet-point* (make-coords :pos #f(200 2580 950) :rpy #f(3.14 0 0)))
(setq *cook-point0* (make-coords :pos #f(500.0 1500.0 825.0) :rpy #f(-3.14 0 0)))
(setq *cook-switch-point* (make-coords :pos #f(660 1550 710) :rpy #f(3.142 0 -1.571)))
(setq *desk-point* (make-coords :pos #f(3470 -2500 700) :rpy #f(1.571 0 0)))

;; set angle-vector
(setq *carry-mcup-pose* #f(300.0 8.04734 38.6959 47.4962 -121.537 -182.722 -69.9025 145.758 -75.0 50.0 -110.0 -110.0 20.0 -10.0 -10.0 -4.27655 47.3669))


;; キッチンまで行く
(defun go-to-cook ()
  (send *robot* :move-to *cook-spot* :world)
  (send *ri* :go-pos 1.1 0 90)
  (send *ri* :move-to *cook-spot*)
  
  (send *robot* :reset-manip-pose)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)

  (send *irtviewer* :look-all
	(geo::make-bounding-box
	 (flatten (send-all (send *robot* :bodies) :vertices))))
  
  (format t ";; please run (open-the-lid)~%"))

;; やかんの蓋を開ける
(defun open-the-lid ()
  (send *axis* :move-to (send (car (send *kettle-lid* :handle)) :worldcoords) :world)

  (send *robot* :head :look-at (send *axis* :worldpos))
  
  (send *robot* :rarm :inverse-kinematics                                              
	*axis*
	:rotation-axis :t
	:debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  
 
  (if (send *kettle-lid* :parent) (send (send *kettle-lid* :parent) :dissoc *kettle-lid*))
  (send (send *robot* :rarm :end-coords :parent) :assoc *kettle-lid*)
  (send *ri* :start-grasp :larm :wait t)
  (send *ri* :robot :rarm :end-coords :assoc (car (send *ri* :find-object *kettle-lid*)))
  
  (send *robot* :rarm :move-end-pos #f(50 0 100) :world
	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  ;; 蓋を置く 
  (send *axis* :move-to (make-coords :pos #f(560.0 1900.0 835.0) :rpy #f(3.14 0 0)) :world)
  (send *robot* :rarm :inverse-kinematics	
  	*axis*
  	:move-target (car (send *kettle-lid* :attention))
  	:rotation-axis :t
  	:debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (send (send *robot* :rarm :end-coords :parent) :dissoc *kettle-lid*)
  (send *ri* :stop-grasp :larm :wait t)
  (send *ri* :robot :rarm :end-coords :dissoc (car (send *ri* :find-object *kettle-lid*)))

  (send *robot* :reset-manip-pose)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (format t ";; please run (pick-up-kettle)~%"))

;; やかんを持つ
(defun pick-up-kettle ()
  (send *axis* :move-to (send (car (send *kettle-body* :handle)) :worldcoords) :world)
  
  (send *robot* :head :look-at (send *axis* :worldpos))
  
  (send *robot* :larm :inverse-kinematics                                              
	*axis*
	:rotation-axis :t
	:debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (send (send *robot* :larm :end-coords :parent) :assoc *kettle-body*)
  (send *ri* :start-grasp :larm :wait t)
  
  (send *robot* :larm :move-end-pos #f(50 0 100) :world
	:debug-view t :look-at-target t)
  (send *robot* :larm :move-end-pos #f(0 0 50) :world
	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (setq *move-pose* (send *robot* :angle-vector))
  (format t ";; please run (go-to-sink)~%"))

;; シンクまで移動する
(defun go-to-sink ()
  (send *robot* :move-to *sink-spot* :world)
  (send *ri* :move-to *sink-spot*)
  (format t ";; please run (get-water)~%"))

;; やかんに水を入れる
(defun get-water ()
  (send *axis* :move-to *water-point* :world)

  (send *robot* :larm :inverse-kinematics
	*axis*
	:move-target (elt (send *kettle-body* :attention) 1)
	:rotation-axis :z
	:debug-view t)

  (send *axis* :move-to *faucet-point* :world)
  (send *robot* :rarm :inverse-kinematics
	*axis*
	:rotation-axis :nil
	:debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  
  
  (send *robot* :rarm :move-end-pos #f(0 0 50) :world
  	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (unix:sleep 2) ;;本来は中身をみて一定の量になったら終了する。時間指定も有り。

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
  (send *robot* :move-to *cook-spot* :world)
  (send *ri* :move-to *cook-spot*)
  (format t ";; please run (put-kettle)~%"))

  
;; やかんを置く
(defun put-kettle ()
  (send *axis* :move-to *cook-point0* :world)
  (send *robot* :larm :inverse-kinematics
	*axis*
	:move-target *kettle-body*
        :rotation-axis :t
        :debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  
  
  (send (send *robot* :larm :end-coords :parent) :dissoc *kettle-body*)
  (send *ri* :stop-grasp :larm :wait t)

  (send *robot* :larm :move-end-pos #f(40 0 0) :world
	:debug-view t :look-at-target t)

  (send *robot* :angle-vector *move-pose*)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (format t ";; please run (close-the-lid)~%"))

;; 蓋を閉める
(defun close-the-lid ()
  (send *axis* :move-to (send (car (send *kettle-lid* :handle)) :worldcoords) :world)

  (send *robot* :head :look-at (send *axis* :worldpos))
  
  (send *robot* :rarm :inverse-kinematics                                              
	*axis*
	:rotation-axis :t
	:debug-view t)  
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  
  
  (if (send *kettle-lid* :parent) (send (send *kettle-lid* :parent) :dissoc *kettle-lid*))
  (send (send *robot* :rarm :end-coords :parent) :assoc *kettle-lid*)
  (send *ri* :start-grasp :rarm :wait t)
  (if (send (car (send *ri* :find-object *kettle-lid*)) :parent) (send (send (car (send *ri* :find-object *kettle-lid*)) :parent) :dissoc (car (send *ri* :find-object *kettle-lid*))))
  (send *ri* :robot :rarm :end-coords :assoc (car (send *ri* :find-object *kettle-lid*)))
  
  (send *robot* :rarm :move-end-pos #f(-50 0 100) :world
	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (send *robot* :rarm :inverse-kinematics                                              
	*kettle-body*
	:move-target *kettle-lid*
	:rotation-axis :t
	:debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  
  
  (if (send *kettle-lid* :parent) (send (send *kettle-lid* :parent) :dissoc *kettle-lid*))
  (send *ri* :stop-grasp :rarm :wait t)
  (send *kettle-body* :assoc *kettle-lid*)
  (send *ri* :robot :rarm :end-coords :dissoc (car (send *ri* :find-object *kettle-lid*)))

  (send *robot* :angle-vector *move-pose*)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (format t ";; please run (put-on-stove)~%"))


;; コンロをつける
(defun put-on-stove ()
  (send *robot* :rarm :inverse-kinematics
	*cook-switch-point*
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

  (format t ";; please run (wait-boil)~%")
  )

;; お湯が湧くのを待つ（音認識）
(defun wait-boil ()
  (unix:sleep 2) ;; 本当は音がなったらとかにする。
  (format t ";; please run (turn-off-stove)~%")
  )

;; コンロを消す
(defun turn-off-stove ()
  (send *robot* :rarm :inverse-kinematics
	*cook-switch-point*
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
  (send *axis* :move-to (send (car (send *kettle-body* :handle)) :worldcoords) :world)  
  (send *robot* :head :look-at (send *axis* :worldpos))
  (send *robot* :larm :inverse-kinematics                                              
	*axis*
	:rotation-axis :t
	:debug-view t)  
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  
  
  (send (send *robot* :larm :end-coords :parent) :assoc *kettle-body*)
  (send *ri* :start-grasp :larm :wait t)

  (send *robot* :larm :move-end-pos #f(0 70 100) :world
  	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (setq *stable-pose* (send *robot* :angle-vector))
  (format t ";; please run (pour-hot-water)~%"))

;; コップにお湯を入れる
(defun pour-hot-water ()
  (send *axis* :move-to (send (car (send *cup* :attention)) :worldcoords) :world)
  (send *axis* :locate #f(0 0 -30))
  (send *axis* :rotate (deg2rad 180) :z :world)
  (send *axis* :rotate (deg2rad -60) :x :world)
  
  (send *robot* :larm :inverse-kinematics
	*axis*
        :move-target (car (send *kettle-body* :attention))
	:rotation-axis :nil
        :debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (unix:sleep 2) ;;本当は認識して注げたかを確認する。

  (send *robot* :angle-vector *stable-pose*)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (format t ";; please run (put-kettle2)~%"))

;; やかんを戻す
(defun put-kettle2 ()
  (send *axis* :move-to *cook-point0* :world)
  (send *robot* :larm :inverse-kinematics
	*axis*
	:move-target *kettle-body*
        :rotation-axis :t
        :debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (send (send *robot* :larm :end-coords :parent) :dissoc *kettle-body*)
  (send *ri* :stop-grasp :larm :wait t)
  
  (send *robot* :larm :move-end-pos #f(40 0 0) :world
	:debug-view t :look-at-target t)

  (send *robot* :angle-vector *move-pose*)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (format t ";; please run (pick-up-cup)~%"))

;; コップをつかむ
(defun pick-up-cup ()
  (send *robot* :reset-manip-pose)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (send *axis* :move-to (send (car (send *cup* :handle)) :worldcoords) :world)  
  (send *robot* :head :look-at (send *cup* :worldpos))

  (send *robot* :rarm :inverse-kinematics                                              
	*axis*
	:rotation-axis :t
	:debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  
  
  (send (send *robot* :rarm :end-coords :parent) :assoc *cup*)
  (send *ri* :start-grasp :rarm :wait t)
  
  (send *robot* :rarm :move-end-pos #f(100 -100 100) :world
  	:debug-view t :look-at-target t)
  (unix:sleep 1)
  (send *robot* :rarm :move-end-pos #f(100 -100 100) :world
  	:debug-view t :look-at-target t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (format t ";; please run (go-to-desk)~%"))

;; 机まで持っていく
(defun go-to-desk ()
  (send *robot* :move-to *desk-spot* :world)
  (send *ri* :go-pos 0 1.5 90)
  (send *ri* :go-pos 0 2.5 0)
  (send *ri* :move-to *desk-spot*)
  
  (send *robot* :rarm :inverse-kinematics
	*desk-point*
	:move-target *cup*
	:rotation-axis :t
	:debug-view t)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (send (send *robot* :rarm :end-coords :parent) :dissoc *cup*)
  (send *ri* :stop-grasp :rarm :wait t)

  (send *robot* :rarm :move-end-pos #f(-50 0 0) :world                    
	:debug-view t :look-at-target t)
  (send *robot* :reset-pose)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)  

  (format t ";; please enjoy tea!~%"))                                            


(defun exec-all ()
  (go-to-cook)
  (open-the-lid)
  (pick-up-kettle)
  (go-to-sink)
  (get-water)
  (go-to-cook2)
  (put-kettle)
  (close-the-lid)
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
  (open-the-lid)
  (pick-up-kettle)
  (go-to-sink)
  (get-water)
  (go-to-cook2)
  (put-kettle)
  ;; (close-the-lid)
  ;; (put-on-stove)
  ;; (prepare-tea)
  ;; (wait-boil)
  ;; (turn-off-stove)
  ;; (pick-up-kettle2)
  ;; (pour-hot-water)
  ;; (put-kettle2)
  )
  
