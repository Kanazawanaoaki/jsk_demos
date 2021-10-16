(require :pr2-interface "package://pr2eus/pr2-interface.l")
(require :eng2-scene "package://jsk_2020_04_pr2_curry/euslisp/model/my-eng2-scene.l")

(defun init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/my-eng2-coords.l")
  
  ;; init ROS Node
  (ros::roseus "pr2-move-with-maps")
  
  ;; init 73B2 room
  (unless (boundp '*scene*) (setq *scene* (make-eng2-scene)))
  
  ;; init PR2
  (unless (boundp '*pr2*) (setq *pr2* (instance pr2-sensor-robot :init)))
  (unless (boundp '*ri*) (setq *ri* (instance pr2-interface :init)))
  (send *pr2* :move-to (send *ri* :state :worldcoords) :world)
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))

  (load "models/arrow-object.l")
  (setq *arrow* (arrow))
  (setq *cds* (arrow))
  
  (objects (list *scene* *pr2*))

  ;; set global variables
  (setq *s-time* 3)
  (setq *w-time* 2)
  (setq *debug-flag* nil)
  )

;; add for recognition

(setq *y-thre* -11)
(setq *x-thre* -15)

;; トピックを定義
(setq *bbox-topic-name* "/segmentation_decomposer/boxes")

;; ros init
(ros::roseus "pr2_cook_eus" :anonymous t)
(ros::load-ros-manifest "jsk_recognition_msgs")
(setq *l* (instance ros::transform-listener :init))
(setq found-obj nil)
(print 0)

;; define cb
(defun object-pose-cb (msg)
  (setq *msg* msg)
  (setq *bbox* (car (send msg :boxes)))
  ;; (print 1)
  (when msg
    (when (send *msg* :boxes)
      (let ((cam-coords nil))
        (setq tm2 (send *l* :get-latest-common-time "base_footprint" "head_mount_kinect_rgb_optical_frame"))    
        (setq *dim* (send *bbox* :dimensions))
        (setq width (* (send *dim* :x) 1000))
        (setq length (* (send *dim* :y) 1000))
        (setq height (* (send *dim* :z) 1000))
        (setq *pose* (send *bbox* :pose))
        (setq cam->obj-coords (ros::tf-pose->coords *pose*))
        (when (send *l* :wait-for-transform  "base_footprint" "head_mount_kinect_rgb_optical_frame" tm2 10)
          (setq cam-coords (send (send *pr2* :copy-worldcoords) :transform 
                                 (send *l* :lookup-transform "base_footprint" "head_mount_kinect_rgb_optical_frame" tm2))))
        (when cam-coords
          (setq obj-coord (send cam-coords :transform cam->obj-coords))
          (setq tmp (- (+ (elt (send obj-coord :pos) 2) (/ height 2)) (+ (elt (send *cutting-board* :worldpos) 2) 10)))
          (send obj-coord :translate (float-vector 0 0 (- (/ height 2) (/ tmp 2))) :world)
          (setq height tmp)
          
          (setq obj-pos (scale 0.001 (send obj-coord :worldpos)))
          (if (> width 0)
              (progn
                (setq found-obj t)
                (setq *width* width)
                (setq *length* length)
                (setq *height* height)
                (setq *obj-coord* obj-coord)
                ))
          (print (list 'found? found-obj obj-pos)))
        obj-pos))))

(defun recognition () ;; 物体認識部分のみ
  (setq found-obj nil)
  (setq cnt 0)
  (ros::unsubscribe *bbox-topic-name*)
  (until found-obj
         (print 4)
         (x::window-main-one) ;; IRT viewerの視点を変えられる。見にくければ変えよう

         (setq msg (one-shot-subscribe *bbox-topic-name* jsk_recognition_msgs::BoundingBoxArray :timeout 2000))
         (when msg
           (object-pose-cb msg)

           ;; 中身が空なら抜ける
           (unless (send *msg* :boxes) 
             (progn
               (setq *end-flag* t)
               (return-from recognition)
               ))
           ;; 中身が0だったらカウントする
           (if (= *width* 0)
               (progn
                 (setq cnt (+ cnt 1))
                 ))
           ;; カウントが５以上になったら抜ける
           (if (>= cnt 5)
               (progn
                 (setq *end-flag* t)
                 (return-from recognition)
                 ))
           )
         ;; メッセージが来ていなかったら抜ける
         (unless msg
           (progn
             (setq *end-flag* t)
             (return-from recognition)
             ))
         )
  )


(ros::load-ros-manifest "geometry_msgs")
(setq *wrench-cb-flag* nil)
(defun wrench-y-cb (msg)
  (when msg
    (let ((y nil))
      (setq y (send msg :wrench :force :y))
      (if (< y *y-thre*)
          (progn 
            (setq *wrench-cb-flag* t)
            (format t "OK!! y: ~A ~%" y)
            )
        (format t "y: ~A ~%" y))
      )))

(defun wrench-x-cb (msg)
  (when msg
    (let ((x nil))
      (setq x (send msg :wrench :force :x))
      (if (< x *x-thre*)
          (progn 
            (setq *wrench-cb-flag* t)
            (format t "OK!! x: ~A ~%" x)
            )
        (format t "x: ~A ~%" x))
      )))


;; ;; add for rosservice
;; (ros::load-ros-manifest "std_srvs")
;; (ros::wait-for-service "after_stow_data_collection/save_request")
;; (setq req (instance std_srvs::TriggerRequest :init))


;; (defun rossrv-test ()
;;   ;; (ros::service-call "after_stow_data_collection_kinect/save_request" req t)
;;   (setq res (ros::service-call "after_stow_data_collection/save_request" req t))
;;   )

;; (defun rossrv-test-double ()
;;   (ros::service-call "after_stow_data_collection_kinect/save_request" req t)
;;   (setq res (ros::service-call "after_stow_data_collection/save_request" req t))
;;   )


;; add dynamic parmas
;; c.f https://github.com/knorth55/jsk_demos/blob/5b2a3112cdefb1d53ae04ea0e06d345684386f21/elevator_move_base_pr2/src/utils.l#L1-L145
(defun call-service (service req)
  (if (ros::wait-for-service service 0)
      (ros::service-call service req)
    nil))

(defun change-dynm-params (&rest args)
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/DWAPlannerROS" "xy_goal_tolerance" :double 0.10)
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/DWAPlannerROS" "yaw_goal_tolerance" :double 0.087)  ;; 5deg
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/global_costmap" "footprint_padding" :double 0.03)
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/local_costmap" "footprint_padding" :double 0.03)
  t)

(defun store-params (&rest args)
  (defparameter *xy-goal-tolerance*
    (ros::get-param "/move_base_node/DWAPlannerROS/xy_goal_tolerance"))
  (defparameter *yaw-goal-tolerance*
    (ros::get-param "/move_base_node/DWAPlannerROS/yaw_goal_tolerance"))
  (defparameter *global-footprint-padding*
    (ros::get-param "/move_base_node/global_costmap/footprint_padding"))
  (defparameter *local-footprint-padding*
    (ros::get-param "/move_base_node/local_costmap/footprint_padding"))
  (defparameter *look-at-human-enabled*
    (send (one-shot-subscribe "look_at_human/enabled" std_msgs::Bool) :data))
  (call-service "look_at_human/stop" (instance std_srvs::EmptyRequest :init))
  t)

(defun restore-params (&rest args)
  (when (boundp '*xy-goal-tolerance*)
    (ros::set-dynamic-reconfigure-param
     "/move_base_node/DWAPlannerROS" "xy_goal_tolerance"
     :double *xy-goal-tolerance*))
  (when (boundp '*yaw-goal-tolerance*)
    (ros::set-dynamic-reconfigure-param
     "/move_base_node/DWAPlannerROS" "yaw_goal_tolerance"
     :double *yaw-goal-tolerance*))
  (when (boundp '*global-footprint-padding*)
    (ros::set-dynamic-reconfigure-param
     "/move_base_node/global_costmap" "footprint_padding"
     :double *global-footprint-padding*))
  (when (boundp '*local-footprint-padding*)
    (ros::set-dynamic-reconfigure-param
     "/move_base_node/local_costmap" "footprint_padding"
     :double *local-footprint-padding*))
  (when (and (boundp '*look-at-human-enabled*) *look-at-human-enabled*)
    (call-service "look_at_human/start" (instance std_srvs::EmptyRequest :init)))
  t)

(defun set-defalut-params (&rest args)
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/DWAPlannerROS" "xy_goal_tolerance"
   :double 0.2)
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/DWAPlannerROS" "yaw_goal_tolerance"
   :double 0.17)
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/global_costmap" "footprint_padding"
   :double 0.1)
  (ros::set-dynamic-reconfigure-param
   "/move_base_node/local_costmap" "footprint_padding"
   :double 0.1)
  t)


;; def utils
(defun update-view ()
  (send *pr2* :copy-worldcoords)
  (send *viewer* :draw-objects)
  (send *irtviewer* :look-all *pr2*)           
  )

(defun update-scene ()
  (objects (list *scene* *pr2*))
  (send *irtviewer* :look-all *pr2*)           
  )

(defun update-pos ()
  (send *pr2* :move-to (send *ri* :state :worldcoords) :world)
  (update-view)
  (print (send *ri* :state :worldcoords))
  )

(init)

(if (send *ri* :simulation-modep)
    (progn
      (update-view)
      )
  (progn
    (update-pos)
    (store-params)
    (change-dynm-params)
    )
  )

(warn "~% If you use real robot, run (update-pos) ~%")
(warn "please run (move-to-kitchen-ri) , (move-to-sink-ri) or (move-to-stove-ri) and (set-pose)~%")

;; add for voice recognition
(ros::load-ros-manifest "speech_recognition_msgs")
(setq *data-flag* nil)
(defun voice-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :transcript))
    (setq *data-flag* t)
    (format t "data: ~A ~%" *data*)
    )
  )

(defun dialogue-func ()
  (ros::unsubscribe "/speech_to_text")
  (setq *data-flag* nil)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'voice-cb)
  (until *data-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  (send *ri* :speak-jp "ありがとうございます")
  (unix:sleep 1)
  )

(setq *ok-flag* nil)
(defun voice-ok-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :transcript))
    (if (equal *data* '("OK"))
        (progn
          (format t "了解しました！ ~%" *data*)
          (setq *ok-flag* t)
          )
      (format t "data: ~A ~%" *data*)
      ) 
    )
  )

(defun ok-wait ()
  (ros::unsubscribe "/speech_to_text")
  (setq *ok-flag* nil)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'voice-ok-cb)
  (until *ok-flag*
         (ros::spin-once)
         (ros::sleep)
         )  
  (send *ri* :speak-jp "ありがとうございます")
  (unix:sleep *w-time*)
  )

(defun ok-grasp-larm (&rest args &key (gain 0.01) &allow-other-keys)
  (ok-wait)
  (send *ri* :start-grasp :larm :wait t :gain gain)
  )

(defun ok-grasp (&rest args &key (gain 0.01) &allow-other-keys)
  (ok-wait)
  (send *ri* :start-grasp :rarm :wait t :gain gain)
  )

(defun receive-with-dialogue-larm (&rest args &key (gain 0.01) &allow-other-keys)
  ;; (send *ri* :speak-jp "包丁を渡す準備をして，合図をして下さい") ;; 喋らせている想定でスタート
  (setq *yes-flag* nil)
  (until *yes-flag*
         (send *ri* :stop-grasp :larm :wait t)
         (ok-grasp-larm :gain gain)
         (send *ri* :speak-jp "上手く掴めていますか？")
         (dialogue-func)
         (if (equal *data* '("はい"))
             (setq *yes-flag* t)
           (progn
             (send *ri* :speak-jp "グリッパを開きます.もう一度お願いします")
             (unix:sleep *w-time*)
             )
           )
         )
  
  (send *ri* :speak-jp "次の行動に移ります")
  (unix:sleep *w-time*)
  )

(defun receive-with-dialogue (&rest args &key (gain 0.01) &allow-other-keys)
  ;; (send *ri* :speak-jp "包丁を渡す準備をして，合図をして下さい") ;; 喋らせている想定でスタート
  (setq *yes-flag* nil)
  (until *yes-flag*
         (send *ri* :stop-grasp :rarm :wait t)
         (ok-grasp :gain gain)
         (send *ri* :speak-jp "上手く掴めていますか？")
         (dialogue-func)
         (if (equal *data* '("はい"))
             (setq *yes-flag* t)
           (progn
             (send *ri* :speak-jp "グリッパを開きます.もう一度お願いします")
             (unix:sleep *w-time*)
             )
           )
         )
  
  (send *ri* :speak-jp "次の行動に移ります")
  (unix:sleep *w-time*)
  )

;; add for grasp detection
(defun grasp-fail-detection (&rest args &key (arm :rarm) (g-thre 10) &allow-other-keys)
  (setq *fail-flag* nil)
  (setq gripper-len (send *ri* :state :gripper arm :position))
  (if (< gripper-len g-thre)
      (setq *fail-flag* t))
  )

;; grasp object grasp primitive
(defun grasp-object (&rest args &key (arm :rarm) (gain 0.01) &allow-other-keys)
  (send *ri* :start-grasp arm :wait t :gain gain)
  (unix:sleep 1)
  )

;; release gripper release primitive
(defun release-object (&rest args &key (arm :rarm) (g-num 0.025) &allow-other-keys)
  (let (tmp-gripper)
    ;;グリッパを微妙に開く
    (setq tmp-gripper (* 0.001 (send *ri* :state :gripper arm :position)))
    (send *ri* :move-gripper arm (+ g-num tmp-gripper))
    ))

;; (defun release-object-larm (&rest args &key (g-num 0.025) &allow-other-keys)
;;   (let (tmp-gripper)
;;     ;;グリッパを微妙に開く
;;     (setq tmp-gripper (* 0.001 (send *ri* :state :gripper :larm :position)))
;;     (send *ri* :move-gripper :larm (+ g-num tmp-gripper))
;;     ))

;; wait until movable
(ros::load-ros-manifest "pr2_msgs")

(defun wait-cable ()
  (setq *cable* t)
  (while *cable*
    ;; (let ((msg (cable-test)))
    ;;   (setq *cable* (< 0 (send msg :AC_present)))
    ;;   (unix::sleep 1)))
    (let ((msg (one-shot-subscribe "/power_state" pr2_msgs::PowerState)))
      (setq *cable* (< 0 (send msg :AC_present)))
      (unix::sleep 1)))
  )

(defun wait-cable-in ()
  (setq *cable* t)
  (while *cable*
    (let ((msg (one-shot-subscribe "/power_state" pr2_msgs::PowerState)))
      (setq *cable* (>= 0 (send msg :AC_present)))
      (unix::sleep 1)))
  )

(defun cable-test ()
  (let ((msg (one-shot-subscribe "/power_state" pr2_msgs::PowerState)))
    (format t "now AC_present is ~A ~%" (send msg :AC_present))
    msg))

(defun speech-before-move-with-rec ()
  (setq *msg* (cable-test))
  (if (< 0 (send *msg* :AC_present))
      (progn
        (send *ri* :speak-jp "移動するので電源ケーブルを抜いて下さい")
        (wait-cable)
        (send *ri* :speak-jp "ありがとうございます．移動を開始します")
        )
    (send *ri* :speak-jp "移動を開始します")
    )
  )

(defun speech-after-move-with-rec ()
  (setq *msg* (cable-test))
  (if (< 0 (send *msg* :AC_present))
      (send *ri* :speak-jp "調理を再開します")
    (progn
      (send *ri* :speak-jp "電源ケーブルを挿して下さい")
      (wait-cable-in)
      (send *ri* :speak-jp "ありがとうございます．調理を再開します")
      ))
  )


;; IRT上の移動
(defun move-to-spot-irt (spot)
  (send *pr2* :move-to (send spot :copy-worldcoords) :world)
  (update-view)
  )

;; 実機の移動 move-base primitive
(defun move-base-to-coords-ri-direct (coord)
  (send *ri* :clear-costmap)
  ;; (send *ri* :move-to (make-coords :pos #f(1200 8500 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
  (send *ri* :move-to coord :frame-id "/map")
  (print (send *ri* :state :worldcoords))
  )

(defun move-base-go-pos-unsafe (x y deg)
  (send *ri* :go-pos-unsafe x y deg)
  (update-pos)
  (update-view)
  (print (send *ri* :state :worldcoords))  
  )

;; def util-funcs
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

(defun set-head ()
  (send *pr2* :head :neck-p :joint-angle 50)
  (send *pr2* :head :neck-y :joint-angle 0.0)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  )

(defun after-move ()
  (send *pr2* :torso_lift_joint :joint-angle 325)
  (set-head)
  )

(defun after-move-with-primitive ()
  (move-torso-func 325)
  (move-head-func :p-val 50 :y-val 0.0)
  )

;; move with speech ;; TODOここに移動可能か検知を入れる．
(defun speech-before-move ()
  (send *ri* :speak-jp "移動するので電源ケーブルを抜いて，合図して下さい")
  (ros::unsubscribe "/speech_to_text")
  (setq *ok-flag* nil)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'voice-ok-cb)
  (until *ok-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  
  (send *ri* :speak-jp "ありがとうございます．移動を開始します")
  )

(defun speech-after-move ()
  (send *ri* :speak-jp "電源ケーブルを挿して，合図して下さい")
  
  (ros::unsubscribe "/speech_to_text")
  (setq *ok-flag* nil)
  (ros::subscribe "/speech_to_text" speech_recognition_msgs::SpeechRecognitionCandidates #'voice-ok-cb)
  (until *ok-flag*
         (ros::spin-once)
         (ros::sleep)
         )  
  (send *ri* :speak-jp "ありがとうございます．調理を再開します")
  )


;; 残りのプリミティブを用意する
;; move-arm primitive
(defun move-arm-ik (coord &key (rotate-flag t) (arm :rarm) (times 3000))
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* arm :inverse-kinematics
        coord
        :rotation-axis rotate-flag
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) times)
  (send *ri* :wait-interpolation)
  )

(defun move-arm-av (av &key (arm :rarm) (times 3000))
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* arm :angle-vector av)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) times)
  (send *ri* :wait-interpolation)
  )

(defun move-arm-avs (avs tms)
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  )

;; move-gripper primitive
(defun move-gripper-func (pos &key (arm :rarm)) ;; ex. (move-gripper-func 50 :arm :larm) (move-gripper-func 0.08 :arm :larm)
  (send *ri* :move-gripper arm pos)
  )

;; move-head primitive
(defun move-head-func (&key (p-val 0.0) (y-val 0.0) (times 3000))
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :head :neck-p :joint-angle p-val)
  (send *pr2* :head :neck-y :joint-angle y-val)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) times)
  (send *ri* :wait-interpolation)
  )

(defun move-head-look-at (pos &key (times 3000)) ;; ex. (move-head-look-at (send (send *arrow* :copy-worldcoords) :worldpos))
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :head :look-at pos)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) times)
  (send *ri* :wait-interpolation)
  )

