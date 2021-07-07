(defun init ()
  (if (not (boundp '*room*))
      (progn
        (load "../../model/my-room73b2-scene.l")
        (setq *room* (room73b2))
        ))
    
  (if (not (boundp '*kitchen*))
      (progn 
        (load "models/room73b2-kitchen-object.l")
        (setq *kitchen* (room73b2-kitchen))
        (send *kitchen* :transform (make-coords :pos (float-vector 305.0 2175.0 20.0) :rot #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))))
        ))

  (if (not (boundp '*pr2*))
      (progn
        (load "package://pr2eus/pr2-interface.l")
        (pr2-init)
        ))

  ;; set まな板
  (load "../../model/cutting-board.l")
  (setq *cutting-board* (cutting-board))
  (send *cutting-board* :transform (make-coords :pos (float-vector 500.0 2000.0 840.0) :rot #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))))

  ;; set objects
  (load "../../model/peeler.l")
  (load "../../model/potato-peeler.l")
  (load "../../model/knife-new-attention.l")
  (load "models/arrow-object.l")
  (setq *arrow* (arrow))

  ;; set spots
  (setq *cook-spot* (send *room73b2* :spot "cook-spot"))
  (setq *sink-spot* (make-coords :pos #f(1055 2600 0) :rpy #f(3.14 0 0))) 
  (setq *kitchen-spot* (send *room73b2* :spot "kitchen-spot"))


  ;; キッチンの場所まで移動 (初期値)
  (defun move-to-kitchen-irt ()
    (send *pr2* :move-to *kitchen-spot* :world)
    )
  (move-to-kitchen-irt)

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (objects (list *pr2* *cutting-board*))

  ;; def global values
  (setq s-time 3)
  
  (setq adj 0)

  ;; set potato
  (load "../../model/potato-new-type.l")

  (setq width 90)
  (setq length 60)
  (setq height 60)
  )

(defun set-pose-ri ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun set-pose ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  )

(init)

(warn "please run (grasp-cup) ~%")

(defun grasp-cup ()

  (set-pose-ri)
  
  (send *ri* :stop-grasp :rarm)
  
  (setq *av1* #f(325.0 75.0 50.0 110.0 -110.0 -20.0 -10.0 -10.0 -10.3967 50.5475 -34.7743 -114.61 170.572 -76.4279 -233.834 0.0 50.0))
  (send *pr2* :angle-vector *av1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)

  (send *pr2* :rarm :move-end-pos #f(-100 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos #f(0 0 -100) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos #f(-100 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos #f(-100 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  ;; (setq *target* (make-coords :pos (float-vector 497.544 2098.394 1000) :rpy (float-vector -3.097 0.222 -1.404)))
  ;; (set-pose)
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;     *target*
  ;;     :rotation-axis t
  ;;     :debug-view t)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  ;; (send *ri* :wait-interpolation)
  
  ;; (setq *target* (make-coords :pos (float-vector 397.545 2098.393 922.693) :rpy (float-vector -3.097 0.222 -1.404)))
  ;; (set-pose)
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;     *target*
  ;;     :rotation-axis t
  ;;     :debug-view t)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 5000)
  ;; (send *ri* :wait-interpolation)

  ;; (setq *target* (make-coords :pos (float-vector 297.544 2098.392 922.696) :rpy (float-vector -3.097 0.222 -1.404)))
  ;; (set-pose)
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;     *target*
  ;;     :rotation-axis t
  ;;     :debug-view t)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  ;; (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :rarm)

  (warn "please run (pick-up-cup) ~%")
  )

(defun pick-up-cup ()
  ;; (setq *pose1* #f(324.768 74.8533 49.8782 109.534 -106.097 -20.0171 -5.72958 -10.7103 12.3639 19.2635 26.5434 -37.0537 -192.461 -27.6422 86.3053 3.0307 74.2702))
  ;; (setq *pose2* #f(324.768 74.8533 49.8782 109.534 -106.097 -20.0171 -5.72958 -10.7103 16.1935 34.9065 21.1899 -71.7907 -186.591 -47.0051 87.4457 3.0307 74.2702))
  ;; (setq *pose3* #f(324.768 74.8533 49.8782 109.534 -106.097 -20.0171 -5.72958 -10.7103 15.8274 46.4602 14.2563 -95.8232 -185.611 -60.674 93.3808 3.0307 74.2702))
  ;; (setq *pose4* #f(324.768 74.8533 49.8782 109.534 -106.097 -20.0171 -5.72958 -10.7103 13.7601 55.7552 6.76184 -115.987 -186.623 -72.5464 99.0657 3.0307 74.2702))

  ;; (setq avs (list *pose1* *pose2* *pose3* *pose4*))
  ;; (setq tms (list 1000 1000 1000 1000))

  ;; (send *ri* :angle-vector-sequence avs tms)
  ;; (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos #f(0 0 100) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos #f(100 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos #f(100 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :move-end-pos #f(100 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (warn "please run (move-to-microwave) ~%")
  )

(defun move-to-microwave ()
  ;; 電子レンジまで移動する
  (send *ri* :clear-costmap)
  (send *ri* :go-pos-unsafe -0.2 0 0)
  (send *ri* :go-pos-unsafe 0 0 -90)
  
  (send *pr2* :torso_lift_joint :joint-angle 100)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *pr2* :angle-vector #f(100.161 75.0006 49.9994 109.993 -109.995 -19.9972 -10.0007 -9.99948 -40.1721 59.1602 -68.2551 -119.512 165.852 -64.9736 -220.86 -0.005299 51.906))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  

  (send *ri* :move-to (make-coords :pos #f(1400 9400 351) :rpy (float-vector 0 0 0)) :frame-id "/map")
  )

(defun now-grasp ()
  (grasp-cup)
  (pick-up-cup)
  )

(defun now-micro ()
  (grasp-cup)
  (pick-up-cup)
  (move-to-microwave)
  )
