(require :fetch-interface "package://fetcheus/fetch-interface.l")
(require :eng2-scene "package://jsk_maps/src/eng2-scene.l")
;; (load "package://jsk_2022_09_fridge_pi/euslisp/demos/fridge-door-close-20220924-02.l")
(ros::roseus-add-srvs "jsk_2022_09_fridge_pi")


(defun init ()
  ;; init 73B2 room
  (unless (boundp '*scene*) (setq *scene* (make-eng2-scene)))

  ;; init FETCH
  (unless (boundp '*fetch*) (setq *fetch* (instance fetch-sensor-robot :init)))
  (unless (boundp '*ri*) (setq *ri* (instance fetch-interface :init)))
  (setq *robot* *fetch*)
  (setq *fetch-fridge-door-spot* (make-coords :pos (float-vector 1537.223 9271.157 29999.747) :rpy (float-vector 1.565 0.0 -0.003)))
  (send *fetch* :move-to (send *fetch-fridge-door-spot* :copy-worldcoords) :world)

  (objects (list *scene* *fetch*))
  )

(defun demo-exec (req)
  (let ((m (send req :response)))
    (format t "demo execution ~%")
    (fridge-door-demo)
    (format t "demo done ~%")
    (send m :success t)
    m))

;; def utils
(defun update-view ()
  (send *fetch* :copy-worldcoords)
  (send *viewer* :draw-objects)
  (send *irtviewer* :look-all *fetch*)
  )

(defun update-pos ()
  (send *fetch* :move-to (send *ri* :state :worldcoords) :world)
  (update-view)
  (print (send *ri* :state :worldcoords))
  )

(defun store-start-spot ()
  (if (send *ri* :simulation-modep)
      (progn
        (format t "Kinematics Simulator ~%")
        (setq *start-spot* (send *fetch-fridge-door-spot* :copy-worldcoords))
        )
      (progn
        (update-pos)
        (setq *start-spot* (send *ri* :state :worldcoords))
        ))
  (format t "start spot is ~A ~%" (send *start-spot* :copy-worldcoords))
  )

;; replay utils
(defun rav2rec (rav-list)
  (setq tmp-av (send *robot* :angle-vector))
  (format t "length of rav-list : ~A ~%" (length rav-list))

  (setq rec-list (list))
  (dolist (rav rav-list)
    (send *robot* :rarm :angle-vector rav)
    (setq now-rec (send (send *robot* :rarm :end-coords) :copy-worldcoords))
    (setq rec-list (append rec-list (list now-rec)))
    )
  (send *robot* :angle-vector tmp-av)
  rec-list)

(defun summarize-rav (rav-list &key (threshold 0.1))
  (let (ans-list rec-list)
    (setq rec-list (rav2rec rav-list))
    (setq ans-list (list (elt rav-list 0)))
    (setq now-index 0)
    (dotimes (i (- (length rav-list) 1))
      ;; ans-listの最後とindex i+1の距離がthreshold以上ならappendする
      (setq now-distance (distance (send (elt rec-list now-index) :worldpos) (send (elt rec-list (+ i 1)) :worldpos)))
      (format t "now distance is : ~A~%" now-distance)
      (if (> now-distance threshold)
          (progn
            (setq ans-list (append ans-list (list (elt rav-list (+ i 1)))))
            (setq now-index (+ i 1))
            )
        ))
    (format t "rav-list length : ~A, summarize-rav-list lenght : ~A~%" (length rav-list) (length ans-list))
    ans-list))

(defun summarize-cook-datas (&key (thre 0.5))
  (setq *place-short-rav-list* (summarize-rav *cook-short-rav-list* :threshold thre))
  )

(defun load-cook-file (&key (file_name "tmp-cook-teaching-data.l") (summarize t) (thre 0.5))
  (load file_name)
  ;; summarize rav-list data if summarize t
  (if summarize
      (summarize-cook-datas :thre thre)
      )
  (setq *initial-head-neck-y* (elt *initial-av* 15))
  (setq *initial-head-neck-p* (elt *initial-av* 16))
  (format t "cook-short-rav-list size : ~A ~%" (length *cook-short-rav-list*))
  )

(defun set-initial-av ()
  ;; (manequine-end)
  (send *robot* :angle-vector *initial-av*)
  ;; (send *robot* :head-neck-y :joint-angle 0.0)
  ;; (send *robot* :head-neck-p :joint-angle 60.0)
  (send *robot* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *robot* :head-neck-p :joint-angle *initial-head-neck-p*)
  (send *ri* :angle-vector (send *robot* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

(defun replay-rav-list (rav-list &key (time 200) (reverse nil))
  (if reverse
      (setq rav-list (reverse rav-list))
    )
  (setq rav-length (length rav-list))
  (format t "length of rav-list : ~A ~%" rav-length)
  (send *robot* :angle-vector (send *ri* :state :potentio-vector))
  (setq now-head-y (send *robot* :head-neck-y :joint-angle))
  (setq now-head-p (send *robot* :head-neck-p :joint-angle))

  (setq avs (list))
  (setq tms (list))
  (dolist (av rav-list)
    ;; (send *robot* :head-neck-y :joint-angle now-head-y)
    ;; (send *robot* :head-neck-p :joint-angle now-head-p)
    ;; (send *robot* :head-neck-y :joint-angle -0.005299)
    ;; (send *robot* :head-neck-p :joint-angle 52.746)
    ;; (send *robot* :head-neck-y :joint-angle 0.0)
    ;; (send *robot* :head-neck-p :joint-angle 60.0)
    (send *robot* :head-neck-y :joint-angle *initial-head-neck-y*)
    (send *robot* :head-neck-p :joint-angle *initial-head-neck-p*)
    (send *robot* :rarm :angle-vector av)
    (setq avs (append avs (list (send *robot* :angle-vector))))
    (setq tms (append tms (list time)))
    )
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  )

(defun replay-short-rav-list (rav-list)
  ;; (send *robot* :head-neck-y :joint-angle 0.0)
  ;; (send *robot* :head-neck-p :joint-angle 60.0)
  (send *robot* :head-neck-y :joint-angle *initial-head-neck-y*)
  (send *robot* :head-neck-p :joint-angle *initial-head-neck-p*)
  (send *robot* :rarm :angle-vector (elt rav-list 0))
  (send *ri* :angle-vector (send *robot* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (replay-rav-list rav-list)
  )

;; demo programs
(defun transfer-to-move-pose ()
  (send *fetch* :reset-pose)
  (send *ri* :angle-vector (send *robot* :angle-vector) 4000)
  )

(defun move-to-fridge-door-spot()
  (transfer-to-move-pose)
  (send *fetch* :move-to (send *fetch-fridge-door-spot* :copy-worldcoords) :world)
  (send *ri* :clear-costmap)
  (send *ri* :move-to (make-coords :pos #f(1537.223 9271.157 0) :rpy (float-vector 1.565 0.0 -0.003)) :frame-id "/map")
  (print (send *ri* :state :worldcoords))
  )

(defun close-fridge-door ()
  (load-cook-file :file_name "fridge-door-close-20220924-02.l")

  ;; initial-pose
  (set-initial-av)

  ;; repaly avs
  (replay-short-rav-list *cook-short-rav-list*)

  ;; return to initial-pose
  (set-initial-av)
  )

(defun return-to-start-stop ()
  (transfer-to-move-pose)
  (send *fetch* :move-to (send *start-spot* :copy-worldcoords) :world)
  (send *ri* :clear-costmap)
  (send *ri* :move-to (send *start-spot* :copy-worldcoords) :frame-id "/map")
  (print (send *ri* :state :worldcoords))
  )

(defun fridge-door-demo ()
  (store-start-spot)
  (if (send *ri* :simulation-modep)
      (format t "Kinematics Simulator ~%")
      (progn
        (move-to-fridge-door-spot)
        ))
  (close-fridge-door)
  (if (send *ri* :simulation-modep)
      (format t "Kinematics Simulator ~%")
      (progn
        (return-to-start-stop)
        ))
  )

(init)
(store-start-spot)
(update-view)
(if (send *ri* :simulation-modep)
    (format t "Kinematics Simulator ~%")
    (progn
      (load "package://jsk_fetch_startup/euslisp/navigation-utils.l")
      ))

;; (warn ";; please run (fridge-door-demo) ~%")

;; service call server
(ros::roseus "fetch_fridge_door_close")
(ros::advertise-service "fridge_door_close_demo" jsk_2022_09_fridge_pi::DemoOrder #'demo-exec)
(do-until-key
    (ros::spin-once))
