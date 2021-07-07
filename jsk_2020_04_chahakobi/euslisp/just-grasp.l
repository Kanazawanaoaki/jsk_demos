#!/usr/bin/env roseus
1;5202;0c
;; load pr2-interface.l
(load "package://pr2eus/pr2-interface.l")

;; init 
(pr2-init)


;; reset-manip-pose
(send *pr2* :reset-manip-pose)
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
(send *ri* :wait-interpolation)


;; init
(load "models/kettle-object.l")
(setq *kettle* (kettle))
(send *kettle* :locate #f(780 0 740) :world)
(send *kettle* :rotate (deg2rad 180) :z) 

(load "models/arrow-object.l")
(setq *axis* (arrow))
(send *axis* :move-to (send *kettle* :handle-handle0) :world)
(objects (list *pr2* *kettle* *axis*))

;; IKを解いてつかむ

(send *axis* :move-to (send (send *kettle* :handle-handle0) :worldcoords) :world)
(send *axis* :translate #f(-80 0 0) :world)
(send *axis* :rotate (deg2rad 180) :y) 
(send *irtviewer* :draw-objects)

(send *axis* :locate #f(0 0 -40))

(send *ri* :stop-grasp :larm)
(send *pr2* :larm :inverse-kinematics
      *axis*
      :rotation-axis :t
      :debug-view t)
(send *ri* :angle-vector (send *pr2* :angle-vector))
(send *ri* :wait-interpolation)

(send *axis* :translate #f(100 0 0) :world)
(send *irtviewer* :draw-objects)

(send *pr2* :larm :inverse-kinematics
      *axis*
      :rotation-axis :t
      :debug-view t)
(send *ri* :angle-vector (send *pr2* :angle-vector))
(send *ri* :wait-interpolation)

;; (send *axis* :translate #f(10 0 10) :world)
;; (send *axis* :rotate (deg2rad 30) :z)
;; (send *irtviewer* :draw-objects)
;; (send *pr2* :larm :inverse-kinematics
;;       *axis*
;;       :rotation-axis :t
;;       :debug-view t)
;; (send *ri* :angle-vector (send *pr2* :angle-vector))
;; (send *ri* :wait-interpolation)


(send *ri* :start-grasp :larm)
