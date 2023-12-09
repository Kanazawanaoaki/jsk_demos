(setq *obj* (make-sphere 100)) ;; dummy object
(require :detection-interface "package://jsk_perception/euslisp/detection_interface.l")
(require :pr2-pose "package://jsk_demo_common/euslisp/pr2-pose.l")
(require :pr2-speack "package://pr2eus/speak.l")
(require :pr2-interface "package://pr2eus/pr2-interface.l")

(defvar *use-voicetext* t)
(defvar *use-english* nil)

;; (if (and (boundp '*use-voicetext*) *use-voicetext*)
;;     (cond
;;      ((and (boundp '*use-english*) *use-english*)
;;       (setq *frige-speak-str* "the refrigerator"))
;;      (t (setq *frige-speak-str* "冷蔵庫")))
;;   (setq *frige-speak-str* "れいぞうこ"))


;; c.f. https://github.com/jsk-ros-pkg/jsk_demos/blob/088b186ea8d02ebda8fee2dc411135f8fd813be1/jsk_demo_common/euslisp/pr2-action.l#L708-L856
(defparameter *adjust-spot-object-cds* nil)
(defun move-to-spot-with-adjust (&key (move-spot :stove) (ratio 1) (look-around nil) (head-pitch 14) (torso-lift 130) (move t) (wait t) (use-base nil))
  (let (ret
        (diffcds (make-coords :pos (float-vector 10000 10000 10000)))
        (distance-threshold 25.0)
        (rotation-threshold 0.09)
        idealcds
        spot-name
        speak-name
        detecion-topic
        cds
        )
    ;; finding adjust spot object
    (case move-spot
          (:stove
           (setq spot-name "stove")
           (setq speak-name "IHコンロ")
           (setq detecion-topic "/point_pose_stove/ObjectDetection")
           (setq idealcds ;; TODO
                 (make-coords :pos (float-vector 775 100 0)
                              :rpy (float-vector 0.05 0 0)))
           )
          (:sink
           (setq spot-name "sink")
           (setq speak-name "水道")
           (setq detecion-topic "/point_pose_stove/ObjectDetection")
           (setq idealcds ;; TODO
                 (make-coords :pos (float-vector 780 100 0)
                              :rpy (float-vector 0.0 0 0)))
           )
    (cond
     ((not (send *ri* :simulation-modep)) ;; real mode
      (setq cds (check-detection :type spot-name :speak-name speak-name
                                 :detection-topic detecion-topic
                                 )))
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
       ((or (send *ri* :simulation-modep) ;;if in simulation mode, execute
            (and (< (norm (float-vector (elt (send diffcds :worldpos) 0)
                                        (elt (send diffcds :worldpos) 1)))
                    distance-threshold)
                 (< (abs (elt (car (rpy-angle (send diffcds :worldrot))) 0))
                    rotation-threshold)))
        (setq ret t)
        (if (not (send *ri* :simulation-modep)) ;; real mode
            (speak-jp "到着しました")
          ))
       (t ;;  there is much difference
        (if move
            (cond
             (wait
              (send *ri* :go-pos-unsafe
                    (/ (elt (send diffcds :worldpos) 0) 1100.0)
                    (/ (elt (send diffcds :worldpos) 1) 1100.0)
                    (* 0.9 (rad2deg (elt (car (rpy-angle (send diffcds :worldrot))) 0))))
              ;; wait ???
              (send *ri* :ros-wait 0.5 :spin-self t :spin t) ;; attention-check ...
              ;; (send *ri* :wait-interpolation)
              )
             (t
              (send *ri* :go-pos-unsafe-no-wait
                    (/ (elt (send diffcds :worldpos) 0) 1100.0)
                    (/ (elt (send diffcds :worldpos) 1) 1100.0)
                    (* 0.9 (rad2deg (elt (car (rpy-angle (send diffcds :worldrot))) 0))))
             )))
        ))
      ) ;; /when cds
    ret
    ))
