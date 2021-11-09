(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/furniture-appliances-demo/graph-appliances/ih-stove-smach.l")

(setq *g* (ih-stove-smach-test))
(setq *solver* (instance breadth-first-graph-search-solver))

(defmethod state-machine
  (:goal-test ;; override may not work original code                                                                            
   (gs)
   (equal (send (car goal-state) :name) gs))
  )

;; (setq *solver* (instance breadth-first-graph-search-solver))
;; (send *g* :start-state (send *g* :node :off))
;; (send *g* :goal-state (send *g* :node :high-heat))
;; (setq path (send *solver* :solve *g* :verbose t))
;; (when path
;;   (print 'solution)
;;   (print (send-all path :state))
;;   (print (send-all path :action))
;;   )


(defun ih-stove-solver (&key (start :off) (goal :high-heat))
  (send *g* :start-state (send *g* :node :off))
  (send *g* :goal-state (send *g* :node :high-heat))
  (setq path (send *solver* :solve *g* :verbose t))
  (when path
    (print 'solution)
    (print (send-all path :state))
    (print (send-all path :action))
    )
  path
  )

(defun action-from-path (path)
  (let (action-name)
    (dolist (solver-node path)
      (setq action-name (send (send solver-node :action) :name))
      (if action-name
          (print action-name)
        )
      )
    ))
;; todo action-name，どこからどこへの変化かを考えて，それで作業をする．
  
(warn "please run (ih-stove-solver) ~%")


(defun now-test ()
  (setq ih-path (ih-stove-solver))
  (action-from-path ih-path)
  )