;; move-torso primitive
(defun move-torso-func (val &key (times 3000)) ;; ex. (move-torso-func 325)
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :torso_lift_joint :joint-angle val)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) times)
  (send *ri* :wait-interpolation)
  )


;; move-object  primitive
(defun move-object-ik (coord &key (rotate-flag t) (arm :rarm) (target (send *pr2* :rarm :end-coords)) (times 3000))
  (send *pr2* arm :inverse-kinematics
        coord
        :move-target target
        :rotation-axis rotate-flag
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) times)
  (send *ri* :wait-interpolation)
  )

(defun move-object-avs (avs tms)
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)  
  )


;; push-object primitive
(defun push-object-primitive (slide-length &key (rotate-flag t) (arm :rarm) (target (send *pr2* :rarm :end-coords)) (times 600) (trans (float-vector 0 -10 -3)))
  (setq avs (list))
  (setq tms (list))
  
  (send *cds* :newcoords (send target :copy-worldcoords))
  
  (dotimes (i (+ (/ slide-length 10) 1))
    (send *cds* :translate trans)
    (send *pr2* arm :inverse-kinematics
          (send *cds* :copy-worldcoords)
          :move-target target
          :rotation-axis t
          :debug-view *debug-flag*)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list times)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  )

;; peel primitive
(defun peel-primitive (peeler height width)
  
  ;; 右手を上げる
  (setq *c* (make-coords))
  (send *c* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *c* :translate #f(0 0 200) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *c* :copy-worldcoords)
        :rotation-axis nil
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; 剥く位置
  (send *c* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *c* :translate #f(0 15 0) :world)
  (send *c* :rotate (deg2rad -90) :z :world)

  (send *c* :translate (float-vector 0 0 (* 1 height)) :world)
  (send *c* :rotate (deg2rad 30) :y)
  (send *c* :translate (float-vector 0 80 80) :world)

  ;;調整
  (send *c* :translate (float-vector 0 adj 0))

  (send *c* :translate (float-vector adj2 0 0))
  
  (send *pr2* :rarm :inverse-kinematics
        *c*
        :move-target (car (send peeler :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *c* :translate (float-vector 0 -80 -80) :world)
  (send *pr2* :rarm :inverse-kinematics
        *c*
        :move-target (car (send peeler :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (setq *tmp-rav-0* (send *pr2* :rarm :angle-vector))
  
  ;; 皮剥き始める所
  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *wrench-cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-y-cb)
  
  (setq interval 10)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i (+ (round (/ (* height 2) interval)) 1))
    (send *c* :translate (float-vector 0 0 (* interval -1)) :world)
    (send *pr2* :rarm :inverse-kinematics
          *c*
          :move-target (car (send peeler :attention))
          :rotation-axis t
          :debug-view nil)
    
    (setq av (send *pr2* :angle-vector))
    
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )

  (send *ri* :angle-vector-sequence avs tms)

  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
            (ros::spin-once)
            (if *wrench-cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      
      ;; 剥き終わり
      (send *c* :rotate (deg2rad -30) :y)
      (send *c* :translate (float-vector (* (+ width 20) -1) 0 0) )
      (send *c* :rotate (deg2rad 30) :y)
      
      (send *pr2* :rarm :inverse-kinematics
            *c*
            :move-target (car (send peeler :attention))
            :rotation-axis t
            :debug-view *debug-flag*)
      (send *viewer* :draw-objects)
      (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
      (send *ri* :wait-interpolation)
      
      (ros::unsubscribe "/right_endeffector/wrench")
      
      (warn "you can retry (peel-test) or (finish-pose-peel) , (set-carrot-2)~%")
      (return-from peel-test t))
    )
  
  ;; 剥き終わり
  (send *c* :rotate (deg2rad -30) :y)
  (send *c* :translate (float-vector (* (+ width 20) -1) 0 0) )
  (send *c* :rotate (deg2rad 30) :y)
  
  (send *pr2* :rarm :inverse-kinematics
        *c*
        :move-target (car (send peeler :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (ros::unsubscribe "/right_endeffector/wrench")
  
  (warn "fail cancel !! ~%")
  (warn "you can retry (peel-test) or (finish-pose-peel) , (set-carrot-2)~%")
  )


;; cut primitive
(defun cut-primitive (coord height knife &key (adj 0)) ;; ex. (cut-primitive (send *cut-point-1* :copy-worldcoords) *height* *knife*)
  (unless (boundp '*pkki*)
    (progn      
      (load "package://jsk_kitchen_knife_pr2/euslisp/pr2-kitchen_knife-interface.l")
      (setq *pkki* (instance pr2-kitchen_knife-interface :init))
      ))
  
  (send *cds* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *cds* :translate #f(0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *cds* :copy-worldcoords)
        :rotation-axis nil
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  

  ;; 少し上に包丁を
  (send *cds* :newcoords (send coord :copy-worldcoords))
  (send *cds* :translate (float-vector 0 0 (* height 1)))
  
  ;;調整
  (send *cds* :translate (float-vector 0 adj 0))
  
  ;; (look-at-arrow)
  ;; (rossrv-test)
  
  ;; 少し上にするために
  (setq offset 50)
  
  (send *cds* :translate (float-vector 0 0 offset))  
  (send *pr2* :rarm :inverse-kinematics
        *cds*
        :move-target (car (send knife :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *cds* :translate (float-vector 0 0 (* offset -0.5)))  
  (send *pr2* :rarm :inverse-kinematics
        *cds*
        :move-target (car (send knife :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  (send *cds* :translate (float-vector 0 0 (* offset -0.5)))  
  (send *pr2* :rarm :inverse-kinematics
        *cds*
        :move-target (car (send knife :attention))
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; 室岡さんの切るやつ
  (send *pkki* :cut-once *cds* 30892 :controller :nn) ;; 新しいVer.用
  
  )

;; mix primitive
(defun mix-primitive (center-pos &rest args &key (nums 10) (offset-vec (float-vector 45 0 5)) (rpy1 (float-vector -2.235 1.061 0.117)) (rpy2 (float-vector -2.267 0.887 0.091)) (target (car (send *spatula* :attention))) &allow-other-keys) ;; ex. (mix-primitive (send (send (send *pot* :attention-attention0) :copy-worldcoords) :worldpos))
  ;; ここはmove-armで頑張る所
  ;; ;; 最初の位置
  ;; (send *cds* :newcoords (make-coords :pos (float-vector 461.01 8107.529 30992.813) :rpy (float-vector -2.023 0.672 0.059)))
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *cds* :copy-worldcoords)
  ;;       :move-target (car (send *spatula* :attention))
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  ;; (send *ri* :wait-interpolation)
  
  ;; (send *cds* :newcoords (make-coords :pos (send (send (send (send *pot* :attention-attention0) :copy-worldcoords) :translate #f(0 0 60) :world) :worldpos) :rpy (float-vector -2.288 0.713 0.075)))
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *cds* :copy-worldcoords)
  ;;       :move-target (car (send *spatula* :attention))
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  ;; (send *ri* :wait-interpolation)
  
  ;; 回転させる
  (setq *cds0* (make-cascoords :pos center-pos)) ;;中心の座標
  (setq *cds1* (make-cascoords :pos (send (send (send *cds0* :copy-worldcoords) :translate offset-vec :world) :worldpos))) ;;回転の初期位置 ;;半径 50だった
  
  ;; (setq *rpy1* (float-vector -2.267 0.887 0.091)) ;;回転中の目標姿勢
  ;; (setq *rpy1* (float-vector -2.406 1.193 0.156)) ;;回転中の目標姿勢 ;;IK解けなかった．
  ;; (setq *rpy1* (float-vector -2.253 0.974 0.102)) ;;回転中の目標姿勢
  
  (setq *rpy1* rpy1) ;;回転中の目標姿勢１
  (setq *rpy2* rpt2) ;;回転中の目標姿勢２ 緩め
  
  (send *cds0* :assoc *cds1*)
  
  (send *cds0* :rotate (deg2rad 45) :z :world)
  (send *cds* :newcoords (make-coords :pos (send (send *cds1* :copy-worldcoords) :worldpos) :rpy *rpy1*))
    
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *pr2* :rarm :inverse-kinematics
        (send *cds* :copy-worldcoords)
        :move-target target
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (setq *rs-avs* (list))
  (setq *rs-tms* (list))
  
  (setq cnt0 0)
  
  (dotimes (i 12)
    (send *cds0* :rotate (deg2rad 30) :z :world)
    (send *cds* :newcoords (make-coords :pos (send (send *cds1* :copy-worldcoords) :worldpos) :rpy *rpy1*))
    
    (setq ik-flag (send *pr2* :rarm :inverse-kinematics
                        (send *cds* :copy-worldcoords)
                        :move-target target
                        :rotation-axis t
                        :debug-view nil
                        :stop 10)
          )
    (if (eql ik-flag nil)
        (progn
          (send *cds* :newcoords (make-coords :pos (send (send *cds1* :copy-worldcoords) :worldpos) :rpy *rpy2*))
          (setq ik-flag (send *pr2* :rarm :inverse-kinematics
                              (send *cds* :copy-worldcoords)
                              :move-target target
                              :rotation-axis t
                              :debug-view nil
                              :stop 10
                              ))
          (if (eql ik-flag nil)
              (progn
                (send *pr2* :rarm :inverse-kinematics
                      (send *cds* :copy-worldcoords)
                      :move-target target
                      :rotation-axis nil
                      :debug-view *debug-flag*)
                (setq cnt0 (+ cnt0 1))
                ))))
    
    (send *viewer* :draw-objects)
    (setq av (send *pr2* :angle-vector))
    (setq *rs-avs* (append *rs-avs* (list av)))
    (setq *rs-tms* (append *rs-tms* (list 400)))
    )

  (setq cnt1 0)
  (dotimes (i nums)
    (send *ri* :angle-vector-sequence *rs-avs* *rs-tms*)
    (send *ri* :wait-interpolation)
    
    (setq cnt1 (+ cnt1 1))
    ;; (if (oddp cnt1)
    ;;     (progn
    ;;       (squeeze-pot-test-1)
    ;;       (squeeze-pot-test-2)
    ;;       ))
    )
  
  ;; ここもmove-objectとかでやる所
  ;; (send *cds* :newcoords (make-coords :pos (send (send (send (send *pot* :attention-attention0) :copy-worldcoords) :translate #f(0 0 60) :world) :worldpos) :rpy (float-vector -2.288 0.713 0.075)))
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *cds* :copy-worldcoords)
  ;;       :move-target (car (send *spatula* :attention))
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  ;; (send *ri* :wait-interpolation)
  
  ;; (send *cds* :newcoords (make-coords :pos (float-vector 461.01 8107.529 30992.813) :rpy (float-vector -2.023 0.672 0.059)))
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *cds* :copy-worldcoords)
  ;;       :move-target (car (send *spatula* :attention))
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  ;; (send *ri* :wait-interpolation)
  
  (print cnt0)
  )

;; scrape primitive
(defun scrape-primitive (&key (target (elt (send *spatula* :attention) 1)))
  (send *cds* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *cds* :translate (float-vector 0 50 -50) :world)
  (send *cds* :rotate (deg2rad -90) :z)
  (send *pr2* :rarm :inverse-kinematics
        (send *cds* :copy-worldcoords)
        :move-target target
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 15)
    (send *cds* :translate (float-vector 0 -10 0) :world)
    (send *pr2* :rarm :inverse-kinematics
          (send *cds* :copy-worldcoords)
          :move-target target
          :rotation-axis t
          :debug-view nil)
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )
  (send *ri* :angle-vector-sequence avs tms)
  
  (ros::unsubscribe "/right_endeffector/wrench")
  (setq *topic-name* "/right_endeffector/wrench")
  (setq *wrench-cb-flag* nil)
  (ros::subscribe "/right_endeffector/wrench" geometry_msgs::WrenchStamped #'wrench-x-cb)
  
  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
            (ros::spin-once)
            (if *wrench-cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      (warn "cancel!!! ~%")
      )
    )
  
  (ros::unsubscribe "/right_endeffector/wrench")
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *cds* :newcoords (send target :copy-worldcoords))

  (setq avs (list))
  (setq tms (list))
  
  ;; tmp
  (setq height (- (elt (send (send *cds* :copy-worldcoords) :worldpos) 2) 30960))
  
  (send *cds* :translate (float-vector 0 0 (* height -0.5)) :world)
  (send *cds* :rotate (deg2rad 10) :y)
  (send *pr2* :rarm :inverse-kinematics
        (send *cds* :copy-worldcoords)
        :move-target target
        :rotation-axis t
        :debug-view nil)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 800)))
  
  (send *cds* :translate (float-vector 0 40 (* height -0.3)) :world)
  (send *cds* :rotate (deg2rad 10) :y)
  (send *pr2* :rarm :inverse-kinematics
        (send *cds* :copy-worldcoords)
        :move-target target
        :rotation-axis t
        :debug-view nil)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 800)))
  
  (send *cds* :translate (float-vector 0 40 (* height -0.3)) :world)
  (send *cds* :rotate (deg2rad 10) :y)
  (send *pr2* :rarm :inverse-kinematics
        (send *cds* :copy-worldcoords)
        :move-target target
        :rotation-axis t
        :debug-view nil)
  (setq av (send *pr2* :angle-vector))
  (setq avs (append avs (list av)))
  (setq tms (append tms (list 800)))
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)

  ;; ここはmove-obejctでやる部分！
  ;; (send *cds* :newcoords (send (elt (send *spatula* :attention) 1) :copy-worldcoords))
  ;; (send *cds* :translate (float-vector 0 30 30) :world)
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *cds* :copy-worldcoords)
  ;;       :move-target (elt (send *spatula* :attention) 1)
  ;;       :rotation-axis t
  ;;       :debug-view nil)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  ;; (send *ri* :wait-interpolation)  
  
  ;; (send *cds* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  ;; (send *cds* :translate #f(0 60 -50) :world)
  ;; (send *cds* :rotate (deg2rad -90) :z)
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *cds* :copy-worldcoords)
  ;;       :move-target (car (send *spatula* :attention))
  ;;       :rotation-axis t
  ;;       :debug-view nil)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  ;; (send *ri* :wait-interpolation)  
  )

;; scoop primitive
(defun scoop-primitive (coord) ;; ex. (sccop-primitive (make-coords :pos (v+ (send (send *pot* :attention-attention0) :worldpos) #f(-24.0 -41.0 -21.0)) :rpy (float-vector -0.74 0.613 -1.132)) )
  
  ;; (send *cds* :newcoords (make-coords :pos (float-vector 471 8170 31070) :rpy (float-vector -1.603 0.0 3.14))) ;; wait-pose
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *cds* :copy-worldcoords)
  ;;       :move-target (car (send *ladle* :attention))
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  ;; (send *ri* :wait-interpolation)
  (send *cds* :newcoords (make-coords :pos (v+ (send coord :worldpos) #f(44.999 131.0 236.0)) :rpy (float-vector -1.606 1.047 3.138)))
  (send *pr2* :rarm :inverse-kinematics
        (send *cds* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  
  (send *cds* :newcoords (send coord :copy-worldcoords))
  (send *pr2* :rarm :inverse-kinematics
        (send *cds* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *cds* :translate #f(0 0 -30) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *cds* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  

  (send *cds* :translate #f(40 60 0) :world)  
  (send *pr2* :rarm :inverse-kinematics  
        (send *cds* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  (send *cds* :newcoords (make-coords :pos (v+ (send coord :worldpos) #f(53.0 25.0 36.0)) :rpy (float-vector -1.296 0.242 -0.152)))
  ;; (send *cds* :newcoords (make-coords :pos (float-vector 479 8064 30870) :rpy (float-vector -1.296 0.242 -0.152)))
  (send *pr2* :rarm :inverse-kinematics
        (send *cds* :copy-worldcoords)
        :move-target (elt (send *ladle* :attention) 1)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  
  ;; ??
  ;; (send *pr2* :rarm :move-end-pos #f(0 0 50) :world)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  ;; (send *ri* :wait-interpolation)
  )


;; pour primitive
(defun pour-primitive (coord deg &key (sleep-time 4) (target (car (send *mcup* :attention))) (arm :larm)) ;; ex. (pour-primitive (send (send (send *pot* :attention-attention0) :copy-worldcoords) :translate #f(0 0 200) :world) 50) 
  ;; そそぐ動作
  
  ;; 移し始める座標
  ;; (send *cds* :newcoords (send (send *pot* :attention-attention0) :copy-worldcoords))
  ;; (send *cds* :translate #f(0 0 200) :world)
  (send *cds* :newcoords (send coord :copy-worldcoords))  
  (send *pr2* arm :inverse-kinematics
        (send *cds* :copy-worldcoords)
        :move-target target
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  
  ;; 傾けていく
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i (/ deg 10))
    (send *cds* :rotate (deg2rad 10) :y)
    (send *pr2* arm :inverse-kinematics
          *cds*
          :move-target target
          :rotation-axis t
          :debug-view nil)
    
    (setq av (send *pr2* :angle-vector))
    
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 600)))
    )
  
  (send *ri* :angle-vector-sequence avs tms)
  (send *ri* :wait-interpolation)
  
  ;; 移し終わったかどうか等を判定する？
  
  
  ;; 待つ時間
  (unix:sleep sleep-time)
  
  ;; 戻す動作
  (send *cds* :newcoords (send coord :copy-worldcoords))  
  (send *pr2* arm :inverse-kinematics
        (send *cds* :copy-worldcoords)
        :move-target target
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  
  )


;; push-button primitive
(defun push-primitive (coord &key (arm :larm) (w-thre -15) (axis :x)) ;; ex. (push-primitive (send *ih-knob-coords* :copy-worldcoords) :w-thre -15 :axis :x)
  (send *cds* :newcoords coord)
  ;; (send *cds* :translate #f(100 0 0) :world)
  (send *cds* :translate #f(-100 0 0))
  
  (send *pr2* arm :inverse-kinematics
        (send *cds* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (setq avs (list))
  (setq tms (list))
  
  (dotimes (i 15)
    ;; (send *pr2* arm :move-end-pos #f(-10 0 0) :world)
    (send *pr2* arm :move-end-pos #f(10 0 0))
    (setq av (send *pr2* :angle-vector))
    (setq avs (append avs (list av)))
    (setq tms (append tms (list 400)))
    )
  (send *ri* :angle-vector-sequence avs tms)
  
  (if (eql arm :larm)
      (setq *wrench-topic-name* "/left_endeffector/wrench")
    (setq *wrench-topic-name* "/right_endeffector/wrench")
    )
  (ros::unsubscribe *wrench-topic-name*)
  (setq *topic-name* *wrench-topic-name*)
  (setq *wrench-cb-flag* nil)

  (cond
   ((equal axis :x)
    (ros::subscribe *wrench-topic-name* geometry_msgs::WrenchStamped #'wrench-x-cb)
    (setq *x-thre* w-thre))
   ((equal axis :y)
    (ros::subscribe *wrench-topic-name* geometry_msgs::WrenchStamped #'wrench-y-cb)
    (setq *y-thre* w-thre))
   )
  
  (while (some #'identity (send *ri* :wait-interpolation nil 0.1))
    (when (progn
            (ros::spin-once)
            (if *wrench-cb-flag* t)
            )
      (send *ri* :cancel-angle-vector)
      (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
      (warn "cancel!!! ~%")
      )
    )
  
  (ros::unsubscribe *wrench-topic-name*)
  )


;; 移動系のプログラム move

(defun move-to-sink-with-speech-before ()
  (speech-before-move-with-rec)
  (unix:sleep *w-time*)
  (move-base-to-coords-ri-direct (make-coords :pos #f(1110 9100 351) :rpy (float-vector pi 0 0)))
  (after-move-with-primitive)
  )



;; move utils
(defun move-to-kitchen-irt ()
  ;; (send *pr2* :move-to (send *kitchen-spot* :copy-worldcoords) :world)
  (move-to-spot-irt *kitchen-spot*)
  (update-view)
  )

(defun move-to-shelf-irt ()
  (move-to-spot-irt *shelf-spot*)
  (update-view)
  )

(defun move-to-sink-irt ()
  (move-to-spot-irt *sink-spot*)
  (update-view)
  )
(defun move-to-stove-irt ()
  (move-to-spot-irt *stove-spot*)
  (update-view)
  )
(defun move-to-microwave-irt ()
  (move-to-spot-irt *microwave-spot*)
  (update-view)
  )
(defun move-to-seasoning-irt ()
  (move-to-spot-irt *seasoning-spot*)
  (update-view)
  )
(defun move-to-arrange-irt ()
  (move-to-spot-irt *arrange-spot*)
  (update-view)
  )
(defun move-to-garbage-irt ()
  (move-to-spot-irt *garbage-spot*)
  (update-view)
  )

(defun move-to-kitchen-ri-direct ()
  (send *ri* :clear-costmap)
  (send *ri* :move-to (make-coords :pos #f(1200 8500 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
  (print (send *ri* :state :worldcoords))
  )

(defun move-to-shelf-ri-direct ()
  (send *ri* :clear-costmap)
  (send *ri* :move-to (make-coords :pos #f(1110 8500 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
  (print (send *ri* :state :worldcoords))
  )

(defun move-to-sink-ri-direct ()
  ;; コンロまで移動する
  (send *ri* :clear-costmap)
  (send *ri* :move-to (make-coords :pos #f(1110 9100 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
  (print (send *ri* :state :worldcoords))
  )

(defun move-to-stove-ri-direct ()
  (send *ri* :clear-costmap)
  (send *ri* :move-to (make-coords :pos #f(1200 8100 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
  (print (send *ri* :state :worldcoords))
  )

(defun move-to-microwave-ri-direct ()
  ;; 電子レンジまで移動する
  (send *ri* :clear-costmap)
  (send *ri* :move-to (make-coords :pos #f(1600 9300 351) :rpy (float-vector 0 0 0)) :frame-id "/map")
  (print (send *ri* :state :worldcoords))
  )

(defun move-to-seasoning-ri-direct ()
  ;; 調味料まで移動する
  (send *ri* :clear-costmap)
  (send *ri* :move-to (make-coords :pos #f(1700 8900 351) :rpy (float-vector 0 0 0)) :frame-id "/map")
  (print (send *ri* :state :worldcoords))
  )

(defun move-to-arrange-ri-direct ()
  (send *ri* :clear-costmap)
  (send *ri* :move-to (make-coords :pos #f(1200 8200 351) :rpy (float-vector pi 0 0)) :frame-id "/map")
  (print (send *ri* :state :worldcoords))
  )

(defun move-to-garbage-ri-direct ()
  (send *ri* :clear-costmap)
  (send *ri* :move-to (make-coords :pos #f(1700 9000 351) :rpy (float-vector 0 0 0)) :frame-id "/map")
  (print (send *ri* :state :worldcoords))
  )
