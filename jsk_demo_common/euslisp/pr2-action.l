(setq *obj* (make-sphere 100)) ;; dummy object
(setq *target-name* nil)
(defparameter *detection-topic* "/openni/rgb/ObjectDetection")
(load "package://jsk_perception/euslisp/detection_interface.l")

;;
;; action-utility
;;
(defun open-fridge-traj (hand handle &optional (rad/length pi/2) &rest args
                         &key (radius 500) (path-div 20) (door-type :circle) &allow-other-keys)
  (let ((cds-traj
         (case door-type
           (:circle
            (open-fridge-circle-traj handle rad/length :radius radius :path-div path-div))
           (:slide
            (open-fridge-slide-traj handle rad/length :path-div path-div))
           )))
    (apply #'move-fridge-traj hand cds-traj args)
    ))
(defun open-fridge-slide-traj
  (handle &optional (path-length 200)
          &key  (path-div 20) (pre-start-x -100) (start-x 25)
          &allow-other-keys)
  (let ((tcds (send (send handle :copy-worldcoords) :translate (float-vector (- path-length) 0 0)))
        ret)
    (setq ret (generate-slide-path (send handle :worldpos)
                                   (send handle :worldpos) (send tcds :worldpos)
                                   path-length :div path-div))
    (mapc #'(lambda (x) (send x :rotate pi/2 :x)) ret)
    (setq *ret*
          (append (list (send (send (car ret) :copy-worldcoords)
                              :translate (float-vector pre-start-x 0 0) :local)
                        (send (send (car ret) :copy-worldcoords)
                              :translate (float-vector start-x 0 0) :local))
                  ret))
    ;; stop grasp
    ;; move (elt ret 0)
    ;; move (elt ret 1)
    ;; start grap
    ;; grasp check
    ;; move-trajectory (subseq ret 2)
    ;; finalize
    *ret*))
(defun open-fridge-circle-traj
  (handle &optional (rad pi/2)
          &key (radius 500) (path-div 20) (pre-start-x -100) (start-x 25))
  ;; 500mm is a distance between handle and axis
  (let ((acds (send (send handle :copy-worldcoords) :translate (float-vector 0 (- radius) 200)))
        (bcds (send (send handle :copy-worldcoords) :translate (float-vector 0 (- radius) -200)))
        (di -pi/2) ret)
    (setq ret (generate-circle-path (send handle :worldpos)
                                    (send acds :worldpos) (send bcds :worldpos)
                                    rad :div path-div));;a,b can be reverse
    (mapc #'(lambda (x) (send x :rotate -pi/2 :x)) ret)
    (setq *ret*
          (append (list (send (send (car ret) :copy-worldcoords)
                              :translate (float-vector pre-start-x 0 0) :local)
                        (send (send (car ret) :copy-worldcoords)
                              :translate (float-vector start-x 0 0) :local))
                  ret))
    ;; stop grasp
    ;; move (elt ret 0)
    ;; move (elt ret 1)
    ;; start grap
    ;; grasp check
    ;; move-trajectory (subseq ret 2)
    ;; finalize
    *ret*))
(defun move-fridge-traj (hand cds-traj
                              &key ((:rotation-axis ra) :z) (use-torso 0.0025)
                              (fix-waist-z 150) (return-sequence) (time-tick 300) (wait-time 4)
                              (grasp-check t)  (move-robot t) (start-sec 1000) &allow-other-keys)
  (let ((st0 (car cds-traj))
        (st1 (cadr cds-traj))
        (lst (cddr cds-traj))
        avs tms)
    (when move-robot  ;; open-gripper
      (send *ri* :move-gripper hand 0.09 :wait nil))
    (when fix-waist-z
      (unless (numberp fix-waist-z) (setq fix-waist-z 130))
      (send *pr2* :torso :waist-z :joint-angle fix-waist-z))
    (cond
     ((move-arm hand st0
                :use-torso (if use-torso (/ use-torso 5))
                :rotation-axis t :sec start-sec :move-robot move-robot)
      t)
     (t
      (ros::ros-warn "Could not solve ik, return from execute-open")
      (return-from move-fridge-traj nil)))

    (move-arm hand st1
              :use-torso (if use-torso (/ use-torso 5))
              :rotation-axis t :sec start-sec :move-robot move-robot)

    (let ((grasp-ret (if move-robot (send *ri* :start-grasp hand :gain 0.1) 10)))
      (when (and grasp-check
                 (< grasp-ret 8)) ;; grasp
        (ros::ros-warn "Grasp handle failed, return from execute-open")
        (return-from move-fridge-traj nil)))

    (dolist (rr lst)
      (let ((ik-solved
             (send *pr2* :inverse-kinematics
                   (send rr :worldcoords)
                   :use-torso use-torso
                   :move-arm hand :rotation-axis ra :debug-view nil :warnp nil)))
        (unless (or ik-solved (eq ra nil))
          (warn ";; retry ~A~%" rr);
          (setq ik-solved
                (send *pr2* :inverse-kinematics
                      (send rr :copy-worldcoords)
                      :use-torso use-torso
                      :move-arm hand :rotation-axis nil :debug-view nil :warnp nil)))
        (unless ik-solved (warn ";; failed ~A~%" rr))
        (when ik-solved
          (push (send *pr2* :angle-vector) avs)
          (push time-tick tms))
        ))
    (when return-sequence
      (return-from move-fridge-traj (list (reverse avs) tms)))

    (when move-robot
      (send *ri* :angle-vector-sequence (reverse avs) tms))
    ;; finalize
    (cond
     ((integerp wait-time)
      (unix:sleep wait-time))
     ((numberp wait-time)
      (unix::usleep
       (round (* wait-time 1000 1000))))
     (wait-time
      (send *ri* :wait-interpolation)))
    (send *ri* :stop-grasp hand)
    (send *ri* :wait-interpolation)
    ;;
    (unix::sleep 1) (ros::spin-once)
    (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
    (let ((end-pt (send *pr2* hand :end-coords :worldpos))
          idx)
      (setq idx (position (find-extream lst #'(lambda(x) (distance (send x :worldpos) end-pt)) #'<) lst))
      (ros::ros-info "idx = [~a/~a]" idx (length lst))
      (when (< idx (/ (length lst) 2))
        (return-from open-fridge-traj nil)))
    t))

;;
;; actions
;;
(warn ";; define grasp-can-single")
(defun grasp-can-single (obj &key (rotation 0))
  (let (via1 via2 tar orig-av)
    (send *ri* :stop-grasp :rarm)
    (send *tfb* :send-transform
          obj "/base_footprint" "/objecta_pose_frame")
    (setq orig-av (send *ri* :state :potentio-vector))

    (when *use-arm-navigation*
      (dotimes (i 5)
        (send *plan-env* :get-planning-scene)
        ;; (unix::usleep (* 400 1000))
        ))

    (setq tar (send obj :copy-worldcoords))
    (send tar :orient 0 :z :world)

    (setq via1 (send tar :copy-worldcoords))
    (send via1 :translate (float-vector (* (cos (deg2rad rotation)) -100)
                                        (* (sin (deg2rad rotation))  100) 0) :world)

    ;; via2
    (setq via2 (send tar :copy-worldcoords))
    (send via2 :translate (float-vector 30 0 0) :world)

    ;; publish tf
    (send *tfb* :send-transform
          via1 "/base_footprint" "/objecta_pose_frame_via1")
    ;;(send *tfb* :send-transform
    ;;via2 "/base_footprint" "/objecta_pose_frame_via2")
    (send *tfb* :send-transform
          via2 "/base_footprint" "/objecta_pose_frame_via2")

    ;; move to via1
    (send *pr2* :rarm :inverse-kinematics via1 :rotation-axis t :use-torso t)
    (send *tfb* :send-transform
          (send *pr2* :rarm :end-coords)  "/base_footprint" "/objecta_pose_end_coords")

    ;;(send *ri* :angle-vector (send *pr2* :angle-vector))
    ;;(send *ri* :wait-interpolation))
    ;; check IK

    (cond
     ((null *use-arm-navigation*)
      (send *ri* :angle-vector (send *pr2* :angle-vector))
      (send *ri* :wait-interpolation))
     ((send *plan-env* :get-ik-for-pose (send *plan-env* :get-robot-coords :rarm) :rarm)
      (ros::ros-warn ";; can not solve collision free IK")
      (send *ri* :angle-vector (send *pr2* :angle-vector))
      (send *ri* :wait-interpolation))
     (t
      (when (send *plan-env* :planning-move-arm :rarm :planning-time 4.0)
        (ros::ros-warn ";; can not solve collision free Plan")
        (send *ri* :angle-vector (send *pr2* :angle-vector))
        (send *ri* :wait-interpolation))
      ))

    ;; move to via2 (grasping pose)
    (send *pr2* :rarm :inverse-kinematics via2 :rotation-axis t :use-torso t)
    ;; check IK
    #|(cond
    ((send *plan-env* :get-ik-for-pose (send *plan-env* :get-robot-coords :rarm) :rarm)
    (ros::ros-warn ";; can not solve collision free IK")
    ;; move to via1
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation))
    (t
    (when (send *plan-env* :planning-move-arm :rarm :planning-time 4.0)
    (ros::ros-warn ";; can not solve collision free Plan")
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation))
    ))|#
    (send *ri* :angle-vector (send *pr2* :angle-vector))
    (send *ri* :wait-interpolation)

    ;; grasp
    (send *ri* :start-grasp :rarm)

    ;; move to via1
    (send *pr2* :rarm :inverse-kinematics via1 :rotation-axis t :use-torso t)
    ;; check IK
    (cond
     ((null *use-arm-navigation*)
      (send *ri* :angle-vector (send *pr2* :angle-vector))
      (send *ri* :wait-interpolation))
     ((send *plan-env* :get-ik-for-pose (send *plan-env* :get-robot-coords :rarm) :rarm)
      (ros::ros-warn ";; can not solve collision free IK")
      ;; move to via1
      (send *ri* :angle-vector (send *pr2* :angle-vector))
      (send *ri* :wait-interpolation))
     (t
      (when (send *plan-env* :planning-move-arm :rarm :planning-time 4.0)
        (ros::ros-warn ";; can not solve collision free Plan")
        (send *ri* :angle-vector (send *pr2* :angle-vector))
        (send *ri* :wait-interpolation))
      ))
    ;;(send *ri* :angle-vector (send *pr2* :angle-vector))
    ;;(send *ri* :wait-interpolation)

    ;; move to original pose
    (send *ri* :angle-vector orig-av)
    (send *ri* :wait-interpolation)
    )
  )

(defun pr2-look-around (&key (time-tick 600) (show-wait 1200)
                             (yaw-angle-list (list 16 -16))
                             (pitch-angle-list (list 14 48))
                             (waist-z 140))
  (let ((last-angle (send *pr2* :angle-vector))
        (y-angle yaw-angle-list)
        (p-angle pitch-angle-list))
    (send *pr2* :head :angle-vector (float-vector (car y-angle) (car p-angle)))
    (send *pr2* :rarm :angle-vector #f(-80.0 74.0 -20.0 -120.0 -20.0 -30.0 180.0))
    (send *pr2* :larm :angle-vector #f(80.0 74.0 20.0 -120.0 20.0 -30.0 180.0))
    (send *pr2* :torso :angle-vector (float-vector waist-z))
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1400)
    (send *ri* :wait-interpolation)

    (dolist (ya y-angle)
      (dolist (pa p-angle)
        (send *pr2* :head :angle-vector (float-vector ya pa))
        (send *ri* :angle-vector (send *pr2* :angle-vector) time-tick)
        (send *ri* :wait-interpolation)
        (unix::usleep (round (* show-wait 1000)))
        )
      (setq p-angle (nreverse p-angle)))

    (send *pr2* :angle-vector last-angle)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1400)
    (send *ri* :wait-interpolation)
    ))

(warn ";; define open-fridge-door")
(defvar *fridge-distance-threshold* 25.0)
(defvar *fridge-rotation-threshold* 0.09)
(defun open-fridge-door (&key (open-fridge-func #'open-fridge-traj)
                              (door-type :circle) (look-around nil)) ;; :circle, :slide1, :slide2
  (let (ret
        (idealcds
        (case door-type
          (:circle
           (make-coords :pos (float-vector 790 100 0)
                        ;;(float-vector 775 100 0) ;;(float-vector 760 100 0)
                        :rpy (float-vector 0.05 0 0)))
          (:slide1
           (make-coords :pos (float-vector 780 100 0)
                        :rpy (float-vector 0.0 0 0)))
          (:slide2
           (make-coords :pos (float-vector 750 100 0)
                        :rpy (float-vector 0.0 0 0)))))
        (diffcds (make-coords :pos (float-vector 10000 10000 10000)))
        cds)
    ;; initial pose
    (case door-type
      (:circle
       (send *pr2* :head :angle-vector (float-vector 0 0))
       (send *pr2* :torso :angle-vector (float-vector 140))
       (send *ri* :angle-vector (send *pr2* :angle-vector))
       (send *ri* :wait-interpolation)
       )
      ((:slide1 :slide2)
       (send *pr2* :head :angle-vector (float-vector 0 0))
       (send *pr2* :torso :angle-vector (float-vector 140))
       (send *pr2* :larm :angle-vector (float-vector 25.0 74.0 35.0 -120.0 20.0 -30.0 0.0))
       (send *ri* :angle-vector (send *pr2* :angle-vector))
       (send *ri* :wait-interpolation)
       ))

    (dotimes (i 10 nil)
      ;; finding handle position
      (setq cds (check-detection :type "fridge" :speak-name "れいぞうこ"))
      ;; need detection fail check

      (when cds
        (send *obj* :reset-coords)
        (send *obj* :transform cds)
        (dump-structure *standard-output*
                        (list (send *pr2* :copy-worldcoords)
                              (send cds :copy-worldcoords)))
        (setq cds
              (make-coords :pos
                           (float-vector (elt (send cds :worldpos) 0)
                                         (elt (send cds :worldpos) 1) 0)
                           :rpy (list (elt (car (rpy-angle (send cds :worldrot))) 0)
                                      0 0)))

        (setq diffcds (send (send idealcds :inverse-transformation)
                            :transform (send cds :worldcoords) :world))

        (warn "~%~A -> ~A / ~A~%" diffcds cds idealcds)
        (ros::ros-info "DIFF: ~A" diffcds)
        (cond
         ((and (< (norm (float-vector (elt (send diffcds :worldpos) 0)
                                      (elt (send diffcds :worldpos) 1)))
                  *fridge-distance-threshold*)
               (< (abs (elt (car (rpy-angle (send diffcds :worldrot))) 0))
                  *fridge-rotation-threshold*))
          (setq cds (check-detection :type "fridge" :speak-name "れいぞうこ"))
          (ros::spin-once)
          (send *ri* :spin-once)
          ;; (y-or-n-p "Can I start open fridge? ")
          (when cds
            (if look-around (pr2-look-around))
            ;; for open fridge
            (case door-type
              (:circle
               (send *pr2* :head :angle-vector (float-vector 0 24))
               (send *ri* :angle-vector (send *pr2* :angle-vector) 600)
               (send *ri* :wait-interpolation)
               )
              ((:slide1 :slide2)
               (send *pr2* :head :angle-vector (float-vector 0 50))
               (send *ri* :angle-vector (send *pr2* :angle-vector) 600)
               (send *ri* :wait-interpolation)
               ))

            (setq cds
                  (make-coords :pos (send cds :worldpos)
                               :rpy (list (caar (send cds :rpy-angle)) 0 0)))
            (case door-type
              (:slide1
               (send cds :translate #f(0 -230 -355)))
              (:slide2
               (send cds :translate #f(0 -230 -675))))
            (setq *last-fridge-handle* cds)

            (case door-type
              (:circle
               (setq ret (funcall open-fridge-func
                                  :rarm cds 1.7 ;;(/ pi 2)
                                  :rotation-axis t :radius 490
                                  :time-tick 600 ;; 300
                                  :wait-time t ;; 6.0
                                  )))
              ((:slide1 :slide2)
               (setq ret (funcall open-fridge-func
                                  :rarm cds 320
                                  :rotation-axis t :door-type :slide
                                  :time-tick 500 ;; 200
                                  :wait-time t
                                  )))
              )
            (if ret (return)))
          (speak-jp "れいぞうこを あけられません でした")
          (send *pr2* :head :angle-vector (float-vector 0 0))
          (send *pr2* :torso :angle-vector (float-vector 140))
          (send *ri* :angle-vector (send *pr2* :angle-vector))
          (send *ri* :go-pos-unsafe -0.1 0 0)
          (send *ri* :wait-interpolation)
          )
         (t ;;  there is much difference
          (send *ri* :go-pos-unsafe
                (/ (elt (send diffcds :worldpos) 0) 1100.0)
                (/ (elt (send diffcds :worldpos) 1) 1100.0)
                (* 0.9 (rad2deg (elt (car (rpy-angle (send diffcds :worldrot))) 0))))
          ;; wait ???
          (unix::usleep (* 500 1000))
          ;; (send *ri* :wait-interpolation)
          ))
        ))

    (when (not ret)
      (ros::ros-info "TIMEOUT: open-fridge-door");;
      (speak-jp "れいぞうこ を みつけられません でした")
      (unix::sleep 2);;
      (return-from open-fridge-door nil))

    (ros::spin-once)
    (send *ri* :spin-once)
    (send *ri* :stop-grasp :rarm)
    (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

    (case door-type
      (:circle
       ;; free door handle
       (let ((rend (send *pr2* :rarm :end-coords :copy-worldcoords)))
         (send rend :translate (float-vector -100 -50 0) *pr2*)
         (send *pr2* :rarm :inverse-kinematics rend)
         (send *ri* :angle-vector (send *pr2* :angle-vector) 1000))

       ;; ?? open door ()
       (send *ri* :angle-vector-sequence
             (list (float-vector 50 5 74 100 -90 -70 -6 20 -70 50 -59 -43 118 0 0 -2 31) ;; 1500
                   (float-vector 50 5 74 100 -90 -70 -6 20 -0 60 -20 -45 118 -90 0 -2 31) ;; 1000
                   (float-vector 50 5 74 100 -90 -70 -6 20 12 45 -34 -110 12 -38 74 -2 31) ;; 1000
                   (float-vector 50 5 74 100 -90 -70 -6 20 -54.745 34.2625 -34.6956 -83.6538 24.9161 -66.3615 118.904 -2.0 31.0) ;; 4500
                   (float-vector 50 5 74 100 -90 -70 -6 20 -54.745 34.2625 -34.6956 -83.6538 24.9161 -66.3615 118.904 -2.0 31.0) ;; 1500 ;; just wait
                   (float-vector 150 5 74 100 -90 -70 -6 20 -7 45 -34 -110 12 -38 74 -2 31)) ;; 2000
             (list 1500 1000 1000 4500 1500 2000))
       (send *ri* :wait-interpolation)

       ;; (send *pr2* :angle-vector (float-vector 200 5.00529 74.2038 105.001 -90.0035 -70.0071 -5.73378 19.9988 9.96029 39.7801 -45.0972 -121.542 94.4262 -111.922 63.0666 -0.0316 21.024))
       (send *pr2* :angle-vector (float-vector 199.971 5.30455 72.1244 105.231 -88.5188 -69.9972 -5.72958 19.9717 24.6812 36.1934 10.6903 -121.497 159.113 -79.5111 -2.92658 -1.35562 26.862))
       (send *ri* :angle-vector (send *pr2* :angle-vector))
       )
      ((:slide1 :slide2)
       (let ((rend (send *pr2* :rarm :end-coords :copy-worldcoords))
             avs)
         ;; should be changed
         (send rend :translate (float-vector -40 -100 0) *pr2*)
         (send *pr2* :rarm :inverse-kinematics rend)
         (push (send *pr2* :angle-vector) avs)
         (send rend :translate (float-vector 0 0 100) *pr2*)
         (send *pr2* :rarm :inverse-kinematics rend)
         (push (send *pr2* :angle-vector) avs)
         (send *ri* :angle-vector-sequence (nreverse avs) (list 800 800))
         (send *ri* :wait-interpolation)
         (send *pr2* :rarm :angle-vector #f(-45.0 25.0 -65.0 -120.0 12.0 -38.0 74.0))
         (send *ri* :angle-vector (send *pr2* :angle-vector) 1600)
         ))
      )
    t
    ))

(warn ";; define grasp-can")
(defun grasp-can (&key (move t) (rotation))
  ;; move-to spot for grasping
  (ros::spin-once)
  (send *ri* :spin-once)
  (when move
    (ros::ros-info "GO POS UNSAFE for grasping can")
    (send *ri* :go-pos-unsafe 0 0 (rad2deg 0.38))
    (send *ri* :go-pos-unsafe 0.185 -0.25 0)
    (send *ri* :wait-interpolation))

  (ros::spin-once)
  (send *ri* :spin-once)
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (let (isgrasp)
    (dotimes (trial 10)
      ;; detect cans which was indicated by ( type )
      ;;(when (not (setq cds (check-detection :type *type* :single t)))
      ;;(setq cds (check-detection :type *type* :tf-force t :timeout 30 :single t)))
      (let (cds)
        (unless (setq cds (check-detection
                           :type *type* :tf-force t :timeout 35 :single t))
          (setq cds (check-detection
                     :type *type* :tf-force t :timeout 70 :single t)))
        (when cds
          ;; (speak-jp (format nil "~A を とりだします" *type*))
          (send *obj* :reset-coords)
          (send *obj* :transform cds)
          (warn ";; print check cans~%")
          (dump-structure *standard-output*
                          (list (send *pr2* :copy-worldcoords)
                                (send cds :copy-worldcoords)))
          (unless (boundp '*tfb*)
            (setq *tfb* (instance ros::transform-broadcaster :init)))
          (send *tfb* :send-transform
                cds "/base_footprint" "/object_pose_frame")
          (ros::spin-once)
          (send *ri* :spin-once)
          (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
          (unless rotation
            ;; FIXME: calc rotation from /map and /base_footprint
            (setq rotation 0))
          (grasp-can-single cds :rotation rotation)
          (setq isgrasp (< 10 (send *ri* :start-grasp :rarm)))
          (when isgrasp
            (when move (send *ri* :go-pos-unsafe -0.3 0.05 -20))
            (unix::sleep 1)
            (return-from grasp-can t))
          ;; (unix::sleep 2)
          (speak-jp "しっぱいしました  もういちど やって みます");;
          )
        )))
  (speak-jp (format nil "~A を とりだし ません でした" *type*))
  (when move (send *ri* :go-pos-unsafe -0.3 0.05 -20))
  (unix::sleep 1)
  nil)

(warn ";; define close-fridge")
(defun close-fridge ()
  ;; close the door of fridge
  (send *ri* :angle-vector-sequence
        (list (float-vector 250 5 74 100 -90 -70 -6 20 -13 50 -30 -25 118 -90 62 -2 31);; 2000
              (float-vector 200 5 74 100 -90 -70 -6 20 -50 54 -15 -43 118 -90 62 -2 31);; 1000
              (float-vector 150 5 74 100 -90 -70 -6 20 -80 10 -39 -33 -49 -32 89 -2 32);; 1500
              (float-vector 100 5 74 100 -90 -70 -6 20 -61 6 -74 -64 55 -75 102 -2 33);; 2500
              ;;(float-vector 50 5 74 100 -90 -70 -6 20 9.05631 26.4211 -42.0907 -111.215 97.6198 -19.5577 -24.0422 -2.0 33.0)
              (float-vector 50 5 74 100 -90 -70 -6 20 -1.74817 12.0099 -66.7541 -77.0519 67.3822 -49.1028 30.3261 -2.0 33.0))  ;; 3500
        (list 2000 1000 1500 1500 2500))
  (send *ri* :wait-interpolation)
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (pr2-tuckarm-pose :rarm)
  t
  )