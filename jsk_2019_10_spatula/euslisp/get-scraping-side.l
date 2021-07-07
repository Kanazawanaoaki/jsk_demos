(load "package://pr2eus/pr2-interface.l")
(setq *ri* (instance pr2-interface :init))
(pr2-init t)


;;start robot from reset position
(send *pr2* :reset-pose)
(if (boundp '*irtviewer*)    
    (send *irtviewer* :draw-objects))

(send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
(send *ri* :wait-interpolation)


;; move robot into initial position
(send *pr2* :rarm :shoulder-p :joint-angle -20)
(send *pr2* :larm :shoulder-p :joint-angle 50)
(send *pr2* :rarm :shoulder-r :joint-angle -130)
(send *pr2* :larm :shoulder-r :joint-angle 120)
(send *pr2* :larm :elbow-p :joint-angle -100)
(send *pr2* :rarm :elbow-p :joint-angle -70)
(send *pr2* :rarm :elbow-r :joint-angle 0)
(send *pr2* :rarm :wrist-p :joint-angle -40)
(send *pr2* :larm :wrist-r :joint-angle 30)

(if (boundp '*irtviewer*)    
    (send *irtviewer* :draw-objects))
(send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
(send *ri* :wait-interpolation)


;; hand the robot the spatula
(send *pr2* :stop-grasp)
(send *ri* :stop-grasp)
(send *ri* :wait-interpolation)
(unix:sleep 5)
(send *pr2* :start-grasp :rarm)
(send *ri* :start-grasp :rarm :gain 0.05)
(send *ri* :wait-interpolation)

;;define angle-vectors for movement
;;send *ri* :state :potentio-vector
;;(objects *r-tcp*)
(setq *av1* #f(49.9331 56.1185 28.9347 130.252 -106.951 -4.19415 -27.7583 140 -16.9966 -9.03369 -111.73 -116.714 -76.193 -57.7095 266.18 3.0727 -21.2682))
(setq *av2* #f(49.9331  56.1185 28.9347 130.252 -106.951 -4.19415 -27.7583 140 -29.1714 -9.19364 -117.398 -118.456 -81.5623 -50.4353 263.348 3.0727 -21.2682))
(setq *av3* #f(49.9331  56.1185 28.9347 130.252 -106.951 -4.19415 -27.7583 140 -29.0716 -9.25665 -86.0776 -118.804 -76.2328 -66.8658 270.291 3.0727 -21.2682))

(setq *av-r-approach* #f(49.9331 56.1185 28.9347 130.252 -106.951 -4.19415 -27.7583 140.0 -32.5695 -12.6491 -76.4196 -115.819 -67.3766 -74.5905 266.454 3.0727 -21.2682))
(setq *av-newbowl* #f(49.9125 56.1185 28.9347 130.252 -106.951 -4.19415 -27.7583 145.49 -44.3293 -11.7819 -87.1801 -121.541 -68.7655 -64.4132 266.2 3.3307 -21.2682))


;;start position
(send *pr2* :angle-vector *av-newbowl*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :larm-controller)
(send *ri* :wait-interpolation)
;;hand the robot the bowl
(unix:sleep 2)
(send *pr2* :start-grasp :larm)
(send *ri* :start-grasp :larm :gain 0.05)
(send *ri* :wait-interpolation)

;;one vector inbetween the start to avoid hitting the bowl with the spatula
(send *pr2* :angle-vector *av-r-approach*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 1500 :rarm-controller)
(send *ri* :wait-interpolation)

(setq *l-tcp* (send (send *pr2* :larm :end-coords) :copy-worldcoords))
(setq *ltargetframe* (send *pr2* :larm :end-coords))

;;adjust the bowl for the best starting position
;;(send *l-tcp* :translate (float-vector 20 -20 -20))
;;(send *pr2* :larm :inverse-kinematics *l-tcp*)
;;(send *ri* :angle-vector (send *pr2* :angle-vector) 700 :larm-controller)
;;(send *ri* :wait-interpolation)


;;as a start use *av3*
;;(send *pr2* :angle-vector *av3*)
;;(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
;;(send *ri* :wait-interpolation)

(setq *r-tcp* (send (send *pr2* :rarm :end-coords) :copy-worldcoords))

(setq *av1-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -20.7298 -3.36521 -84.946 -116.734 -83.5788 -70.6311 277.265 0.006701 -2.298))
(setq *av2-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -15.2191 9.85133 -94.9152 -114.105 -101.092 -67.2035 280.509 0.006701 -2.298))
(setq *av3-wall* #f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -27.7253 2.64068 -84.0543 -120.025 -86.5879 -74.2459 273.116 0.006701 -2.298))


(send *pr2* :angle-vector *av3-wall*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :larm-controller)
(send *ri* :wait-interpolation)
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
(send *ri* :wait-interpolation)

(send *pr2* :angle-vector *av1-wall*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
(send *ri* :wait-interpolation)

(send *pr2* :angle-vector *av2-wall*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
(send *ri* :wait-interpolation)

(send *pr2* :angle-vector *av3-wall*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
(send *ri* :wait-interpolation)

;;larm start position -> *av3-wall*
;;#f(49.9246 49.4965 26.2457 123.885 -101.996 -6.95641 -29.4629 135.943 -29.0716 -9.25665 -86.0776 -118.804 -76.2328 -66.8673 270.29 0.006701 -2.298)

;;av1-wall
;;#f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -20.7298 -3.36521 -84.946 -116.734 -83.5788 -70.6311 277.265 0.006701 -2.298)

;;av2-wall
;;#f(49.9246 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -15.2191 9.85133 -94.9152 -114.105 -101.092 -67.2035 280.509 0.006701 -2.298)

;;

#|
;;and move 6 cm forward
(send *r-tcp* :translate (float-vector 0 60 0))
(send *pr2* :rarm :inverse-kinematics *r-tcp*)
(if (boundp '*irtviewer*)
      (send *irtviewer* :draw-objects))
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
(send *ri* :wait-interpolation)

(setq *r-tcp1* (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
;;now adjust the right hand to a good starting position for scraping
(send *r-tcp1* :translate (float-vector 0 0 0))
(send *pr2* :rarm :inverse-kinematics *r-tcp1*)
(if (boundp '*irtviewer*)
      (send *irtviewer* :draw-objects))
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
(send *ri* :wait-interpolation)
;;save the angle vector when satisfied
(setq *av1-wall* (send *ri* :state :potentio-vector))


;;then scrape down
(send *r-tcp* :translate (float-vector 110 0 0))
(send *pr2* :rarm :inverse-kinematics *r-tcp*)
(if (boundp '*irtviewer*)
      (send *irtviewer* :draw-objects))
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
(send *ri* :wait-interpolation)
;;save the angle vector when satisfied
(setq *av2-wall* (send *ri* :state :potentio-vector))

;;*av3-wall* should be the same as *av3*
(setq *av3-wall* *av3*)
(send *pr2* :angle-vector *av3-wall*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
(send *ri* :wait-interpolation)
|#
