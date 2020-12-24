(defun swing-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")

  ;; 揺するやつ
  (load "package://jsk_demo_common/euslisp/pr2-action.l")
  
  (move-to-kitchen-irt)
  (objects (list *pr2* *scene*))
  (update-view)
  )

(swing-init)

(defun grasp-swing-rarm (&rest args &key (times 10) &allow-other-keys)
  (set-pose)
  (setq *data-list* (list))
  
  ;; 開閉を繰り返す
  (dotimes (i times)
    (send *ri* :stop-grasp :rarm :wait t)
    (send *ri* :start-grasp :rarm :wait t)
    (setq data (send *ri* :state :gripper :rarm :position))
    (setq *data-list* (append *data-list* (list data)))
    )
  
  (print *data-list*)
  )

(defun grasp-swing-larm (&rest args &key (times 10) &allow-other-keys)
  (set-pose)
  (setq *data-list* (list))
  
  ;; 開閉を繰り返す  
  (dotimes (i times)
    (send *ri* :stop-grasp :larm :wait t)
    (send *ri* :start-grasp :larm :wait t)
    (setq data (send *ri* :state :gripper :larm :position))
    (setq *data-list* (append *data-list* (list data)))
    )
  
  (print *data-list*)
  )


(defun knife-touch-swing-set ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")

  (set-pose)
  
  ;; (send *pr2* :rarm :angle-vector #f())

  ;; 包丁を受け取る
  
  ;; 揺すられるまで待つ．
  (wait-for-hand-impact :larm)
  
  (warn "please start to record rosbag and run (knife-touch-swing) ~%")
  )


(defun knife-touch-swing ()
  
  )

