(load "package://pr2eus/pr2-interface.l")
(pr2-init)

(send *pr2* :reset-pose)

(load "models/arrow-object.l")
(setq *arrow* (arrow))
(send *arrow* :newcoords (make-coords :pos #f(600 0 1000)))
;; (objects (list *pr2* *arrow*))
(objects (list *pr2*))

(setq *rt* (arrow))
(send *rt* :newcoords (make-coords :pos #f(600 -25 1000)))
(send *rt* :rotate (deg2rad 90) :z)
(send *pr2* :rarm :inverse-kinematics *rt*)
(send *ri* :angle-vector (send *pr2* :angle-vector))
(send *ri* :wait-interpolation)

(setq *lt* (arrow))
(send *lt* :newcoords (make-coords :pos #f(600 25 1000)))
(send *lt* :rotate (deg2rad -90) :z)
(send *pr2* :larm :inverse-kinematics *lt*)
(send *ri* :angle-vector (send *pr2* :angle-vector))
(send *ri* :wait-interpolation)

(setq *arrow* (arrow))
(send *arrow* :newcoords (make-coords :pos #f(600 0 1000)))
(send *pr2* :head :look-at (send *arrow* :worldpos))
(send *ri* :angle-vector (send *pr2* :angle-vector))
