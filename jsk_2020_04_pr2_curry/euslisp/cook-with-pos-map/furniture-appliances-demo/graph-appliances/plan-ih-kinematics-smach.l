(defun plan-ih-kinematics-init ()
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/furniture-appliances-demo/graph-appliances/ih-stove-smach.l")
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/furniture-appliances-demo/graph-appliances/ih-stove-kinematics-action.l")
  (additional-init)

  ;; def ih-stove smach graph
  (setq *g* (ih-stove-smach-test))
  (defmethod state-machine
    (:goal-test ;; override may not work original code                                                                            
     (gs)
     (equal (send (car goal-state) :name) gs))
    )

  )
(plan-ih-kinematics-init)


(defun ih-stove-solver (&rest args &key (start :off) (goal :high-heat) &allow-other-keys)
  (setq *solver* (instance breadth-first-graph-search-solver))
  (send *g* :start-state (send *g* :node start))
  (send *g* :goal-state (send *g* :node goal))
  (setq path (send *solver* :solve *g* :verbose t))
  (when path
    (print 'solution)
    (print (send-all path :state))
    (print (send-all path :action))
    )
  path
  )

(defun action-from-path (path)
  (let (action-name action-from action-to)
    (dolist (solver-node path)
      (setq action-name (send (send solver-node :action) :name))
      (if action-name
          (progn
            (setq func-name (read-from-string (format nil "~A-action" (string-downcase (string action-name)))))
            (setq action-from (send (send (send solver-node :action) :from) :name))
            (setq action-to (send (send (send solver-node :action) :to) :name))
            (funcall (read-from-string (format nil "~A :from ~A :to ~A" func-name action-from action-to)))
            )
        )
      )
    ))

(defun action-ih (&rest args &key (start :off) (goal :high-heat) &allow-other-keys)
  (setq ih-path (ih-stove-solver :start start :goal goal))
  (action-from-path ih-path)
  )

(warn "please run (action-ih) ~%")


;; def now codes
(defun now-test ()
  (action-ih :start :off :goal :low-heat)
  )


(defun now-on-ih ()
  (action-ih :start :off :goal :medium-heat)
  )

(defun now-stop-ih ()
  (action-ih :start :medium-heat :goal :off)  
  )
