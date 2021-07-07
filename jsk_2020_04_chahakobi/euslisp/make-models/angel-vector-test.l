#!/usr/bin/env roseus
;; load pr2-interface.l
(load "package://pr2eus/pr2.l")
(setq *pr2* (pr2))


;;define angle-vectors for vision
(setq *av-snapshot* #f(324.807 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -15.2124 -9.77758 -83.654 -81.938 -58.164 -102.254 344.738 3.0727 72))
(setq *look-front* #f(324.807 48.1046 24.0788 125.944 -102.011 -13.0963 -30.5362 126.148 -16.7019 -12.4359 -83.5748 -75.1221 -57.0671 -106.827 337.891 3.0727 72.0))
(setq *look-back* #f(324.807 51.737 30.1327 120.422 -101.764 4.18285 -28.8173 149.013 -17.8988 -13.2915 -80.4201 -84.9935 -54.0573 -104.319 347.318 3.0727 72.0))
(setq *look-right* #f(324.807 45.4864 16.3124 126.845 -108.835 -5.52084 -15.5745 129.482 -16.3723 -9.6885 -84.0297 -78.6769 -58.9823 -104.076 340.577 3.0727 72.0))
(setq *look-left* #f(324.807 51.1648 45.4815 116.822 -85.7364 -9.41469 -61.5682 142.069 -18.4818 -17.5874 -75.8746 -87.1968 -48.6971 -106.389 352.394 3.0727 72.0))

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
(send *axis* :rotate (deg2rad 180) :x)  
(send *irtviewer* :draw-objects)

(send *pr2* :larm :inverse-kinematics
      *axis*
      :rotation-axis :t
      :debug-view t)

(send *axis* :translate #f(90 0 0) :world)
(send *irtviewer* :draw-objects)

(send *pr2* :larm :inverse-kinematics
      *axis*
      :rotation-axis :t
      :debug-view t)

(send (send *pr2* :larm :end-coords :parent) :assoc *kettle*)


(defun step1 ()
  (send *pr2* :angle-vector *av-snapshot*))

(defun step2 ()
  (send *pr2* :angle-vector *look-front*))

(defun step3 ()
  (send *pr2* :angle-vector *look-back*))

(defun step4 ()
  (send *pr2* :angle-vector *look-right*))

(defun step5 ()
  (send *pr2* :angle-vector *look-left*))  


(defun pose1 ()
  (send *axis* :newcoords (make-coords :pos #f(400 0 800) :rpy #f(-1.57 0 -1.57)))
  (send *pr2* :larm :inverse-kinematics
	*axis*
	;; (make-coords :pos #f(358.676 83.313 803.969) :rpy #f(0 0 0))
	;; (make-coords :pos #f(358.676 83.313 803.969) :rpy #f(-1.562 0.04 3.113))
	:rotation-axis t
	:debug-view t)
  (setq *pose1* (send *pr2* :angle-vector))
  )

(defun pose2 ()
  (send *axis* :rotate (deg2rad 80) :y)
  (send *pr2* :larm :inverse-kinematics
	*axis*
	;; (make-coords :pos #f(358.676 83.313 803.969) :rpy #f(0 0 0))
	;; (make-coords :pos #f(358.676 83.313 803.969) :rpy #f(-1.562 0.04 3.113))
	:rotation-axis t
	:debug-view t)
  (setq *pose1* (send *pr2* :angle-vector))
  )
