(defun ih-primitive-init () ;; ihの動作部分だけをプリミティブを使って書く用にする．
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/my-cook-primitive-funcs.l")
  (load "package://jsk_2020_04_pr2_curry/euslisp/smach-test/furniture-appliances/ros-topic-test/smach_state_msg-publisher.l")
  
  (setq *ih-panel-coords* (make-coords :pos (float-vector 563 7940 30865) :rpy (float-vector  3.044 1.407 2.87)))
  
  (move-to-stove-irt)
  (objects (list *pr2* *scene*))
  (update-view)
  )

(ih-primitive-init)

(defun ready-pose ()
  (move-arm-av #f(117.007 48.3805 113.439 -103.326 38.7107 -5.72958 14.4628) :arm :larm :times 4000) ;;move-arm primitive
  )

(defun push-knob ()  
  ;; (send *ri* :start-grasp :larm :wait t) ;; grasp primitive?
  (move-gripper-func 0 :arm :larm) ;; move-gripper primitive
  
  (send *arrow* :newcoords (send *ih-knob-coords* :copy-worldcoords))
  (push-primitive (send *ih-knob-coords* :copy-worldcoords) :arm :larm :w-thre -15 :axis :x) ;; push-primitive
  
  (send *arrow* :newcoords (send *ih-knob-coords* :copy-worldcoords))
  (send *arrow* :translate #f(-100 0 0))
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm :times 4000)
  )

(defun grasp-knob ()
  (move-gripper-func 0.08 :arm :larm) ;; move-gripper primitive
  
  (send *arrow* :newcoords (send *ih-knob-coords* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 90) :x)
  (send *arrow* :translate #f(100 0 0) :world)
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm) ;;move-arm primitive
    
  (send *arrow* :newcoords (send *ih-knob-coords* :copy-worldcoords))
  (push-primitive (send *ih-knob-coords* :copy-worldcoords) :arm :larm :w-thre -15 :axis :x) ;; push-primitive
  
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(10 0 0) :world)
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm) ;;move-arm primitive
  
  (grasp-object :arm :larm :gain 100) ;;grasp-object primitive
  )

(defun rotate-knob (&rest args &key (deg 30) &allow-other-keys)
  ;; rotate
  (setq avs (list))
  (setq tms (list))

  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))

  (cond
   ((> deg 0)
    (dotimes (i (/ deg 10))
      (send *arrow* :rotate (deg2rad 10) :x)
      (send *pr2* :larm :inverse-kinematics
            (send *arrow* :copy-worldcoords)
            :rotation-axis t
            :debug-view nil)
      (setq av (send *pr2* :angle-vector))
      (setq avs (append avs (list av)))
      (setq tms (append tms (list 200)))
      ))
   ((< deg 0)
    (dotimes (i (/ (* deg -1) 10))
      (send *arrow* :rotate (deg2rad -10) :x)
      (send *pr2* :larm :inverse-kinematics
            (send *arrow* :copy-worldcoords)
            :rotation-axis t
            :debug-view nil)
      (setq av (send *pr2* :angle-vector))
      (setq avs (append avs (list av)))
      (setq tms (append tms (list 200)))
      ))
   )

  (unless (equal deg 0)
    (move-object-avs avs tms) ;; move-arm primitive? move object primitive?
    )
  )

(defun release-knob ()
  (send *ri* :stop-grasp :larm :wait t)
  
  (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(30 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)

  (send *arrow* :newcoords (send *ih-knob-coords* :copy-worldcoords))
  (send *arrow* :rotate (deg2rad 90) :x)
  (send *arrow* :translate #f(100 0 0) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *ri* :angle-vector (send *pr2* :angle-vector))
  (send *ri* :wait-interpolation)
  )

;; now codes 連続のIHコンロ操作のプログラムを書く．
(defun now-start-ih ()
  
  )


;; ih-use-stove-codes.lの中にある プログラム．
(defun now-start-ih-with-fail-detection (&rest args &key (deg -10) &allow-other-keys)
  (set-pose-3)
  (push-knob)

  (grasp-knob)
  ;; 失敗を検知する
  (grasp-fail-detection-larm :g-thre 10)
  (if (equal *fail-flag* t) ;; 一度失敗したらもう一度挑戦する
      (progn
        (release-knob)
        (push-knob)
        (grasp-knob)
        (grasp-fail-detection-larm :g-thre 10)
        (if (equal *fail-flag* t) ;; 二度失敗したら人に助けてもらう
            (progn
              (release-knob)
              (set-pose-3)
              (send *ri* :speak-jp "IHコンロのつまみの操作に失敗しました，コンロをつけて合図をして下さい")
              (ok-wait)
              (return-from now-start-ih-with-fail-detection)))
        ))
  
  (rotate-knob :deg 30)
  (rotate-knob :deg deg)
  (release-knob)
  (set-pose-3)
  )



