(defun swing-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")

  (move-to-kitchen-irt)
  (objects (list *pr2* *scene*))
  (update-view)
  )

(swing-init)


(defun knife-touch-swing-set ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")
  
  
  (warn "please start to record rosbag and run (knife-touch-swing) ~%")
  )


(defun knife-touch-swing ()
  
  )
