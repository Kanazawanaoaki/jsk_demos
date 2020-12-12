(load "../model/my-room73b2-scene.l")
(setq *room* (room73b2))

(load "package://pr2eus/pr2-interface.l")
(pr2-init)

(load "package://jsk_fetch_startup/euslisp/navigation-utils.l")


;; set spots
(setq *cook-spot* (send *room73b2* :spot "cook-spot"))
(setq *sink-spot* (make-coords :pos #f(1055 2600 0) :rpy #f(3.14 0 0))) 
(setq *desk-spot* (make-coords :pos #f(3470 -1900 0) :rpy #f(-1.57 0 0)))

(setq *kitchen-spot* (send *room73b2* :spot "kitchen-spot"))
(setq */eng2/7f/room73B2-front-of-kitchenboard* (send *room73b2* :spot "/eng2/7f/room73B2-front-of-kitchenboard"))

;; キッチンの場所まで移動

(defun move-to-kitchen-irt ()
  (send *pr2* :move-to *kitchen-spot* :world)
  )
(defun move-to-kitchenboard-irt ()
  (send *pr2* :move-to */eng2/7f/room73B2-front-of-kitchenboard* :world)
  )

(defun move-to-kitchen-ri ()
  ;; (send *ri* :speak-jp "台所まで移動します")
  (send *ri* :clear-costmap)
  ;; (send *ri* :move-to (make-coords :pos #f(1200 8500 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
  (setq local-flag (send *ri* :move-to (make-coords :pos #f(1400 8500 351) :rpy (float-vector pi 0 0)) :frame-id "/map"))
  (if (eql local-flag t)
      (progn
    (send *ri* :go-pos-unsafe 0.2 0 0)
    (warn "go-pos unsafe !! ~%")
    )
    (send *ri* :speak-jp "移動に失敗しました")
    )
  )

(defun move-to-sink-ri ()
  ;; コンロまで移動する
  (send *ri* :clear-costmap)
  ;; (send *ri* :move-to (make-coords :pos #f(1110 9100 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
  (setq local-flag (send *ri* :move-to (make-coords :pos #f(1400 9100 351) :rpy (float-vector pi 0 0)) :frame-id "/map"))
  (if (eql local-flag t)
      (progn   (send *ri* :go-pos-unsafe 0.29 0 0)
           )
    (send *ri* :speak-jp "移動に失敗しました")
    )
  )

(defun move-to-stove-ri ()
  ;; コンロまで移動する
  (send *ri* :clear-costmap)
  (send *ri* :move-to (make-coords :pos #f(1400 8100 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
  )

(defun move-to-microwave-ri ()
  ;; 電子レンジまで移動する
  (send *ri* :clear-costmap)
  (send *ri* :move-to (make-coords :pos #f(1700 9400 351) :rpy (float-vector 0 0 0)) :frame-id "/map")
  )

(defun move-to-seasoning-ri ()
  ;; 電子レンジまで移動する
  (send *ri* :clear-costmap)
  (send *ri* :move-to (make-coords :pos #f(1700 8900 351) :rpy (float-vector 0 0 0)) :frame-id "/map")
  )

(defun move-to-microwave-unsafe ()
  ;; 電子レンジまで移動する
  (send *ri* :clear-costmap)
  (send *ri* :go-pos-unsafe -0.1 0 0)
  (send *ri* :go-pos-unsafe 0 0 -90)
  (send *ri* :move-to (make-coords :pos #f(1400 9400 351) :rpy (float-vector 0 0 0)) :frame-id "/map")
  )


(defun move-to-kitchenboard-ri ()
  (go-to-spot "/eng2/7f/room73B2-front-of-kitchenboard")
  )

(defun set-pose ()
  (send *pr2* :reset-manip-pose)
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (send *viewer* :draw-objects)
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

(move-to-kitchen-irt)

(objects (list *room* *pr2*))
(send *irtviewer* :look-all
      (geo::make-bounding-box 
       (flatten (send-all (send *pr2* :bodies) :vertices))))


(warn "please run (move-to-kitchen-ri) , (move-to-sink-ri) (move-to-stove-ri) and (set-pose)~%")


;; set for recognize robot's pos
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

;; (objects (list *pr2* *cutting-board* *k-panel*))

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

