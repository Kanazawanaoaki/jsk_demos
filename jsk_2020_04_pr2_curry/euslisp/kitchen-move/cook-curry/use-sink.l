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
  (setq *sink-spot* (make-coords :pos #f(1110 2600 0) :rpy #f(3.14 0 0))) 
  (setq *kitchen-spot* (send *room73b2* :spot "kitchen-spot"))
  (setq *stove-spot* (make-coords :pos #f(1400 1600 0) :rpy #f(3.14 0 0)))


  ;; キッチンの場所まで移動 (初期値)
  (defun move-to-kitchen-irt ()
    (send *pr2* :move-to *sink-spot* :world)
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

(defun set-pose ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (warn "please run (on-stove) ~%")
  )

(init)

(defun set-pose-2 ()
  (send *pr2* :reset-pose)
  (send *pr2* :head_tilt_joint :joint-angle 40)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  )

;; (set-pose)


;; point-pose-extractor
(require :detection-interface "package://jsk_perception/euslisp/detection_interface.l")
(defparameter *detection-topic* "/ObjectDetection")



(warn "please run (set-pose) or (set-pose-2) ~%")

(setq local-cds (make-coords :pos (float-vector 709.078 235.518 1524.735) :rpy (float-vector -3.101 0.632 -0.036)))
(setq *k-panel* (make-cube 70 55 10))

(objects (list *pr2* *cutting-board* *k-panel*))

(defun recognition ()
  (setq k-pos (float-vector 0 0 0))
  (dotimes (i 10)
    (setq local-cds (check-detection :type "microwave" :speak-name "denshirenji" :timeout 10 :speak nil))
    (send *k-panel* :move-to *pr2* :world)
    (send *k-panel* :transform (send local-cds :copy-worldcoords))
    (setq k-pos (v+ k-pos (send *k-panel* :pos)))
    )
  (send *k-panel* :newcoords (make-coords :pos (scale 0.1 k-pos)))
  (send *k-panel* :rotate (deg2rad 90) :y)
  (send *k-panel* :translate #f(75 115 0))

  )

(defun on-water ()
  (send *ri* :start-grasp :rarm :wait t)

  ;; スイッチの位置
  (send *arrow* :newcoords (make-coords :pos (float-vector 680.337 1730.059 750) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :translate #f(130 0 0) :world)


  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq avs (list))
  (setq tms (list))
  (send *pr2* :rarm :move-end-pos #f(-100 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 600)))

  (send *pr2* :rarm :move-end-pos #f(-30 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 600)))

  (send *pr2* :rarm :move-end-pos #f(30 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 600)))

  (send *pr2* :rarm :move-end-pos #f(100 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 600)))

  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  (warn "hoge hoge ~%")
  )

(defun off-stove ()
  (send *ri* :start-grasp :rarm :wait t)

  ;; スイッチの位置
  (send *arrow* :newcoords (make-coords :pos (float-vector 680.337 1710.059 750) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :translate #f(130 0 0) :world)

  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq avs (list))
  (setq tms (list))

  (send *pr2* :rarm :move-end-pos #f(-100 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 600)))

  (send *pr2* :rarm :move-end-pos #f(-30 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 600)))

  (send *pr2* :rarm :move-end-pos #f(30 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 600)))

  (send *pr2* :rarm :move-end-pos #f(100 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 600)))

  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  )

(defun push-knob ()
  (send *ri* :start-grasp :rarm :wait t)

  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 706.961 1714.929 711.89) :rpy (float-vector -3.036 0.054 1.588)))
  ;; つまみの位置
  (send *arrow* :newcoords (make-coords :pos (float-vector 680.337 1710 715) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :translate #f(130 0 0) :world)

  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq avs (list))
  (setq tms (list))

  (send *pr2* :rarm :move-end-pos #f(-100 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 600)))

  (send *pr2* :rarm :move-end-pos #f(-30 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 600)))
  
  (send *pr2* :rarm :move-end-pos #f(30 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 600)))

  (send *pr2* :rarm :move-end-pos #f(100 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 600)))

  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  )

(defun rotate-knob ()
  (send *ri* :stop-grasp :rarm :wait t)
  
  (send *arrow* :newcoords (make-coords :pos (float-vector 680.337 1710 715) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :rotate (deg2rad 90) :x)
  (send *arrow* :translate #f(130 0 0) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (send *arrow* :translate #f(-100 0 0) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation t)

  (send *arrow* :translate #f(-30 0 0) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :rarm :wait t)

  ;; rotate
  (send *arrow* :rotate (deg2rad 30) :x)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm :wait t)

  (send *arrow* :translate #f(30 0 0) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation t)

  (send *arrow* :translate #f(100 0 0) :world)
  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation )
  )

(defun push-boil-button ()
  (send *ri* :start-grasp :rarm :wait t)

  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 706.961 1714.929 711.89) :rpy (float-vector -3.036 0.054 1.588)))
  ;; つまみの位置
  (send *arrow* :newcoords (make-coords :pos (float-vector 677 1690 665) :rpy (float-vector -3.047 -0.011 1.512)))
  (send *arrow* :translate #f(130 0 0) :world)

  (send *pr2* :rarm :inverse-kinematics
    (send *arrow* :copy-worldcoords)
    :rotation-axis t
    :debug-view t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (setq avs (list))
  (setq tms (list))

  (send *pr2* :rarm :move-end-pos #f(-100 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 800)))

  (send *pr2* :rarm :move-end-pos #f(-30 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 800)))
  
  (send *pr2* :rarm :move-end-pos #f(30 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 800)))

  (send *pr2* :rarm :move-end-pos #f(100 0 0) :world)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 800)))

  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)  
  )


(defun now-test ()
  (set-pose)
  (on-stove)
  (push-knob)
  (rotate-knob)
  (push-knob)
  (off-stove)
  )
