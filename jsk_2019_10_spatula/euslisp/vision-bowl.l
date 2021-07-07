(load "package://pr2eus/pr2-interface.l")
(ros::roseus "pr2_send_joints")
;;(ros::advertise "start_scraping" std_msgs::bool 1)
(ros::advertise "action_r_arm" std_msgs::string 1)
(setq *ri* (instance pr2-interface :init))
(pr2-init t)

;;av for first moevments
(setq *av-r-approach* #f(49.9331 56.1185 28.9347 130.252 -106.951 -4.19415 -27.7583 140.0 -32.5695 -12.6491 -76.4196 -115.819 -67.3766 -74.5905 266.454 3.0727 72))
(setq *av-newbowl* #f(49.9125 56.1185 28.9347 130.252 -106.951 -4.19415 -27.7583 145.49 -44.3293 -11.7819 -87.1801 -121.541 -68.7655 -64.4132 266.2 3.3307 72))
(setq *av3* #f(49.9331  49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -29.0716 -9.25665 -86.0776 -118.804 -76.2328 -66.8658 270.291 3.0727 72))
;;base position around which movement was done
(setq *av-snapshot* #f(49.9331 49.5519 26.3404 123.787 -101.985 -6.62817 -29.4461 135.656 -15.2124 -9.77758 -83.654 -81.938 -58.164 -102.254 344.738 3.0727 72.0))

;;(send *l-tcp* :rotate (+ 0 (/ pi 12)) :y :world)
;;(setq *look-front* #f(49.9331 48.1046 24.0788 125.944 -102.011 -13.0963 -30.5362 126.148 -42.0622 2.80288 -75.3276 -120.343 -77.1933 -83.0409 260.172 3.0727 72.0))
;;(setq *look-front* #f(49.9331 48.1046 24.0788 125.944 -102.011 -13.0963 -30.5362 126.148 -13.1287 -9.37147 -84.3659 -72.939 -60.2333 -105.418 338.289 3.0727 72.0))
;;(send *l-tcp* :rotate (- 0 (/ pi 8)) :y :world)
;;(setq *look-back* #f(49.9331 51.737 30.1327 120.422 -101.764 4.18285 -28.8173 149.013 -15.7055 -13.3653 -80.7665 -83.8848 -54.1232 -103.834 348.24 3.0727 72.0))
;;(send *l-tcp* :rotate (+ 0 (/ pi 12)) :x :world)
;;(setq *look-right* #f(49.9331 45.4864 16.3124 126.845 -108.835 -5.52084 -15.5745 129.482 -14.2446 -9.58389 -84.0429 -77.551 -59.1313 -103.819 341.559 3.0727 72.0))
;; (send *l-tcp* :rotate (- 0 (/ pi 10)) :x :world)
;;(setq *look-left* #f(49.9331 51.1648 45.4815 116.822 -85.7364 -9.41469 -61.5682 142.069 -12.6521 -13.3023 -81.8618 -78.4099 -55.1697 -104.929 345.818 3.0727 72.0))


;;(send *l-tcp* :rotate (+ 0 (/ pi 12)) :y :world)
;;(setq *look-front* #f(49.9331 48.1046 24.0788 125.944 -102.011 -13.0963 -30.5362 126.148 -42.0622 2.80288 -75.3276 -120.343 -77.1933 -83.0409 260.172 3.0727 72.0))
(setq *look-front* #f(49.9331 48.1046 24.0788 125.944 -102.011 -13.0963 -30.5362 126.148 -12.2823 -12.0782 -84.1743 -68.6902 -58.5151 -108.045 336.0 3.0727 72.0))
;;(send *l-tcp* :rotate (- 0 (/ pi 8)) :y :world)
(setq *look-back* #f(49.9331 51.737 30.1327 120.422 -101.764 4.18285 -28.8173 149.013 -15.7055 -13.3653 -80.7665 -83.8848 -54.1232 -103.834 348.24 3.0727 72.0))
;;(send *l-tcp* :rotate (+ 0 (/ pi 12)) :x :world)
(setq *look-right* #f(49.9331 45.4864 16.3124 126.845 -108.835 -5.52084 -15.5745 129.482 -14.2446 -9.58389 -84.0429 -77.551 -59.1313 -103.819 341.559 3.0727 72.0))
;; (send *l-tcp* :rotate (- 0 (/ pi 10)) :x :world)
(setq *look-left* #f(49.9331 51.1648 45.4815 116.822 -85.7364 -9.41469 -61.5682 142.069 -18.4818 -17.5874 -75.8746 -87.1968 -48.6971 -106.389 352.394 3.0727 72.0))

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
(send *pr2* :head :neck-p :joint-angle 72)

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

(send *pr2* :angle-vector *av3*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 700 :larm-controller)
(send *ri* :wait-interpolation)


(send *pr2* :angle-vector  *av-snapshot*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :rarm-controller)
(send *ri* :wait-interpolation)

(setq *l-tcp* (send (send *pr2* :larm :end-coords) :copy-worldcoords))
;;(send *l-tcp* :rotate (+ 0 (/ pi 2)) :z :world) ;;toward robot
;;(send *pr2* :larm :inverse-kinematics *l-tcp*)
;;(send *ri* :angle-vector (send *pr2* :angle-vector) 1000 :larm-controller)


(setq *joint-angle-time* (list 1000 1000 1000 1000 1000)) 
(setq *joint-angle-list* (list *look-front* *look-right* *look-back* *look-left* *av-snapshot*))
(dotimes (j 5)
  (ros::service-call "passthrough_points/request" (instance std_srvs::EmptyRequest :init))
  (send *ri* :angle-vector-sequence *joint-angle-list* *joint-angle-time*)
  (send *ri* :wait-interpolation)
  (unix:sleep 2)
  )


#|
(dotimes (j 10)
(send *pr2* :angle-vector *look-front*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 300 :larm-controller)
(send *ri* :wait-interpolation)
(ros::service-call "passthrough_points/request" (instance std_srvs::EmptyRequest :init))
(unix:usleep 300000)

(send *pr2* :angle-vector  *look-right*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 300 :larm-controller)
(send *ri* :wait-interpolation)
(ros::service-call "passthrough_points/request" (instance std_srvs::EmptyRequest :init))
(unix:usleep 300000)

(send *pr2* :angle-vector  *look-back*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 300 :larm-controller)
(send *ri* :wait-interpolation)
(ros::service-call "passthrough_points/request" (instance std_srvs::EmptyRequest :init))
(unix:usleep 300000)

(send *pr2* :angle-vector  *look-left*)
(send *ri* :angle-vector (send *pr2* :angle-vector) 300 :larm-controller)
(send *ri* :wait-interpolation)
(ros::service-call "passthrough_points/request" (instance std_srvs::EmptyRequest :init))
(unix:usleep 300000)
)
|#
