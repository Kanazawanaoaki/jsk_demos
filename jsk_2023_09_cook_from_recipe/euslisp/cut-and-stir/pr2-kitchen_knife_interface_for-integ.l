(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/knife-new-attention.l")
(load "package://pr2eus/pr2-interface.l")
(load "models/arrow-object.l")
;; (load "package://informatized_body_core/euslisp/informatized-body-core.l")
;; (initialize-ibm-core "pr2_knife")

(ros::roseus-add-msgs "geometry_msgs")

(defclass pr2-kitchen_knife-interface
  :super object
  :slots (cut-pose
          nn-ref-hand-z
          nn-diff-ref-hand-z
          ibm-ref-hand-z
          ibm-cut-target-num
          ibm-cut-target-mode)
  )

(defmethod pr2-kitchen_knife-interface
  (:init
   ()
   (ros::roseus "pr2_knife_cut_interface")
   ;; (setq default-cut-pose (make-cascoords :pos #f(640.39 26.636 927.821) :rpy #f(-0.058 -0.122 -0.067)))
   ;; (setq default-cut-pose (make-cascoords :pos #f(640.39 26.636 927.821) :rpy #f(0 0 0)))
   (setq default-cut-pose (make-cascoords :pos #f(690.39 26.636 927.821) :rpy #f(0 0 0)))
   (setq cut-pose (make-cascoords))
   (send cut-pose :newcoords (send default-cut-pose :copy-worldcoords))

   ;; init pr2
   (when (not (boundp '*pr2*))
     (pr2-init)
     )

   ;; ;; init publisher
   ;; (ros::advertise "diff_hand_z" std_msgs::float64multiarray 1)
   ;; (ros::advertise "hand_z" std_msgs::float64multiarray 1)
   ;; (ros::advertise "/pr2_knife/wrench_act" informatized_body_msgs::Float32MultiArrayStamped 1)
   ;; (ros::advertise "/pr2_knife/hand_act" informatized_body_msgs::Float32MultiArrayStamped 1)
   ;; (ros::advertise "/pr2_knife/hand_ref" informatized_body_msgs::Float32MultiArrayStamped 1)
   ;; (ros::advertise "/pr2_knife/controller/target_state" informatized_body_msgs::TargetState 1)

   ;; ;; init subscriber
   ;; (setq nn-ref-hand-z 0)
   ;; (ros::subscribe "/deepmpc/ref_hand_z" std_msgs::Float64MultiArray
   ;;                 #'send self :cb-nn-ref-hand-z)
   ;; (setq nn-diff-ref-hand-z 0)
   ;; (ros::subscribe "/deepmpc/diff_ref_hand_z" std_msgs::float64multiarray
   ;;                 #'send self :cb-nn-diff-ref-hand-z)
   ;; (setq now-force 0)
   ;; (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped
   ;;                 #'send self :cb-wrench)
   ;; (setq ibm-ref-hand-z 0) ;; tmp
   ;; (ros::subscribe "/pr2_knife/controller/target_input" std_msgs::Float32MultiArray
   ;;                 #'send self :cb-ibm-target-input)

   ;; ;; init ibm-cut-target num and mode
   ;; (setq ibm-cut-target-num 10)
   ;; (setq ibm-cut-target-mode "minimize")

   ;; init knife
   (when (not (boundp '*knife*))
     (setq *knife* (knife))
     (send *knife* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
     (send *knife* :translate #f(20 0 0))

     (send *knife* :rotate (deg2rad 90) :x)
     (send *pr2* :rarm :end-coords :assoc *knife*)
     )

   ;; init arrow
   (when (not (boundp '*arrow*))
     (setq *arrow* (arrow))
     (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
     )

   (when (not (boundp '*irtviewer*))
     (objects (list *pr2* *knife* *arrow*))
     )
   )

  ;; (:pub-target-state
  ;;  (&key
  ;;   (time 3000)
  ;;   (target-height (+ 892 10))
  ;;   (initial-hand-ref (+ 892 10))
  ;;   (weight #f())
  ;;   )
  ;;  (setq target-wrench (make-array 1 :element-type :float :initial-element 0))
  ;;  (setq target-hand-act (make-array 1 :element-type :float :initial-element target-height));; target height, height+height-threshold
  ;;  (setq target-hand-ref (make-array 1 :element-type :float :initial-element initial-hand-ref))
  ;;  (setq target-state-msg (instance informatized_body_msgs::TargetState :init))
  ;;  ;; (send target-state-msg :type (list "none" "match" "get")) ;; wrench_act, hand_act, hand_ref
  ;;  (send target-state-msg :type (list "none" ibm-cut-target-mode "get")) ;; wrench_act, hand_act, hand_ref ;;hand_ref get
  ;;  (send target-state-msg :target (concatenate float-vector target-wrench
  ;;                                              target-hand-act
  ;;                                              target-hand-ref))
  ;;  (send target-state-msg :weight weight)
  ;;  (send target-state-msg :time time)
  ;;  (ros::publish "/pr2_knife/controller/target_state" target-state-msg)
  ;;  )

  (:start-update-pb
   (&key
    (batch -1)
    (epoch 2) ;;10
    (n_data_thre 5) ;;20
    (n_data_max 50)
    )
   (online-update-start-base "pr2_knife" :mode 0 :batch batch :epoch epoch  :n_data_thre n_data_thre :n_data_max n_data_max)
   )

  (:stop-update-pb
   ()
   (online-update-stop-base "pr2_knife")
   )

  (:reset-pbs
   ()
   (online-update-reset-pbs-base "pr2_knife")
   )

  (:set-pb
   (class_name)
   (online-update-set-pb-base "pr2_knife" class_name)
   )

  (:set-ibm-cut-target-num
   (set-num)
   (setq ibm-cut-target-num set-num)
   (format t "ibm-cut-target-num set to ~A!~%" ibm-cut-target-num)
   )

  (:set-ibm-cut-target-mode
   (mode)
   (if (or (equal mode "minimize") (equal mode "match") (equal mode "minterval"))
       (setq ibm-cut-target-mode mode))
   (format t "ibm-cut-target-mode set to ~A!~%" ibm-cut-target-mode)
   )

  (:cb-nn-ref-hand-z
   (msg)
   (setq nn-ref-hand-z (elt (send msg :data) 0))
   )

  (:cb-nn-diff-ref-hand-z
   (msg)
   (setq nn-diff-ref-hand-z (elt (send msg :data) 0))
   )

  (:cb-wrench
   (msg)
   (setq now-force (send msg :wrench :force :y))
   )

  (:cb-ibm-target-input
   (msg)
   (setq ibm-ref-hand-z (elt (send msg :data) 2)) ;; data is [wrench_act, hand_act, hand_ref]
   (format t "ibm-ref-hand-z: ~A ~%" ibm-ref-hand-z)
   )

  (:ref-other-hand
   (cds)
   (send (send cds :copy-worldcoords) :move-to (make-coords :pos #f(150 75 80) :rpy (float-vector 0 -pi/2 0)))
   )

  (:show-default-cut-pose
   ()
   (send *arrow* :newcoords (send default-cut-pose :copy-worldcoords))
   default-cut-pose)

  (:show-cut-pose
   ()
   (send *arrow* :newcoords (send cut-pose :copy-worldcoords))
   cut-pose)

  (:set-now-cut-pose
   ()
   (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
   (setq cut-pose (send (car (send *knife* :attention)) :copy-worldcoords))
   (send *arrow* :newcoords (send cut-pose :copy-worldcoords))
   cut-pose)

  (:cut-pose
   (&optional (cut-pose- nil))
   (if cut-pose-
       (setq cut-pose cut-pose-))
   cut-pose)

  (:reset-cut-pose
   ()
   (send cut-pose :newcoords (send default-cut-pose :copy-worldcorods))
   cut-pose)

  (:translate-cut-pose
   (&optional (num 0) (axis :z))
   (cond
    ((equal axis :x)
     (send cut-pose :translate (float-vector num 0 0) :world)
     )
    ((equal axis :y)
     (send cut-pose :translate (float-vector 0 num 0) :world)
     )
    ((equal axis :z)
     (send cut-pose :translate (float-vector 0 0 num) :world)
     )
    )
   cut-pose)

  (:rotate-cut-pose
   (&optional (deg 0) (axis :z))
   (send cut-pose :rotate (deg2rad deg) axis :world)
   cut-pose)

  (:manip-pose
   ()
   (send *pr2* :reset-manip-pose)
   (send *pr2* :torso_lift_joint :joint-angle 300) ;;325
   (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
   (send *ri* :wait-interpolation)
   )

  (:init-cut-pose
   (&optional (init-cut-pose (send cut-pose :copy-worldcoords)) (both-arm nil))
   (format t "init-cut-pose is ~A ~%" init-cut-pose)
   (send *pr2* :head :neck-p :joint-angle 50)
   (send *pr2* :torso_lift_joint :joint-angle 300) ;;325
   (send *pr2* :rarm :inverse-kinematics init-cut-pose
         :link-list (list
                     (send *pr2* :link-list (send *pr2* :rarm :end-coords :parent)))
         :move-target (car (send *knife* :attention))
         :debug-view t
         )
   (if both-arm (send *pr2* :larm :inverse-kinematics (send self :ref-other-hand init-cut-pose) :rotation-axis :y))
   (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
   (send *ri* :wait-interpolation)

   (send *ri* :start-grasp :rarm :gain 0.03)
   (unix::sleep 3)
   )

  (:up-larm
   (&optional (height 10))
   (send *pr2* :larm :move-end-pos (float-vector 0 0 height) :world)
   (send *ri* :angle-vector (send *pr2* :angle-vector))
   (send *ri* :wait-interpolation)
   )

  (:grasp-object
   (&optional (height-offset 0))
   (send *ri* :stop-grasp :larm)
   (unix::sleep 2)

   ;; (send *pr2* :larm :angle-vector #f(28.4949 22.0655 71.5578 -75.6765 91.9197 -71.5319 220.579))
   (send *pr2* :larm :angle-vector #f(27.1807 21.8158 72.0309 -75.7248 92.3023 -70.6232 219.808))
   ;;(send *pr2* :larm :angle-vector #f(26.7023 26.7214 70.9455 -88.9509 101.197 -72.2724 206.567))
   (send *ri* :angle-vector (send *pr2* :angle-vector))
   (send *ri* :wait-interpolation)

   (if (not (eq height-offset 0))
       (progn
         (send *pr2* :larm :move-end-pos (float-vector 0 0 height-offset))
         (send *ri* :angle-vector (send *pr2* :angle-vector))
         (send *ri* :wait-interpolation)
         ))

   (send *ri* :start-grasp :larm :gain 0.02)
   (unix::sleep 2)
   )

  (:move-to-cut-spot
   ()
   (send *ri* :clear-costmap)
   (send *ri* :move-to (make-coords :pos #f(1110 8500 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
   (print (send *ri* :state :worldcoords))
   )

  (:test-execute-cut
   (&optional (controller :rule-base) (height 892) (diff-height 0) &key ((:y y) 0))
   (ros::ros-info "init cut pose")
   ;;(setq cut-pose (make-cascoords :pos #f(674.994 34.993 950.983) :rpy #f(0 -0.122 0)))
   (send self :init-cut-pose (send (send cut-pose :copy-worldcoords) :translate (float-vector 0 y 0)))
   (ros::subscribe "/pr2_knife/controller/target_input" std_msgs::Float32MultiArray
                   #'send self :cb-ibm-target-input) ;;tmp
   (setq ibm-ref-hand-z 0) ;; tmp
   (ros::ros-info "cut")
   (send self :cut-once (send (send cut-pose :copy-worldcoords) :translate (float-vector 0 y 0))
         height :controller controller)
   (ros::unsubscribe "/pr2_knife/controller/target_input")
   )

  ;; height is not knife attention but rarm endcoords
  (:cut-once
   (arrow &optional (height 892) &key (controller :rule-base))
   (cond
    ((eq controller :rule-base)
     (send self :rule-base-cut-motion (copy-object arrow) height)
     )
    ((or (eq controller :random1) (eq controller :random2) (eq controller :random3) (eq controller :nn) (eq controller :ibm))
     (send self :primitive-cut-motion (copy-object arrow) height :controller controller)
     )
    )
   )

  (:rule-base-cut-motion
   (arrow height)
   (let ((avs(list))
         (tms (list))
         (interval 10))
     (dotimes (i (round (/ (- (elt (send arrow :worldpos) 2) height) interval)))
       (send arrow :translate (float-vector (* interval 2) 0 (/ interval -2)))
       (send *pr2* :rarm :inverse-kinematics arrow
             :link-list (list
                         (send *pr2* :link-list (send *pr2* :rarm :end-coords :parent)))
             :move-target (car (send *knife* :attention)))

       (setq av (send *pr2* :angle-vector))
       (setq avs (append avs (list av)))
       (setq tms (append tms (list 600)))

       (send arrow :translate (float-vector (* interval -2) 0 (/ interval -2)))
       (send *pr2* :rarm :inverse-kinematics arrow
             :link-list (list
                         (send *pr2* :link-list (send *pr2* :rarm :end-coords :parent)))
             :move-target (car (send *knife* :attention)))

       (setq av (send *pr2* :angle-vector))
       (setq avs (append avs (list av)))
       (setq tms (append tms (list 600)))
       )

     (send *ri* :angle-vector-sequence avs tms)
     (send *ri* :wait-interpolation)
     )
   )

  (:primitive-cut-motion
   (arrow height &key (controller :random1))
   (let* ((cut-x 0)
          (diff-cut-z 0)
          (cut-y 0)
          (cut-z 0)
          (cut-tmp 0)
          (start-time)
          (end-time)
          (prev-res-hand-z -1)
          (prev-ref-hand-z -1)
          (original-res-hand-z (elt (send *pr2* :rarm :end-coords :worldpos) 2))
          (res-hand-z original-res-hand-z)
          (ref-hand-z -1)
          (diff-res-hand-z -1)
          (diff-ref-hand-z -1)
          (ref-hand-cds)
          (target-cut-flag nil)
          (height-threshold 10))
     (do-until-key
      (if (< res-hand-z (+ height height-threshold)) (return-from nil nil))
      ;;(if (>= cut-z height) (return-from nil nil))
      ;;(if (>= (- original-res-hand-z res-hand-z) height) (return-from nil nil))

      (incf cut-tmp)
      (setq start-time (send (ros::time-now) :to-nsec))

      (setq cut-x (send self :calc-cut-x))   ;; calculate hand x

      (cond   ;; calculate hand z
       ((eq controller :random1)
        (setq diff-cut-z (send self :random-cut1 ref-hand-z res-hand-z)))
       ((eq controller :random2)
        (setq diff-cut-z (send self :random-cut2 ref-hand-z res-hand-z)))
       ((eq controller :random3)
        (setq diff-cut-z (send self :random-cut3 ref-hand-z res-hand-z)))
       ((eq controller :nn)
        (if (< cut-tmp 4)
            (setq diff-cut-z (send self :random-cut1 ref-hand-z res-hand-z))
          (setq diff-cut-z (send self :nn-cut ref-hand-z res-hand-z)))
        )
       ((eq controller :ibm) ;; not work now!!!!
        (if (< cut-tmp 10) ;;4 ;; 4回目まではランダムに切っている．それは無くしてもよいかも． 今は0にしていて今後変えても良いかも ;;10だった？
            (setq diff-cut-z (send self :random-cut1 ref-hand-z res-hand-z))
          (progn
            ;; (send self :stop-update-pb);; tmp
            (setq target-cut-z (send self :ibm-cut ref-hand-z res-hand-z))
            (format t "target-cut-z: ~A ~%" target-cut-z)
            (if (> target-cut-z (+ res-hand-z 20)) (setq target-cut-z (+ res-hand-z 20))) ;; 20mm 以上も上に行こうとしていたらそれを抑制
            (if (> target-cut-z 870) (setq target-cut-z (- target-cut-z 10))) ;; IKが解けない380以上に行こうとしていたら抑制
            (setq target-cut-flag t)
            (setq diff-cut-z 0)
            )
          )
        ))

      (setq cut-z (+ cut-z diff-cut-z))
      (if (> cut-z height) (setq cut-z height))
      (warn "diff-cut-z: ~A~%" diff-cut-z)
      (warn "cut-z: ~A~%" cut-z)
      ;;(warn "test: ~A ~A~%" ref-hand-z res-hand-z)

      ;; send to robot
      #|
      (cond
      ((or (eq controller :random1) (eq controller :random2) (eq controller :random3))
      (setq ref-hand-cds (send (send arrow :copy-worldcoords) :translate
      (float-vector cut-x cut-z cut-y)))
      )
      ((eq controller :nn)
      (setq ref-hand-cds (send (send arrow :copy-worldcoords) :translate
      (float-vector cut-x cut-z cut-y)))
      )
      )
      |#
      (setq ref-hand-cds (send (send arrow :copy-worldcoords) :translate
                               (float-vector cut-x cut-y (- cut-z))))
      (if target-cut-flag
          (progn
            (send ref-hand-cds :translate (float-vector 0 0 (- target-cut-z (elt (send ref-hand-cds :worldpos) 2))))
            (send ref-hand-cds :translate (float-vector 0 0 -18.94));; addjust knife and hand
            )
          )

      (format t "ref-hand-cds: ~A ~%" ref-hand-cds)
      ;;(send *pr2* :rarm :inverse-kinematics ref-hand-cds)
      ;;(send *pr2* :rarm :inverse-kinematics arrow :move-target (car (send *knife* :attention)))
      (send *pr2* :rarm :inverse-kinematics ref-hand-cds
            :link-list (list
                        (send *pr2* :link-list (send *pr2* :rarm :end-coords :parent)))
            :move-target (car (send *knife* :attention))
            :debug-view t)

      ;;(if both-arm (send *pr2* :larm :inverse-kinematics (send self :ref-other-hand ref-hand-cds) :rotation-axis :y))
      (send *pr2* :head :neck-p :joint-angle 50) ;; for fix head
      (send *ri* :angle-vector (send *pr2* :angle-vector) 500)

      ;; (unix::usleep (floor (* 1000000 0.1)))
      (send *ri* :wait-interpolation) ;; TODO

      ;; calculate reference and result hand z
      (setq ref-hand-z (elt (send *pr2* :rarm :end-coords :worldpos) 2))
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      (setq res-hand-z (elt (send *pr2* :rarm :end-coords :worldpos) 2))

      (warn "~A~%" res-hand-z)

      ;; calculate diff and absoluate reference and result hand z
      (when (and (not (eq prev-res-hand-z -1)) (not (eq prev-ref-hand-z -1)))
        (setq diff-res-hand-z (- res-hand-z prev-res-hand-z))
        (setq diff-ref-hand-z (- ref-hand-z prev-ref-hand-z))

        ;; ;; publish
        ;; (let ((diff-hand-z-msg (instance std_msgs::float64multiarray :init))
        ;;       (hand-z-msg (instance std_msgs::float64multiarray :init))
        ;;       (hand-act-msg (instance informatized_body_msgs::Float32MultiArrayStamped :init))
        ;;       (hand-ref-msg (instance informatized_body_msgs::Float32MultiArrayStamped :init))
        ;;       (wrench-act-msg (instance informatized_body_msgs::Float32MultiArrayStamped :init))
        ;;       (stamp (ros::time-now))
        ;;       )
        ;;   ;; diff hand z msg
        ;;   (send diff-hand-z-msg :data (float-vector diff-res-hand-z diff-ref-hand-z))
        ;;   (ros::publish "diff_hand_z" diff-hand-z-msg)

        ;;   ;; hand z msg
        ;;   (send hand-z-msg :data (float-vector res-hand-z ref-hand-z))
        ;;   (ros::publish "hand_z" hand-z-msg)

        ;;   ;; hand act msg
        ;;   (send hand-act-msg :header (instance std_msgs::Header :init :stamp stamp))
        ;;   (send hand-act-msg :data (float-vector res-hand-z))
        ;;   (ros::publish "/pr2_knife/hand_act" hand-act-msg)

        ;;   ;; hand ref msg
        ;;   (send hand-ref-msg :header (instance std_msgs::Header :init :stamp stamp))
        ;;   (send hand-ref-msg :data (float-vector ref-hand-z))
        ;;   (ros::publish "/pr2_knife/hand_ref" hand-ref-msg)

        ;;   ;; hand ref msg
        ;;   (send wrench-act-msg :header (instance std_msgs::Header :init :stamp stamp))
        ;;   (send wrench-act-msg :data (float-vector now-force))
        ;;   (ros::publish "/pr2_knife/wrench_act" wrench-act-msg)

        ;;   ;; ibm target state
        ;;   (send self :pub-target-state :target-height (- res-hand-z ibm-cut-target-num) :initial-hand-ref (- res-hand-z ibm-cut-target-num))
        ;;   )
        )

      ;; set previous reference and result hand z
      (setq prev-res-hand-z res-hand-z)
      (setq prev-ref-hand-z ref-hand-z)

      ;; wait so that execute every 0.1 s
      (setq end-time (send (ros::time-now) :to-nsec))
      (if (< (- end-time start-time) (* 1000000 0.1))
          (unix::usleep (floor (- (* 1000000 0.1) (- end-time start-time))))
        )

      (ros::spin-once)
      )

     (dotimes (time-idx 12)
       (setq cut-x (send self :calc-cut-x))
       (setq ref-hand-cds (send (send arrow :copy-worldcoords) :translate
                                (float-vector cut-x cut-y 0)))
       (setf (elt (send ref-hand-cds :worldpos) 2)
             (+ height
                (- (elt (send (car (send *knife* :attention)) :worldpos) 2)
                   (elt (send *pr2* :rarm :end-coords :worldpos) 2))))
       (warn "height ~A~%" height)

       (send *pr2* :rarm :inverse-kinematics ref-hand-cds
             :link-list (list
                         (send *pr2* :link-list (send *pr2* :rarm :end-coords :parent)))
             :move-target (car (send *knife* :attention))
             :debug-view t)

       (send *pr2* :head :neck-p :joint-angle 50) ;; for fix head
       (send *ri* :angle-vector (send *pr2* :angle-vector) 500)
       ;; (unix::usleep (floor (* 1000000 0.1)))
       (send *ri* :wait-interpolation)
       )

     (send *pr2* :head :neck-p :joint-angle 50) ;; for fix head
     (send *ri* :angle-vector (send *pr2* :angle-vector) 1000)
     (send *ri* :wait-interpolation)
     )
   )

  (:calc-cut-x
   ()
   (let ((current-time (/ (send (ros::time-now) :to-nsec) 1000000))
         (time-width 2000)
         (res-cut-x 40))
     (if (> (mod  current-time time-width) (/ time-width 2))
         (setq res-cut-x (- res-cut-x))
       )
     res-cut-x)
   )

  ;; TODO explore the method to adjust z
  (:random-cut1
   (ref-hand-z res-hand-z)
   (let ((diff-cut-z)
         (cut-z-speed 2))
     (setq diff-cut-z (* (random 5) cut-z-speed))
     (when (and (not (eq res-hand-z -1)) (not (eq ref-hand-z -1)))
       (if (< ref-hand-z (- res-hand-z 5))   ;; stuck to cut
           (if (> (random 10) 3)
               (setq diff-cut-z 0)
             (setq diff-cut-z (* (random 10) (- cut-z-speed)))
             )
         )
       )
     diff-cut-z)
   )

  (:random-cut2
   (ref-hand-z res-hand-z)
   (let ((diff-cut-z)
         (cut-z-speed 2))
     (setq diff-cut-z (* (random 5) cut-z-speed))
     (when (and (not (eq res-hand-z -1)) (not (eq ref-hand-z -1)))
       (if (< ref-hand-z (- res-hand-z 2))   ;; stuck to cut
           (if (> (random 10) 3)
               (setq diff-cut-z 0)
             (setq diff-cut-z (* (random 3) (- cut-z-speed)))
             )
         )
       )
     diff-cut-z)
   )

  (:random-cut3
   (ref-hand-z res-hand-z)
   (let ((diff-cut-z)
         (cut-z-speed 4))
     (setq diff-cut-z (* (random 5) cut-z-speed))
     (when (and (not (eq res-hand-z -1)) (not (eq ref-hand-z -1)))
       (if (< ref-hand-z (- res-hand-z 7))   ;; stuck to cut
           (if (> (random 10) 3)
               (setq diff-cut-z 0)
             (setq diff-cut-z (* (random 6) (- cut-z-speed)))
             )
         )
       )
     diff-cut-z)
   )

  (:nn-cut
   (ref-hand-z res-hand-z)
   (let ((diff-cut-z))
     ;;(setq diff-cut-z (- (- nn-ref-hand-z res-hand-z)))
     (setq diff-cut-z (- nn-diff-ref-hand-z))

     (if (< 10 diff-cut-z) (setq diff-cut-z 10))
     (if (> -10 diff-cut-z) (setq diff-cut-z -10))
     diff-cut-z)
   )

  (:ibm-cut
   (ref-hand-z res-hand-z)
   (let ((target-cut-z))
     (setq target-cut-z ibm-ref-hand-z)
     target-cut-z)
   )

  (:execute-cut
   ()
   )
  )


(warn "~%")
(warn "(setq *pkki* (instance pr2-kitchen_knife-interface :init))~%")
(warn "(send *pkki* :init-cut-pose)~%")
(warn "(send *pkki* :grasp-object)~%")
(warn "~%")
(warn "(send *pkki* :test-execute-cut :rule-base)~%")
(warn "(send *pkki* :test-execute-cut :random1)~%")
(warn "(send *pkki* :test-execute-cut :nn)~%")
(warn "(send *pkki* :test-execute-cut :nn :y 10)~%")
