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

(setq *s-time* 3)

(warn "please run (before-cup) ~%")

(defun before-cup ()
  (set-pose-ri)

  (setq *av0* #f(325.0 75.0 50.0 110.0 -110.0 -20.0 -10.0 -10.0 5.97738 55.8128 -6.2944 -116.003 172.052 -73.5272 -252.787 0.0 50.0))
  (send *pr2* :angle-vector *av0*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)

  (unix:sleep 1)
  (send *ri* :stop-grasp :rarm)
  (send *ri* :speak-jp "コップを握らせて下さい")
  
  (unix:sleep *s-time*)
  (send *ri* :start-grasp :rarm :wait t)  

  (warn "please run (put-cup) ~%")
  )


(defun put-cup ()
  
  (send *pr2* :rarm :move-end-pos #f(-100 0 0) :world)
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

  (send *pr2* :rarm :move-end-pos #f(0 0 -100) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm)
  
  (send *pr2* :rarm :move-end-pos #f(100 0 0) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (warn "please run (after-cup) ~%")
  )

(defun after-cup ()
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

  (send *pr2* :rarm :move-end-pos #f(0 0 100) :world)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  (setq *av1* (send *pr2* :angle-vector))
  )

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
  (setq *av0* (send *pr2* :angle-vector))

  (warn "please run (move-to-microwave) ~%")
  )

(defun reset-rarm ()
  (setq *rav-r1* #f(-20.8048 54.2396 -5.42985 -119.734 197.32 -75.8373 -189.059))
  (send *pr2* :rarm :angle-vector *rav-r1*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)

  (setq *rav-r2* #f(-30.0303 1.63624 -169.166 -116.783 100.843 -98.3015 -58.1037))
  (send *pr2* :rarm :angle-vector *rav-r2*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  )

(defun now-put ()
  (before-cup)
  (put-cup)
  (reset-rarm)
  )
