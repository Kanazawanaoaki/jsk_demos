#!/usr/bin/env roseus

(load "package://pddl_planner/src/pddl-result-graph.l")
(load "package://pddl_planner/src/eus-pddl-client.l")

;;
;; problem
;;
(setq *boil-water-ih-problem* (instance pddl-problem :init :name 'boil_water_ih :domain 'kanazawa_ih))

;;使用する変数の宣言
(send *boil-water-ih-problem* :objects
      '((WATER . object)
        (POT . object)
        (IH . object) ;; 家電？
        )
      )

;;初期条件
(send *boil-water-ih-problem* :initial-condition
      '(;;(NORMAL WATER)
        (ON POT IH)
        (IH-OFF IH)))

;;終了条件
(send *boil-water-ih-problem* :goal-condition
      '((BOILED WATER)
        (IH-OFF IH)))

;;
;; domain
;;
(setq *domain* (instance pddl-domain :init :name 'kanazawa_ih))
(send *domain* :requirements '(:typing))
(send *domain* :types '(object))
(send *domain* :constants '(WATER POT IH - object))
(send *domain* :predicates '((ON ?obj0 ?obj1 - object)
                             (IN ?obj0 ?obj1 - object)
                             (IH-OFF ?obj - object)
                             (IH-ON ?obj - object)
                             (BOILED ?obj - object)
                             ))

;;making action
(setq *actions*
      (list
       (instance pddl-action :init
                 :name "water-in"
                 :parameters '((?OBJECT object))
                 :precondition '((NOT (IN WATER ?OBJECT))
                                 )
                 :effect '((IN WATER ?OBJECT)
                           ))
       (instance pddl-action :init
                 :name "heat-ih"
                 :parameters '()
                 :precondition '((IH-OFF IH)
                                 )
                 :effect '((IH-ON IH)
                           (NOT (IH-OFF IH))
                           ))
       (instance pddl-action :init
                 :name "boil-water"
                 :parameters '()
                 :precondition '((NOT (BOILED WATER))
                                 (IN WATER POT)
                                 (ON POT IH)
                                 (IH-ON IH)
                                 )
                 :effect '((BOILED WATER)
                           ))
       (instance pddl-action :init
                 :name "stop-ih"
                 :parameters '()
                 :precondition '((IH-ON IH)
                                 )
                 :effect '((IH-OFF IH)
                           (NOT (IH-ON IH))
                           ))
       ))

;;add action to domain
(dolist (act *actions*)
  (send *domain* :add :action act))

;;
;; solve planning
;;
(pprint (setq *result* (solve-pddl-planning *domain* *boil-water-ih-problem*)))

(setq gr (make-graph-from-pddl-results (list *result*) :node-name :pprint))

(send gr :write-to-pdf "kanazaw_ih.pdf")

(when (ros::get-param "~display_graph" "true")
  (piped-fork "xdg-open kanazaw_ih.pdf"))

(when (string= "__log:=" (subseq (car (last lisp::*eustop-argument*)) 0 7))
  (ros::exit))

