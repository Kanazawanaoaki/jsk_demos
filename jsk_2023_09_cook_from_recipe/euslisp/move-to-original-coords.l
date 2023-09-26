(load "package://pr2eus/pr2-interface.l")
(load "models/arrow-object.l")
(ros::load-ros-manifest "jsk_2023_09_cook_from_recipe")

(defun init-pr2 ()
  (pr2-init)
  (setq *arrow* (arrow))
  (setq *robot* *pr2*)
  (objects (list *robot* *arrow*))
  ;; (send *robot* :reset-pose) ;; TODO change
  )

(init-pr2)

(defun pr2-reset-move-pose ()
  (send *pr2* :reset-pose)
  (send *pr2* :head-neck-p :joint-angle 30)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  )

(defun calc-pnp-request ()
  (let (req res)
    (setq req (instance jsk_2023_09_cook_from_recipe::CalcPnpRequest :init))
    (setq res (ros::service-call "calc_pnp_with_superglue" req t))
    (if (send res :success)
        (return-from calc-pnp-request res)
      (return-from calc-pnp-request nil))
    ))

(defun plane-rot-to-matrix (plane-rot)
  (let ((q0 (elt plane-rot 0))
        (q1 (elt plane-rot 1))
        (q2 (elt plane-rot 2))
        (q3 (elt plane-rot 3))
        (q4 (elt plane-rot 4))
        (q5 (elt plane-rot 5))
        (q6 (elt plane-rot 6))
        (q7 (elt plane-rot 7))
        (q8 (elt plane-rot 8)))
    ;; (list (list q0 q1 q2)
    ;;       (list q3 q4 q5)
    ;;       (list q6 q7 q8))
    (matrix (list q0 q1 q2)
            (list q3 q4 q5)
            (list q6 q7 q8))
    ))

(defun calc-theta (coords)
  (let* ((theta-nosign (acos (v. (float-vector 1 0 0)
                          (send coords :rotate-vector (float-vector 0 0 1)))))
         (theta-sign (if (> (elt (v* (float-vector 1 0 0)
                                   (send coords :rotate-vector (float-vector 0 0 1))) 2) 0)
                       1 -1))
         (theta (* theta-nosign theta-sign)))
         theta))

(defun get-current-coords ()
  (let ((result-flag nil)
        (current-res))
    (while (equal result-flag nil)
      (setq current-res (calc-pnp-request))
      (setq *current-rot* (plane-rot-to-matrix (send current-res :rotation_matrix)))
      (setq *current-pos* (scale 1000 (send current-res :position_vector)))
      (if (< (norm *current-pos*) 3000)
          (setq result-flag t)
          ))
    ;; TODO check  normが閾値以上ならもう一度
    ))

(defun show-camera-coords ()
  (send *arrow* :newcoords (send (send *robot* :head_mount_kinect_rgb_optical_frame_lk) :copy-worldcoords))

  ;; ;; そのままのバージョン
  ;; (setq now-trans (make-coords :pos *current-pos* :rot *current-rot*))
  ;; (send *arrow* :transform now-trans)

  ;; 逆だったバージョン これっぽい
  (setq now-trans (make-coords :pos *current-pos* :rot *current-rot*))
  (setq inv-trans (send now-trans :inverse-transformation))
  (send *arrow* :transform inv-trans)

  ;; TODO old
  ;; (setq tmp-coords (make-coords :rot *current-rot*))
  ;; (setq inv-rot (send (send tmp-coords :inverse-transformation) :rot))
  ;; (setq now-trans (make-coords :pos *current-pos* :rot inv-rot))
  ;; (send *arrow* :transform now-trans)




  ;; (send *arrow* :translate *current-pos*)
  ;; (setq now-trans (make-coords :rot *current-rot*))
  ;; (send *arrow* :transform now-trans)

  ;; (setq now-trans (make-coords :rot *current-rot*))
  ;; (send *arrow* :transform now-trans)
  ;; (send *arrow* :translate *current-pos*)


  ;; (send *arrow* :translate *current-pos* :world)
  ;; (setq now-trans (make-coords :rot *current-rot*))
  ;; (send *arrow* :transform now-trans)
  )

(defun pr2-move (&key (move-real nil))
  (setq now-coords (make-coords :pos (float-vector (elt (send *arrow* :worldpos) 0) (elt (send *arrow* :worldpos) 1) 0)))
  (setq theta (car (car (rpy-angle *current-rot*))))

  (send now-coords :rotate theta :z :local)
  (send *robot* :move-to (send now-coords :copy-worldcoords))
  (if move-real
      (progn
        (send *ri* :go-pos (* (elt (send now-coords :worldpos) 0) 0.001) (* (elt (send now-coords :worldpos) 1) 0.001) theta)
        ))
  )

(format t "please exec (get-current-coords) (show-camera-coords) (pr2-move) ~%")
