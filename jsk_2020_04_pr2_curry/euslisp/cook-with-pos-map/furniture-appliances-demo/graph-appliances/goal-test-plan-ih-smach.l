(load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/furniture-appliances-demo/graph-appliances/ih-stove-smach.l")

(setq *g* (ih-stove-smach-test))

(defmethod state-machine
  (:goal-test ;; override may not work original code                                                                            
   (gs)
   (equal (send (car goal-state) :name) gs))
  )

(setq *solver* (instance breadth-first-graph-search-solver))
;; (send *g* :start-state (send *g* :node :low-heat))
(send *g* :start-state (send *g* :node :off))
(send *g* :goal-state (send *g* :node :high-heat))
(setq path (send *solver* :solve *g* :verbose t))
(when path
  (print 'solution)
  (print (send-all path :state))
  (print (send-all path :action))
  )
