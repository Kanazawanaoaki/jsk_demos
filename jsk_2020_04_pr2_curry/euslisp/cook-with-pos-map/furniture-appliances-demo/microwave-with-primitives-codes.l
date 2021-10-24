(defun microwave-primitive-init () ;; 電子レンジの動作部分だけをプリミティブを使って書く用にする．
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/my-cook-primitive-funcs.l")
  (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/furniture-appliances/ros-topic-test/smach_state_msg-publisher.l")
  

  (require :detection-interface "package://jsk_perception/euslisp/detection_interface.l")
  (defparameter *detection-topic* "/ObjectDetection")
  
  ;; init microwave
  (load "package://microwave_pr2_201710/euslisp/lib/microwave.l")
  (unless (boundp '*microwave*) (setq *microwave* (microwave-init)))
  ;; (send *microwave* :move-to (send (send *scene* :spot "/eng2/7f/room73B2-counter-side") :worldcoords) :world)
  ;; (send *microwave* :move-to (make-coords :pos (float-vector 0 0 1000)))

  (send *microwave* :move-to (send *microwave-spot* :worldcoords) :world)
  (send *microwave* :move-to (make-coords :pos (float-vector 700 200 1000)))
  
  ;; set global var
  (setq *microwave-pos* (send *microwave* :pos))
  (setq *microwave-rpy* (send *microwave* :rpy-angle))
  
  (move-to-spot-irt *microwave-spot*)
  (objects (list *pr2* *scene* *microwave*))
  (update-view)
  )

(microwave-primitive-init)



;; move-with primitive funcs
(defun reset-pose ()
  (send *pr2* :reset-pose)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  )

(defun recog-pose ()
  (move-head-func :p-val 28 :y-val 0)
  )

(defun open-microwave ()
  (let ((handle-coords))
    (move-gripper-func 0 :arm :larm :stop-grasp t) ;; move-gripper primitive
    
    (send *microwave* :move-to (make-coords :pos *microwave-pos* :rpy (car *microwave-rpy*)) :world)
    (send *microwave* :angle-vector (float-vector 180))

    (send *pr2* :larm :angle-vector #f(60.0 74.0 70.0 -120.0 20.0 -30.0 180.0))
    
    ;; pre-open1 m-handleは書き方がやばいから(send *microwave* :get-handle)とかを使って書き換えて行きたい.
    (setq handle-coords (make-coords :pos (send (send m-handle :copy-worldcoords) :worldpos) :rpy (float-vector (car (car (rpy-angle (send (send m-handle :copy-worldcoords) :worldrot)))) 0 0)))
    (send handle-coords :translate (float-vector -80 -10 -50))
    (move-arm-ik (send (send handle-coords :copy-worldcoords) :rotate (/ pi -2) :y) :rotate-flag t :arm :larm :times 2000) ;; move-arm primitive

    ;; pre-open2
    (setq handle-coords (make-coords :pos (send (send m-handle :copy-worldcoords) :worldpos) :rpy (float-vector (car (car (rpy-angle (send (send m-handle :copy-worldcoords) :worldrot)))) 0 0)))
    (send handle-coords :translate (float-vector -80 -10 50))
    (move-arm-ik (send (send handle-coords :copy-worldcoords) :rotate (/ pi -2) :y) :rotate-flag t :arm :larm :times 2000) ;; move-arm primitive 

    (let ((i 170)   ;; open
          (av)
          (tms (list))
          (avs (list)))
      (while (> i 89) ;; 99
        (send *microwave* :angle-vector (float-vector i))
        (setq handle-coords (make-coords :pos (send (send m-handle :copy-worldcoords) :worldpos) :rpy (float-vector (car (car (rpy-angle (send (send m-handle :copy-worldcoords) :worldrot)))) 0 0)))
        (send handle-coords :translate (float-vector -80 -10 50))
        
        (send *pr2* :larm :inverse-kinematics (send (send handle-coords :copy-worldcoords) :rotate (/ pi -2) :y) :rotation-axis t)
        (setq av (send *pr2* :angle-vector))
        (setq avs (append avs (list av)))
        (setq tms (append tms (list 600)))

        (setq i (- i 10))
        )
      (move-object-avs avs tms) ;; move-object primitive ?
      )
    
    ;; detach left hand from microwave
    (move-arm-ik (send (send handle-coords :copy-worldcoords) :rotate (/ pi -2) :y) :rotate-flag t :arm :larm :times 1000) ;; move-arm primitive

    (move-arm-ik (send (send (send handle-coords :copy-worldcoords) :rotate (/ pi -2) :y) :translate (float-vector -50 0 60)) :rotate-flag t :arm :larm :times 1000) ;; move-arm primitive

    (move-arm-ik (send (send (send handle-coords :copy-worldcoords) :rotate (/ pi -2) :y) :translate (float-vector -50 -10 60)) :rotate-flag t :arm :larm :times 1000) ;; move-arm primitive
    
    (move-arm-ik (send (send (send handle-coords :copy-worldcoords) :rotate (/ pi -2) :y) :translate (float-vector -200 0 10)) :rotate-flag t :arm :larm :times 1000) ;; move-arm primitive
    
    (move-arm-av #f(60.0 74.0 70.0 -120.0 20.0 -30.0 180.0) :arm :larm :times 1000) ;; move-arm primitive
    )
  )


(defun close-microwave ()
  (let ((handle-coords))
    (send *pr2* :head :neck-p :joint-angle 28)
    (send *pr2* :larm :angle-vector #f(60.0 74.0 70.0 -120.0 20.0 -30.0 180.0))
    (send *microwave* :angle-vector (float-vector 70))

    ;; pre-hang left hand to microwave
    (setq handle-coords (make-coords :pos (send (send (send m-handle :copy-worldcoords) :translate (float-vector -100 -100 -50)) :worldpos) :rpy (float-vector (car (car (rpy-angle (send m-handle :worldrot)))) 0 0)))
    (move-arm-ik (send (send handle-coords :copy-worldcoords) :rotate (/ pi -2) :y) :rotate-flag nil :arm :larm :times 2000) ;; move-ar
     
    ;; hang left hand to microwave
    (setq handle-coords (make-coords :pos (send (send (send m-handle :copy-worldcoords) :translate (float-vector -100 -100 130)) :worldpos) :rpy (float-vector (car (car (rpy-angle (send m-handle :worldrot)))) 0 0)))
    (move-arm-ik (send (send handle-coords :copy-worldcoords) :rotate (/ pi -2) :y) :rotate-flag nil :arm :larm :times 2000) ;; move-ar
     
    (let ((i 110)   ;; close
          (av)
          (tms (list))
          (avs (list)))
      (while (< i 216)
        (send *microwave* :angle-vector (float-vector i))
        (setq handle-coords (make-coords :pos (send (send (send m-handle :copy-worldcoords) :translate (float-vector -100 -100 130)) :worldpos)
                                         :rpy (float-vector (car (car (rpy-angle (send m-handle :worldrot)))) 0 0)))
        (send *pr2* :larm :inverse-kinematics (send (send handle-coords :copy-worldcoords) :rotate (/ pi -2) :y) :rotation-axis nil)
        (setq av (send *pr2* :angle-vector))
        (setq avs (append avs (list av)))
        (setq tms (append tms (list 400)))
        (setq i (+ i 10))
        )
      (send *ri* :angle-vector-sequence avs tms)
      (send *ri* :wait-interpolation)
      )
  
    ;; reset pose
    (send *pr2* :head :neck-p :joint-angle 28) ;; これはどうしようかめっちゃ微妙...
    (move-arm-av #f(60.0 74.0 70.0 -120.0 20.0 -30.0 180.0) :arm :larm :times 1000) ;; move-arm primitive
    )
  )

(defun push-button (pos) ;; 引数ありのプログラムにして使いまわす
  (let* ((button-front (send (send *microwave* :copy-worldcoords) :transform (make-coords :pos pos)))
        (button (send (send button-front :copy-worldcoords) :translate (float-vector 95 0 0) :world))) ;; 85
    
    (push-primitive button :arm :rarm :w-thre -15 :axis :x)
     
    ;; post-push
    (move-arm-ik button-front :arm :rarm :rotate-flag t :times 2000) ;; move arm primitive
    )
  )


(defun push-500w-button ()
  (send *pr2* :reset-pose)
  (send *pr2* :head :neck-p :joint-angle 28)
  (send *pr2* :start-grasp :rarm)
  (move-gripper-func 0 :arm :rarm) ;; move-gripper primitive
  
  (send *microwave* :move-to (make-coords :pos *microwave-pos* :rpy (car *microwave-rpy*)) :world)
  (send *microwave* :angle-vector (float-vector 180))
  
  ;; (send self :push-button (float-vector -70 -370 95)) ;; (float-vector -70 -370 105)
  (push-button (float-vector -70 -380 85))
  
  ;; reset-pose rarm
  (send *pr2* :head :neck-p :joint-angle 28) ;; これもどうしようかめっちゃ微妙...
  (move-arm-av #f(-60.0 74.0 -70.0 -120.0 -20.0 -30.0 180.0) :arm :rarm :times 1000) ;; move-arm primitive
  )

(defun push-1min-button ()
  (send *pr2* :reset-pose)
  (send *pr2* :head :neck-p :joint-angle 28)
  (send *pr2* :start-grasp :rarm)
  (move-gripper-func 0 :arm :rarm) ;; move-gripper primitive
  
  (send *microwave* :move-to (make-coords :pos *microwave-pos* :rpy (car *microwave-rpy*)) :world)
  (send *microwave* :angle-vector (float-vector 180))
  
  ;; (send self :push-button (float-vector -70 -390 110)) ;; (float-vector -70 -390 120)
  (push-button (float-vector -70 -405 100))
  
  ;; reset-pose rarm
  (send *pr2* :head :neck-p :joint-angle 28) ;; これもどうしようかめっちゃ微妙...
  (move-arm-av #f(-60.0 74.0 -70.0 -120.0 -20.0 -30.0 180.0) :arm :rarm :times 1000) ;; move-arm primitive
  )

(defun push-start-button ()
  (send *pr2* :reset-pose)
  (send *pr2* :head :neck-p :joint-angle 28)
  (send *pr2* :start-grasp :rarm)
  (move-gripper-func 0 :arm :rarm) ;; move-gripper primitive
  
  (send *microwave* :move-to (make-coords :pos *microwave-pos* :rpy (car *microwave-rpy*)) :world)
  (send *microwave* :angle-vector (float-vector 180))
  
  ;; (send self :push-button (float-vector -70 -410 185)) ;; (float-vector -70 -410 195)
  (push-button (float-vector -60 -410 175))
  
  ;; reset-pose rarm
  (send *pr2* :head :neck-p :joint-angle 28) ;; これもどうしようかめっちゃ微妙...
  (move-arm-av #f(-60.0 74.0 -70.0 -120.0 -20.0 -30.0 180.0) :arm :rarm :times 1000) ;; move-arm primitive
  )

(defun push-reset-button ()
  (send *pr2* :reset-pose)
  (send *pr2* :head :neck-p :joint-angle 28)
  (send *pr2* :start-grasp :rarm)
  (move-gripper-func 0 :arm :rarm) ;; move-gripper primitive
  
  (send *microwave* :move-to (make-coords :pos *microwave-pos* :rpy (car *microwave-rpy*)) :world)
  (send *microwave* :angle-vector (float-vector 180))
  
  ;; (send self :push-button (float-vector -70 -410 185)) ;; (float-vector -70 -410 195)
  (push-button (float-vector -70 -415 70))
  
  ;; reset-pose rarm
  (send *pr2* :head :neck-p :joint-angle 28) ;; これもどうしようかめっちゃ微妙...
  (move-arm-av #f(-60.0 74.0 -70.0 -120.0 -20.0 -30.0 180.0) :arm :rarm :times 1000) ;; move-arm primitive
  )


;; recognition
(ros::load-ros-package "roseus")

(defun microwave-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :data))
    (format t "~A ~%" *data*)
    )
  )

(defun panel-reader-cb (msg)
  (when msg
    (setq *msg* msg)
    (setq *data* (send *msg* :data))
    (format t "~A ~%" *data*)
    (if (ros::time> (send *msg* :header :stamp) *now*)
        (setq *cb-flag* t)
      )
    ))

(defun read-panel ()
  (setq *now* (ros::time-now))
  (ros::unsubscribe "/microwave_reader/result")
  (setq *cb-flag* nil)
  (ros::subscribe "/microwave_reader/result" roseus::StringStamped #'panel-reader-cb)
  (until *cb-flag*
         (ros::spin-once)
         (ros::sleep)
         )
  *data*
  )

(defun string2num (string)
  (let (num)
    (cond
     ((equal string "1")
      (setq num 1))
     ((equal string "2")
      (setq num 2))
     ((equal string "3")
      (setq num 3))
     ((equal string "4")
      (setq num 4))
     ((equal string "5")
      (setq num 5))
     ((equal string "6")
      (setq num 6))
     ((equal string "7")
      (setq num 7))
     ((equal string "8")
      (setq num 8))
     ((equal string "9")
      (setq num 9))
     ((equal string "10")
      (setq num 10))
     ((equal string "11")
      (setq num 11))
     )
    num))

(defun min-check (data min) ;; 認識結果dataがminより上か下か一致しているか返す
  (let (data-num)
    (setq data-num (string2num (string-trim "m" (string-trim "/" data))))
    
    (cond
     ((equal data-num min)
      (format t "data is equal ~%")
      (return-from min-check :equal)
      )
     ((< data-num min)
      (format t "data is tarinai ~%")
      (return-from min-check :under)
      )
     ((> data-num min)
      (format t "data is over ~%")
      (return-from min-check :over)
      ))
    )
  )

(defun microwave-pos-recognition ()
  (let ((local-cds)
        (local-pos)
        (microwave-cds (make-coords)))
    (send *microwave* :move-to (send *ri* :state :worldcoords) :world)
    (send *microwave* :move-to (send *ri* :state :worldcoords) :world)
    (send *pr2* :move-to (send *ri* :state :worldcoords) :world)
    
    (recog-pose)
    
    (setq local-pos (float-vector 0 0 0))
    (dotimes (i 10)
      (setq local-cds (check-detection :type "microwave" :speak-name "denshirenji" :timeout 10 :speak nil))
      (setq local-pos (v+ local-pos (send local-cds :pos)))
      )
    (send local-cds :newcoords (make-coords :pos (scale 0.1 local-pos) :rpy (elt (send local-cds :rpy-angle) 0)))
    
    (send microwave-cds :move-to *pr2* :world)
    (send microwave-cds :transform local-cds)
    (send *microwave* :move-to microwave-cds :world)

    (send *microwave* :rotate pi/2 :y)
    (send *microwave* :rotate pi :x)
    (send *microwave* :translate (float-vector 0 370 -300))  ;; -220
    
    (setq *microwave-pos* (send *microwave* :pos))
    (setq *microwave-rpy* (send *microwave* :rpy-angle))
    )    
  )


;; put and take object funcs tmp 電子レンジ操作自体とは関係ない部分についての話
(defun kanazawa-pose ()
  (send *pr2* :angle-vector #f(100.161 75.0006 49.9994 109.993 -109.995 -19.9972 -10.0007 -9.99948 -40.1721 59.1602 -68.2551 -119.512 165.852 -64.9736 -220.86 -0.005299 51.906))
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )   

(defun kanazawa-put-object ()
  (send *ri* :start-grasp :rarm)
  (send *ri* :wait-interpolation)

  (send *microwave* :move-to (make-coords :pos *microwave-pos* :rpy (car *microwave-rpy*)) :world)
  (send *microwave* :angle-vector (float-vector 100))
    
  ;; pre-put2
  (send *pr2* :rarm :inverse-kinematics (send (send (send *microwave* :copy-worldcoords) :translate (float-vector -100 -210 180)) :rotate (deg2rad -90) :x) :rotation-axis t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;; put
  (send *pr2* :rarm :inverse-kinematics (send (send (send *microwave* :copy-worldcoords) :translate (float-vector 140 -210 160)) :rotate (deg2rad -90) :x) :rotation-axis t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :rarm :inverse-kinematics (send (send (send *microwave* :copy-worldcoords) :translate (float-vector 140 -210 150)) :rotate (deg2rad -90) :x) :rotation-axis t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :stop-grasp :rarm :wait t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *pr2* :rarm :inverse-kinematics (send (send (send *microwave* :copy-worldcoords) :translate (float-vector 0 -210 150)) :rotate (deg2rad -90) :x) :rotation-axis t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; post-put1
  (send *pr2* :rarm :inverse-kinematics (send (send (send *microwave* :copy-worldcoords) :translate (float-vector -100 -210 150)) :rotate (deg2rad -90) :x) :rotation-axis t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)

  ;; post-put2
  (send *pr2* :reset-pose)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)
  )

(defun kanazawa-take-object ()
  (kanazawa-pose)
  (send *ri* :stop-grasp :rarm)
  (send *ri* :wait-interpolation)

  (send *microwave* :move-to (make-coords :pos microwave-pos :rpy (car microwave-rpy)) :world)
  (send *microwave* :angle-vector (float-vector 100))

  ;; pre-put2
  (send *pr2* :rarm :inverse-kinematics (send (send (send *microwave* :copy-worldcoords) :translate (float-vector -100 -210 150)) :rotate (deg2rad -90) :x) :rotation-axis t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)

  ;; put
  (send *pr2* :rarm :inverse-kinematics (send (send (send *microwave* :copy-worldcoords) :translate (float-vector 140 -210 150)) :rotate (deg2rad -90) :x) :rotation-axis t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :rarm :inverse-kinematics (send (send (send *microwave* :copy-worldcoords) :translate (float-vector 140 -210 160)) :rotate (deg2rad -90) :x) :rotation-axis t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  (send *ri* :start-grasp :rarm :wait t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *pr2* :rarm :inverse-kinematics (send (send (send *microwave* :copy-worldcoords) :translate (float-vector 0 -210 160)) :rotate (deg2rad -90) :x) :rotation-axis t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)

  ;; post-put1
  (send *pr2* :rarm :inverse-kinematics (send (send (send *microwave* :copy-worldcoords) :translate (float-vector -100 -210 160)) :rotate (deg2rad -90) :x) :rotation-axis t)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 6000)
  (send *ri* :wait-interpolation)

  (kanazawa-pose)
  )

;; defun smach funcs
(defun microwave-smach-open ()
  (pub-msg "open")
  (send *ri* :speak-jp "電子レンジの扉を開けました．")
  )

(defun microwave-smach-close ()
  (pub-msg "close")
  (send *ri* :speak-jp "電子レンジの扉を閉めました．")
  )

(defun microwave-smach-panal (&rest args &key (panal :0s) &allow-other-keys) ;; 引数付きにする :panel (:0s,:500w,:170w,:1min,:2min,:3min,:4min,:heating)
  (cond
   ((equal heat :0s)
    (pub-msg "0s")
    (send *ri* :speak-jp "電子レンジを0の状態にしました．"))
   ((equal heat :500w)
    (pub-msg "500w")
    (send *ri* :speak-jp "電子レンジを500ワットに設定しました．"))
   ((equal heat :170w)
    (pub-msg "170w")
    (send *ri* :speak-jp "電子レンジを170ワットに設定しました．"))
   ((equal heat :1min)
    (pub-msg "1min")
    (send *ri* :speak-jp "電子レンジを1ふんに設定しました．"))
   ((equal heat :2min)
    (pub-msg "2min")
    (send *ri* :speak-jp "電子レンジを2ふんに設定しました．"))
   ((equal heat :3min)
    (pub-msg "3min")
    (send *ri* :speak-jp "電子レンジを3ふんに設定しました．"))
   ((equal heat :4min)
    (pub-msg "4min")
    (send *ri* :speak-jp "電子レンジを4ふんに設定しました．"))
   ((equal heat :heating)
    (pub-msg "heating")
    (send *ri* :speak-jp "電子レンジの加熱を開始しました．"))
   )
  )

(defun panel-rec2symbol (data)
  (cond
   ((equal data "/1m")
    (return-from panel-rec2symbol :1min))
   ((equal data "/2m")
    (return-from panel-rec2symbol :2min))
   ((equal data "/3m")
    (return-from panel-rec2symbol :3min))
   ((equal data "/4m")
    (return-from panel-rec2symbol :4min))
   ((equal data "/5m")
    (return-from panel-rec2symbol :5min))
   )
  )

(defun microwave-smach-finish ()
  (pub-msg "finish")
  (send *ri* :speak-jp "電子レンジの操作を修了しました．")
  )


;; now codes 連続の電子レンジ操作のプログラムを書く とりあえず押し間違えを考えないバージョン
(defun now-microwave-test ()
  ;; recognition
  (microwave-pos-recogniton) ;; 位置を認識
  
  ;; open and close microwave
  (open-microwave) ;;扉をあける
  (microwave-smach-open)
  (close-microwave) ;;扉を閉める
  (microwave-smach-close)
  
  ;; push button この部分は今までのを参考にして書く とりあえず押し間違えを考えないバージョン
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (push-500w-button)
    (read-panel)
    (if (equal *data* "/500w")
        (setq *push-flag* t))
    )

  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (push-1min-button)
    (read-panel)
    (if (equal *data* "/1m")
        (setq *push-flag* t))
    )
  
  (setq *tmp-data* *data*)
  
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (push-start-button)
    (read-panel)
    (if (or (equal *data* "/start") (not (equal *data* *tmp-data*)))
        (setq *push-flag* t))
    )
  
  ;; wait for heating
  (unix::sleep (* 2 60))
  
  ;; open and close microwave
  (open-microwave)
  (microwave-smach-open)
  )


(defun now-start-microwave ()
  ;; recognition
  (microwave-pos-recogniton) ;; 位置を認識
  
  ;; open and close microwave
  (open-microwave) ;;扉をあける
  (microwave-smach-open)
  (close-microwave) ;;扉を閉める
  (microwave-smach-close)
  )

(defun now-microwave-min (&rest args &key (min 2) &allow-other-keys) ;; 引数は将来的には170wとかの押し間違いにも対応したい．(w 170)
  ;; min分にする
  (setq *set-flag* nil)
  (until *set-flag*
         (read-panel)
         (cond 
          ((equal *data* "/0s")
           (microwave-smach-panel :panel :0s)
           (push-500w-button);; 500wボタンを押す
           )
          ((equal *data* "/170w")
           (microwave-smach-panel :panel :170w)
           (push-500w-button);; 500wボタンを押す
           )
          ((equal *data* "/500w")
           (microwave-smach-panel :panel :500w)
           (push-1min-button);; 1minボタンを押す
           )
          ((and (substringp "m" hoge) (equal (substringp "s" hoge) nil))
           (cond
            ((equal (min-check *data*) :equal);; 分数が一致した時
             (microwave-smach-panel :panel (panel-rec2symbol *data*))
             (setq *set-flag* t);;これを抜ける
             )
            ((equal (min-check *data*) :lack);; 分数が足りなかった時
             (microwave-smach-panel :panel (panel-rec2symbol *data*))
             (push-1min-button);; 1minボタンを押す
             )
            ((equal (min-check *data*) :over);; 分数がオーバーした時
             (microwave-smach-panel :panel (panel-rec2symbol *data*))
             (push-reset-button);; リセットボタンを押す
             )
            )
           )
          ((and (substringp "m" hoge) (substringp "s" hoge)) ;;1m59sとか
           ;; 何もしないで認識しなおし
           (warn "recog fail ~%")
           )
          ))
  
  ;; startボタンを押してスタートさせる
  (setq *tmp-data* *data*)
  (setq *push-flag* nil)
  (while (eql *push-flag* nil)
    (push-start-button)
    (read-panel)
    (if (or (or (equal *data* "/1m59s") (equal *data* "/2m59s")) (not (equal *data* *tmp-data*))) ;;ここは調整必要そう
        (progn
          (setq *push-flag* t)
          (microwave-smach-panel :panel :heating)
          )
      )
    )
  )

(defun now-end-microwave ()
  ;; open and close microwave
  (open-microwave) ;;扉をあける
  (microwave-smach-open)
  (close-microwave) ;;扉を閉める
  (microwave-smach-close)
  (microwave-smach-finish)
  )

(defun now-microwave-all ()
  (now-start-microwave)
  (now-microwave-min)
  (now-end-microwave)
  )

(defun now-micro-sato () ;; サトウのご飯
  ;; put object in microwave  
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-put-object)
  (send *pmi* :close-microwave)
  
  ;; push button
  (send *pmi* :push-500w-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-start-button)
  
  ;; wait for heating
  (unix::sleep (* 2 60))

  ;; take object from microwave
  (send *pmi* :open-microwave)
  )

(defun hot-veg-micro () ;; 温野菜の温める
  ;; put object in microwave
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-put-object)
  (send *pmi* :close-microwave)
  
  ;; push button
  (send *pmi* :push-500w-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-1min-button)
  (send *pmi* :push-start-button)
  
  ;; wait for heating
  (unix::sleep (* 3 60))
  
  ;; take object from microwave
  (send *pmi* :open-microwave)
  (send *pmi* :kanazawa-take-object)
  (send *pmi* :close-microwave)
  )

