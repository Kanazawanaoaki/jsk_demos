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
  (load "../../model/spatula.l")
  (load "../../model/ladle.l")
  
  (load "models/arrow-object.l")
  (setq *arrow* (arrow))
  
  ;; set spots
  (setq *cook-spot* (send *room73b2* :spot "cook-spot"))
  (setq *sink-spot* (make-coords :pos #f(1055 2600 0) :rpy #f(3.14 0 0))) 
  (setq *kitchen-spot* (send *room73b2* :spot "kitchen-spot"))
  (setq *stove-spot* (make-coords :pos #f(1400 1600 0) :rpy #f(3.14 0 0)))
  
  ;; キッチンの場所まで移動 (初期値)
  (defun move-to-kitchen-irt ()
    (send *pr2* :move-to *kitchen-spot* :world)
    )
  (move-to-kitchen-irt)
  
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  ;; def global values
  (setq s-time 3)
  
  (setq adj 0)
  

  ;; def tool coords
  ;; (setq *spatula-coords-0* (make-coords :pos (float-vector 362 1946 880) :rpy (float-vector 2.766 0.889 1.742))) ;; tmp
  ;; (setq *ladle-coords-0* (make-coords :pos (float-vector 344 2116 880) :rpy (float-vector 3.016 0.995 1.718))) ;; tmp

  (setq *spatula-coords-1* (make-coords :pos (float-vector 604.067 2135.483 875.13) :rpy (float-vector 3.104 -0.006 -0.088)))
  (setq *ladle-coords-1* (make-coords :pos (float-vector 344 2116 880) :rpy (float-vector 3.016 0.995 1.718))) ;; TODO
  )

(defun set-pose ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun set-pose-rec ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *pr2* :head_tilt_joint :joint-angle 0)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(init)


;; 認識系は一応残しておく．


;; virtual force
(setq *x-thre* -15)

(ros::roseus "stove_rec_test" :anonymous t)
(setq *topic-name* "/left_endeffector/wrench")
(ros::load-ros-manifest "geometry_msgs")
(setq *cb-flag* nil)
(defun wrench-x-cb (msg)
  (when msg
    (let ((x nil))
      (setq x (send msg :wrench :force :x))
      (if (< x *x-thre*)
          (progn 
            (setq *cb-flag* t)
            (format t "OK!! x: ~A ~%" x)
            )
        (format t "x: ~A ~%" x))
      )))


;; point-pose-extractor
(require :detection-interface "package://jsk_perception/euslisp/detection_interface.l")
(defparameter *detection-topic* "/ObjectDetection")

(setq local-cds (make-coords :pos (float-vector 709.078 235.518 1524.735) :rpy (float-vector -3.101 0.632 -0.036)))
(setq *k-panel* (make-cube 70 55 10))
(send *k-panel* :move-to *pr2* :world)
(send *k-panel* :transform (send local-cds :copy-worldcoords))
(send *k-panel* :newcoords (make-coords :pos (send (send *k-panel* :copy-worldcoords) :worldpos)))
(send *k-panel* :rotate (deg2rad 90) :y)
(send *k-panel* :translate #f(35 27.5 0))

(objects (list *pr2* *cutting-board* *k-panel*))

(defun recognition ()
  (set-pose-rec)
  (setq k-pos (float-vector 0 0 0))
  (dotimes (i 10)
    (setq local-cds (check-detection :type "microwave" :speak-name "denshirenji" :timeout 10 :speak nil))
    (send *k-panel* :move-to *pr2* :world)
    (send *k-panel* :transform (send local-cds :copy-worldcoords))
    (setq k-pos (v+ k-pos (send *k-panel* :pos)))
    )
  (send *k-panel* :newcoords (make-coords :pos (scale 0.1 k-pos)))
  (send *k-panel* :rotate (deg2rad 90) :y)
  (send *k-panel* :translate #f(35 27.5 0))
  )

;; end recog codes

(warn "please run (open-shelf-set) ~%")

(defun open-shelf-set ()
  )


(defun open-shelf ()
  )

(defun now-test ()
  (set-pose-3)
  (on-stove)
  (push-knob)
  (grasp-knob)
  (rotate-knob :deg 30)
  (release-knob)
  (push-knob)
  (off-stove)
  )
