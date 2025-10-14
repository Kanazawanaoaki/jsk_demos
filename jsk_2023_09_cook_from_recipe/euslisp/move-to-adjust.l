(unless (boundp '*obj*) (setq *obj* (make-sphere 100))) ;; dummy object
;; (require :pr2-pose "package://jsk_demo_common/euslisp/pr2-pose.l")
(require :pr2-speack "package://pr2eus/speak.l")
;; (require :pr2-interface "package://pr2eus/pr2-interface.l")
(require :pr2-cook-utils "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_utils.l")
(require :move-utils "package://jsk_2023_09_cook_from_recipe/euslisp/move-utils.l")

(defvar *use-voicetext* t)
(defvar *use-english* nil)
(defvar *use-cable* t)
(defvar *rarm-hold-object-flag* nil)
(defvar *larm-hold-object-flag* nil)

;; (if (and (boundp '*use-voicetext*) *use-voicetext*)
;;     (cond
;;      ((and (boundp '*use-english*) *use-english*)
;;       (setq *frige-speak-str* "the refrigerator"))
;;      (t (setq *frige-speak-str* "冷蔵庫")))
;;   (setq *frige-speak-str* "れいぞうこ"))

(unless (boundp '*stove-offset-cds*) (setq *stove-offset-cds* (make-coords)))
(unless (boundp '*kitchen-offset-cds*) (setq *kitchen-offset-cds* (make-coords)))
(unless (boundp '*sink-offset-cds*) (setq *sink-offset-cds* (make-coords)))
(unless (boundp '*counter-offset-cds*) (setq *counter-offset-cds* (make-coords)))

(defun adjust-cds-with-spot (ik-target spot-name)
  (let (ik-target-adj)
    (cond
     ((string= spot-name "stove")
      (setq ik-target-adj (set-offset-cds ik-target *stove-offset-cds*))
      )
     ((string= spot-name "sink")
      (setq ik-target-adj (set-offset-cds ik-target *sink-offset-cds*))
      )
     ((string= spot-name "kitchen")
      (setq ik-target-adj (set-offset-cds ik-target *kitchen-offset-cds*))
      )
     ((string= spot-name "counter")
      (setq ik-target-adj (set-offset-cds ik-target *counter-offset-cds*))
      )
     (t
      (format t "spot-name ~A is not defined !!!~%" spot-name)
      (return-from adjust-cds-with-spot nil)
      )
     )
    (print ik-target-adj)
    ik-target-adj))

(defun dump-spot-offset ()
  (let ((dir_path)
        (file_path))
    (setq dir_path (ros::resolve-ros-path "package://jsk_2023_09_cook_from_recipe/datas/eus-spot-offset"))
    (setq file_path (format nil "~A/eus-spot-offset.l" dir_path))
    (dump-loadable-structure file_path *stove-offset-cds* *kitchen-offset-cds* *sink-offset-cds* *counter-offset-cds*)
    (format t "adj coords is saved in ~A ~%" file_path)
    ))

(defun reset-spot-offset-file ()
  (let ((dir_path)
        (file_path))
    (setq dir_path (ros::resolve-ros-path "package://jsk_2023_09_cook_from_recipe/datas/eus-spot-offset"))
    (setq file_path (format nil "~A/eus-spot-offset.l" dir_path))
    (setq *stove-offset-cds* (make-coords))
    (setq *kitchen-offset-cds* (make-coords))
    (setq *sink-offset-cds* (make-coords))
    (setq *counter-offset-cds* (make-coords))
    (dump-loadable-structure file_path *stove-offset-cds* *kitchen-offset-cds* *sink-offset-cds* *counter-offset-cds*)
    (format t "adj coords is saved in ~A ~%" file_path)
    ))

(defun load-spot-offset ()
  (let ((dir_path)
        (file_path))
    (setq dir_path (ros::resolve-ros-path "package://jsk_2023_09_cook_from_recipe/datas/eus-spot-offset"))
    (setq file_path (format nil "~A/eus-spot-offset.l" dir_path))
    (if (probe-file file_path) ;; check file is exist
        (load file_path)
      (progn
        (format t "file ~A is not exist! So return nil. ~%" file_path)
        (return-from load-spot-offset nil)
        )
      )
    (format t "adj coords is load from ~A ~%" file_path)
    (format t "*stove-offset-cds* : ~A ~%" *stove-offset-cds*)
    (format t "*kitchen-offset-cds* : ~A ~%" *kitchen-offset-cds*)
    (format t "*sink-offset-cds* : ~A ~%" *sink-offset-cds*)
    (format t "*counter-offset-cds* : ~A ~%" *counter-offset-cds*)
    ;; original (setq *stove-offset-cds* '#s(coordinates plist nil rot #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0)) pos #f(0.0 0.0 0.0)))
    ))


;; tmp check
(defun check-stove-spot (&key (use-cds-offset nil))
  ;; (reset-manip-pose)
  (reset-cook-pose)

  ;; pre-set-av  ;; from cut-and-stir/pr2-cooking-actions-funcs.l ih-stove-action
  (send *pr2* :rarm :angle-vector #f(-51.7423 64.9578 -95.8258 -91.4896 117.771 -46.7522 -2.78394))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :rarm :wait t)
  (let ((ik-target (make-coords :pos #f(645.029 -178.873 696.789) :rpy #f(-0.089 0.092 3.019)))
        ik-target-adj
        (push-length 10)
        (pre-set-val (float-vector -30 0 0))
        )
    (if use-cds-offset
        (setq ik-target-adj (set-offset-cds ik-target *stove-offset-cds*))
      (setq ik-target-adj (send ik-target :copy-worldcoords)))
    (print ik-target-adj)
    (send ik-target-adj :translate (float-vector push-length 0 0) :local)

    ;; pre-pose
    (send ik-target-adj :translate pre-set-val :local)
    (send *pr2* :rarm :inverse-kinematics
          ik-target-adj
          :rotation-axis t
          :revert-if-fail nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)

    ;; push
    (send ik-target-adj :translate (scale -1 pre-set-val) :local)
    (send *pr2* :rarm :inverse-kinematics
          ik-target-adj
          :rotation-axis t
          :revert-if-fail nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)

    ;; return
    (send ik-target-adj :translate pre-set-val :local)
    (send *pr2* :rarm :inverse-kinematics
          ik-target-adj
          :rotation-axis t
          :revert-if-fail nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)

    (send *ri* :stop-grasp :rarm :wait t)

    ;; grasp
    (send ik-target-adj :translate (float-vector (- push-length) 0 0) :local)
    (send ik-target-adj :translate (scale -1 pre-set-val) :local)
    (send *pr2* :rarm :inverse-kinematics
          ik-target-adj
          :rotation-axis t
          :revert-if-fail nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)

    (send *ri* :start-grasp :rarm :wait t)

    ;; rotate
    (send ik-target-adj :rotate (deg2rad 30) :x)
    (send *pr2* :rarm :inverse-kinematics
          ik-target-adj
          :rotation-axis t
          :revert-if-fail nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
    (send *ri* :wait-interpolation)

    (send *ri* :stop-grasp :rarm :wait t)

    (send ik-target-adj :translate pre-set-val :local)
    (send *pr2* :rarm :inverse-kinematics
          ik-target-adj
          :rotation-axis t
          :revert-if-fail nil)
    (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
    (send *ri* :wait-interpolation)
    )

  (send *pr2* :rarm :angle-vector #f(-51.7423 64.9578 -95.8258 -91.4896 117.771 -46.7522 -2.78394))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  ;; (reset-manip-pose)
  (reset-cook-pose)
  )

(defun check-kitchen-spot ()
  ;; (reset-manip-pose :arm :larm :time 2000)
  ;; (reset-manip-pose :arm :rarm :time 2000)
  (reset-cook-pose :arm :larm :time 2000)
  (reset-cook-pose :arm :rarm :time 2000)

  (send *pr2* :rarm :angle-vector #f(-57.5199 62.5833 -57.6647 -117.726 -171.269 -49.5124 107.99))
  (send *pr2* :larm :angle-vector #f(32.6942 52.7237 80.3627 -117.552 -144.824 -70.7049 209.82))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (format t "wait ok !! ~%")
  (ok-wait)

  (reset-cook-pose :arm :larm :time 2000)
  (reset-cook-pose :arm :rarm :time 2000)
  (reset-pose)
  )


(defun check-sink-spot ()
  (reset-manip-pose :arm :larm :time 2000)
  (reset-manip-pose :arm :rarm :time 2000)

  (send *pr2* :rarm :angle-vector #f(-32.5563 22.3727 -103.121 -112.907 109.776 -5.72958 229.4))
  ;; (send *pr2* :larm :angle-vector #f(92.4848 41.8099 73.9639 -90.2619 -295.046 -15.2736 153.803))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (format t "wait ok !! ~%")
  (ok-wait)

  (reset-manip-pose :arm :larm :time 2000)
  (reset-manip-pose :arm :rarm :time 2000)
  (reset-pose)
  )

(defun move-to-spot (to &key (use-k4a t) (after-cable-check t))
  (let ((move-suc-flag nil)
        (adjust-suc-flag nil))
    ;; move-to start
    (send *ri* :clear-costmap)
    (if (equal *larm-hold-object-flag* nil)
        (progn
          (send *pr2* :larm :angle-vector (get-tuckarm :rarm :inside :larm))
          (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
          (send *ri* :wait-interpolation)
          ))
    (reset-move-pose :head-p 0.0 :torso 50.0 :tm 3000)
    ;; cable wait
    (speech-before-move-with-rec)
    (until move-suc-flag
           (cond
            ((string= to "stove")
             (print "move-to stove")
             ;; (setq move-suc-flag (send *ri* :move-to (make-coords :pos #f(1200 8100 30000) :rpy (float-vector pi 0 0)) :frame-id "/map"))
             ;; (setq move-suc-flag (send *ri* :move-to (make-coords :pos #f(1200 8070 30000) :rpy (float-vector pi 0 0)) :frame-id "/map"))
             (setq move-suc-flag (send *ri* :move-to (make-coords :pos #f(1300 7970 351) :rpy (float-vector pi 0 0)) :frame-id "/map"))
             (when move-suc-flag ;; 移動が成功したら
               (setq adjust-suc-flag nil)
               (reset-move-pose :head-p 0.0 :torso 50.0 :tm 1000)
               (until adjust-suc-flag
                      ;; (reset-pose)
                      (reset-move-pose :head-p 0.0 :torso 50.0 :tm 1000)
                      (format t "pr2 reset-pose ~%")
                      ;; (setq adjust-suc-flag (move-with-adjust :move-spot :stove :use-k4a use-k4a))
                      (setq adjust-suc-flag (move-with-adjust :move-spot :stove :use-k4a use-k4a :rec-num 1))
                      )
               ))
            ((string= to "kitchen")
             (print "move-to kitchen")
             ;; (setq move-suc-flag (send *ri* :move-to (make-coords :pos #f(1200 8500 30000) :rpy (float-vector pi 0 0)) :frame-id "/map"))
             (setq move-suc-flag (send *ri* :move-to (make-coords :pos #f(1200 8600 30000) :rpy (float-vector pi 0 0)) :frame-id "/map"))
             (when move-suc-flag
               (setq adjust-suc-flag nil)
               (reset-move-pose :head-p 0.0 :torso 50.0 :tm 1000)
               (until adjust-suc-flag
                      (reset-move-pose :head-p 0.0 :torso 50.0 :tm 1000)
                      (format t "pr2 reset-pose ~%")
                      ;; (setq adjust-suc-flag (move-with-adjust :move-spot :kitchen :use-k4a use-k4a))
                      (setq adjust-suc-flag (move-with-adjust :move-spot :kitchen :use-k4a use-k4a :rec-num 1))
                      )
               ))
            ((string= to "sink")
             (print "move-to sink")
             (setq move-suc-flag (send *ri* :move-to (make-coords :pos #f(1110 9100 30000) :rpy (float-vector pi 0 0)) :frame-id "/map"))
             (when move-suc-flag
               (setq adjust-suc-flag nil)
               (reset-move-pose :head-p 0.0 :torso 50.0 :tm 1000)
               (until adjust-suc-flag
                      (reset-move-pose :head-p 0.0 :torso 50.0 :tm 1000)
                      (format t "pr2 reset-pose ~%")
                      ;; (setq adjust-suc-flag (move-with-adjust :move-spot :sink :use-k4a use-k4a))
                      (setq adjust-suc-flag (move-with-adjust :move-spot :sink :use-k4a use-k4a :rec-num 1))
                      )
               ))
            ((string= to "counter")
             (print "move-to counter")
             (setq move-suc-flag (send *ri* :move-to (make-coords :pos #f(2010 8800 30000) :rpy (float-vector 0 0 0)) :frame-id "/map"))
             (when move-suc-flag
               (setq adjust-suc-flag nil)
               ;; (reset-move-pose :head-p 50.0 :torso 200.0 :tm 1000);; (reset-move-pose :head-p 50.0 :torso 150.0 :tm 1000)
               (reset-move-pose :head-p 50.0 :torso 325.0 :tm 1000)
               (until adjust-suc-flag
                      ;; (reset-move-pose :head-p 50.0 :torso 200.0 :tm 1000)
                      (reset-move-pose :head-p 50.0 :torso 325.0 :tm 1000)
                      (format t "pr2 reset-pose ~%")
                      ;; (setq adjust-suc-flag (move-with-adjust :move-spot :counter :use-k4a use-k4a :rec-num 3))
                      (setq adjust-suc-flag (move-with-adjust :move-spot :counter :use-k4a use-k4a :rec-num 1))
                      )
               ))
            )
           (format t "move-to result ~A ~%" move-suc-flag)
           (if move-suc-flag
               (progn
                 (if (and after-cable-check *use-cable*)
                     (speech-after-move-with-rec)
                   )
                 )
             (progn
               (speak-with-log "移動に失敗しました．アシストして下さい")
               (print "wait for key pressed (after move fail)")
               (do-until-key
                (unix:usleep 100000)
                ))
             )
           )
    move-suc-flag))


;; c.f. https://github.com/jsk-ros-pkg/jsk_demos/blob/088b186ea8d02ebda8fee2dc411135f8fd813be1/jsk_demo_common/euslisp/pr2-action.l#L708-L856
(defparameter *adjust-spot-object-cds* nil)

(defun calc-diffcds (idealcds rec-cds distance-threshold rotation-threshold)
  (let ((diffcds))
    (setq diffcds (send (send idealcds :inverse-transformation)
                        :transform (send rec-cds :worldcoords) :world))

    (warn "~%~A -> ~A / ~A~%" diffcds rec-cds idealcds)
    (ros::ros-info "DIFF: ~A" diffcds)
    (ros::ros-info "DIFF distrance: ~A, distance-threshold: ~A" (norm (float-vector (elt (send diffcds :worldpos) 0)
                                                                                    (elt (send diffcds :worldpos) 1)))
                   distance-threshold)
    (ros::ros-info "DIFF rotation: ~A, rotation-threshold: ~A" (abs (elt (car (rpy-angle (send diffcds :worldrot))) 0))
                   rotation-threshold)
    diffcds))

(defun move-with-adjust (&key (move-spot :stove) (ratio 1) (look-around nil) (head-pitch 14) (torso-lift 130) (move t) (wait t) (use-base nil) (use-k4a t) (rec-num 5))
  (let ((ret nil)
        (distance-threshold 20.0) ;;25.0
        (rotation-threshold 0.09) ;;0.09
        idealcds
        diffcds
        spot-name
        speak-name
        detection-topic
        trans-flag
        cam-cds
        cds
        )
    (setq diffcds (make-coords :pos (float-vector 10000 10000 10000)))
    (setq trans-flag nil)
    ;; finding adjust spot object
    (case move-spot
          (:stove
           (setq spot-name "stove")
           (setq speak-name "IHコンロ")
           (setq detection-topic "/point_pose_stove/ObjectDetection")
           (if use-k4a
               (progn
                 ;; (setq idealcds ;; for k4a
                 ;;       (make-coords :pos (float-vector 1288.043 106.543 1481.986)
                 ;;                    :rpy (float-vector 2.873 1.538 -0.192)))
                 ;; (setq idealcds ;; for femto mega v1
                 ;;       (make-coords :pos (float-vector 1261.166 167.382 1381.361)
                 ;;                    :rpy (float-vector -0.041 1.547 3.118)))
                 ;; (setq idealcds ;; for femto mega v2
                 ;;       (make-coords :pos (float-vector 1298.364 111.351 1386.061)
                 ;;                    :rpy (float-vector -3.085 1.508 0.21)))
                 ;; (setq idealcds ;; for femto mega 20250224 calib v3 staight
                 ;;       (make-coords :pos (float-vector 1377.415 184.07 1430.816)
                 ;;                    :rpy (float-vector 1.416 1.555 -1.706)))
                 (setq idealcds ;; for femto mega 20250224 calib use mega image
                       (make-coords :pos (float-vector 1323.683 137.666 1433.521)
                                    :rpy (float-vector 2.833 1.545 -0.137)))
                 )
             (setq idealcds ;; for kinect
                   (make-coords :pos (float-vector 1145.287 325.273 1420.734)
                                :rpy (float-vector 0.248 1.435 -2.965)))
             )
           )
          (:kitchen
           (setq spot-name "kitchen")
           (setq speak-name "キッチン")
           (setq detection-topic "/point_pose_kitchen/ObjectDetection")
           (if use-k4a
               (progn
                 ;; (setq idealcds ;; for k4a
                 ;;       (make-coords :pos (float-vector 1146.088 237.191 1356.95)
                 ;;                    :rpy (float-vector 3.098 1.549 0.026)))
                 (setq idealcds ;; for femto mega
                       (make-coords :pos (float-vector 1160.804 229.486 1310.694)
                                    :rpy (float-vector 0.266 1.508 -2.903)))
                 )
             (setq idealcds ;; for kinect
                   (make-coords :pos (float-vector 1163.785 266.85 1284.483)
                                :rpy (float-vector 0.167 1.403 -3.019)))
             )
           )
          (:sink
           (setq spot-name "sink")
           (setq speak-name "水道")
           (setq detection-topic "/point_pose_sink/ObjectDetection")
           (if use-k4a
               (setq idealcds ;; for k4a
                     (make-coords :pos (float-vector 1099.015 102.449 1329.082)
                                  :rpy (float-vector 0.075 1.508 -3.061)))
             (setq idealcds ;; for kinect
                   (make-coords :pos (float-vector 1031.396 137.734 1282.394)
                                :rpy (float-vector 0.258 1.499 -2.909)))
             )
           )
          (:counter
           (setq spot-name "counter")
           (setq speak-name "カウンター")
           (setq detection-topic "/point_pose_counter/ObjectDetection")
           (if use-k4a
               (progn
                 ;; (setq idealcds ;; for k4a torso 200
                 ;;       (make-coords :pos (float-vector 985.366 496.913 872.82);; 1005.771 485.175 864.579
                 ;;                    :rpy (float-vector -3.101 0.022 0.003)));; -3.128 0.017 -0.005
                 (setq idealcds ;; for k4a torso 325
                       (make-coords :pos (float-vector 1008.441 489.445 869.754)
                                    :rpy (float-vector -3.103 0.019 0.001)))
                 )
             (setq idealcds ;; for kinect ;; todo
                   (make-coords :pos (float-vector 1031.396 137.734 1282.394)
                                :rpy (float-vector 0.258 1.499 -2.909)))
             )
           )
          )
    (cond
     ((not (send *ri* :simulation-modep)) ;; real mode
      (if use-k4a
          (progn
            ;; (unless (boundp '*tfl*)
            ;;   (setq *tfl* (instance ros::transform-listener :init)))
            ;; (setq trans nil)
            ;; (until trans
            ;;        (setq pp_msg (one-shot-subscribe detection-topic posedetection_msgs::ObjectDetection))
            ;;        (setq trans (send *tfl* :lookup-transform *base-frame-id* (send pp_msg :header :frame_id) (send pp_msg :header :stamp)))
            ;;        )
            ;; (setq cds (make-coords))
            ;; (send cds :move-to trans :local)
            ;; (send cds :move-to (ros::tf-pose->coords (send (car (send pp_msg :objects)) :pose)) :local)
            ;; (setq cds (k4a-check-detection detection-topic :rec-num rec-num :use-out-filter t :filter-thre 50))
            (setq cds (k4a-check-detection detection-topic :rec-num rec-num :use-out-filter nil))
            )
        (setq cds (check-detection :type spot-name :speak-name speak-name
                                   :detection-topic detection-topic
                                   )))
      )
     (t ;; simulation mode
      (setq cds (send (make-cube 60 60 60) :translate (float-vector 777 98 1112))) ;; TODO
      ))
    (setq *adjust-spot-object-cds* cds)
    ;; need detection fail check
    (send *ri* :ros-wait 0.0 :spin-self t) ;; attention-check ...
    (when cds
      (send *obj* :reset-coords)
      (send *obj* :transform cds)
      (dump-structure *standard-output*
                      (list (send *pr2* :copy-worldcoords)
                            (send cds :copy-worldcoords)))

      ;; (when trans-flag ;; k4a-check-detectionの中で行われているので要らない
      ;;   (setq cam-cds (get-tf-coords "femto_mega_color_optical_frame" :base-frame "base_footprint"))
      ;;   (setq idealcds (calc-target-from-base-rel cam-cds idealcds))
      ;;   (setq cds (calc-target-from-base-rel cam-cds cds))
      ;;   )

      (setq diffcds (calc-diffcds idealcds cds distance-threshold rotation-threshold))

      (cond
       ((or (send *ri* :simulation-modep) ;;if in simulation mode, execute
            (and (< (norm (float-vector (elt (send diffcds :worldpos) 0)
                                        (elt (send diffcds :worldpos) 1)))
                    distance-threshold)
                 (< (abs (elt (car (rpy-angle (send diffcds :worldrot))) 0))
                    rotation-threshold)))
        (setq ret t)
        (load-spot-offset) ;; load current offset setting
        (case move-spot
              (:stove
               (setq *stove-offset-cds* (make-coords :pos (float-vector (elt (send diffcds :worldpos) 0) (elt (send diffcds :worldpos) 1) 0)
                                                     :rpy (float-vector (elt (car (rpy-angle (send diffcds :worldrot))) 0) 0 0)))
               )
              (:kitchen
               (setq *kitchen-offset-cds* (make-coords :pos (float-vector (elt (send diffcds :worldpos) 0) (elt (send diffcds :worldpos) 1) 0)
                                                       :rpy (float-vector (elt (car (rpy-angle (send diffcds :worldrot))) 0) 0 0)))
               )
              (:sink
               (setq *sink-offset-cds* (make-coords :pos (float-vector (elt (send diffcds :worldpos) 0) (elt (send diffcds :worldpos) 1) 0)
                                                    :rpy (float-vector (elt (car (rpy-angle (send diffcds :worldrot))) 0) 0 0)))
               )
              (:counter
               (setq *counter-offset-cds* (make-coords :pos (float-vector (elt (send diffcds :worldpos) 0) (elt (send diffcds :worldpos) 1) 0)
                                                       :rpy (float-vector (elt (car (rpy-angle (send diffcds :worldrot))) 0) 0 0)))
               )
              )
        (if (not (send *ri* :simulation-modep)) ;; real mode
            (progn
              (speak-jp "到着しました")
              (dump-spot-offset)
              )
          ))
       (t ;;  there is much difference
        (if move
            (cond
             (wait
              (send *ri* :go-pos-unsafe
                    (/ (elt (send diffcds :worldpos) 0) 1100.0)
                    (/ (elt (send diffcds :worldpos) 1) 1100.0)
                    (* 0.9 (rad2deg (elt (car (rpy-angle (send diffcds :worldrot))) 0))))
              ;; (setq move-adjust-x (- (elt (send cds :worldpos) 0) (elt (send idealcds :worldpos) 0)))
              ;; (setq move-adjust-y (- (elt (send cds :worldpos) 1) (elt (send idealcds :worldpos) 1)))
              ;; ;; (setq move-adjust-theta
              ;; ;;       (rad2deg (elt (car (rpy-angle (send diffcds :worldrot))) 0)))
              ;; (setq move-adjust-theta
              ;;       (- (rad2deg (car (car (rpy-angle (send cds :worldrot))))) (rad2deg (car (car (rpy-angle (send idealcds :worldrot)))))))
              ;; (warn "~A, ~A, ~A ~%" move-adjust-x move-adjust-y move-adjust-theta)
              ;; (send *ri* :go-pos-unsafe-no-wait
              ;;       (/ move-adjust-x 1100.0)
              ;;       (/ move-adjust-y 1100.0)
              ;;       (* 0.9 move-adjust-theta))

              ;; wait ???
              (send *ri* :ros-wait 0.5 :spin-self t :spin t) ;; attention-check ...
              ;; (send *ri* :wait-interpolation)
              )
             (t
              (send *ri* :go-pos-unsafe-no-wait
                    (/ (elt (send diffcds :worldpos) 0) 1100.0)
                    (/ (elt (send diffcds :worldpos) 1) 1100.0)
                    (* 0.9 (rad2deg (elt (car (rpy-angle (send diffcds :worldrot))) 0))))

              ;; (setq move-adjust-x (- (elt (send cds :worldpos) 0) (elt (send idealcds :worldpos) 0)))
              ;; (setq move-adjust-y (- (elt (send cds :worldpos) 1) (elt (send idealcds :worldpos) 1)))
              ;; ;; (setq move-adjust-theta
              ;; ;;       (rad2deg (elt (car (rpy-angle (send diffcds :worldrot))) 0)))
              ;; (setq move-adjust-theta
              ;;       (- (rad2deg (car (car (rpy-angle (send idealcds :worldrot))))) (rad2deg (car (car (rpy-angle (send cds :worldrot)))))))
              ;; (warn "~A, ~A, ~A," )
              ;; (send *ri* :go-pos-unsafe-no-wait
              ;;       (/ move-adjust-x 1100.0)
              ;;       (/ move-adjust-y 1100.0)
              ;;       (* 0.9 move-adjust-theta))
              ;; ))
              )
             ))
        )
       )
      ) ;; /when cds
    ret
    ))
