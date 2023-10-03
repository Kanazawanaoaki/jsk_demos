#!/usr/bin/env roseus

(setq *exit-on-end* (string= "__log:=" (subseq (car (last lisp::*eustop-argument*)) 0 7)))

(load "package://pddl_planner/src/pddl-result-graph.l")
(load "package://pddl_planner/src/eus-pddl-client.l")

;;
;; problem
;;
(setq *mix-testproblem* (instance pddl-problem :init :name 'mix_tmp :domain 'mix_test))

;;使用する変数の宣言
(send *mix-testproblem* :objects
      '((EGG . object)))

;;初期条件
(send *mix-testproblem* :initial-condition
      ;; '((IN MILK BOWL)
      ;;   (IN EGG BOWL)
      ;;   ))
      '((IN MILK CUP)
        (IN EGG BOWL)
        ))

;;終了条件
(send *mix-testproblem* :goal-condition
      '((IN EGG-MIXTURE BOWL)
        (MIXED EGG-MIXTURE MILK EGG)
        ))

;;
;; domain
;;
(setq *domain* (instance pddl-domain :init :name 'mix_test))
(send *domain* :requirements '(:typing))
(send *domain* :types '(object vessel))
(send *domain* :constants '(EGG MILK EGG-MIXTURE - object BOWL CUP - vessel))
(send *domain* :predicates '((IN ?obj - object ?vessel - vessel)
                             (MIXED ?mixture - object ?ing1 - object ?ing2 - object)
                             ))
;;making action
(setq *actions*
      (list
       (instance pddl-action :init
                 :name "transfer"
                 :parameters '((?CONTENT object) (?FROM ?TO  vessel))
                 :precondition '((IN ?CONTENT ?FROM)
                                 )
                 :effect '((IN ?CONTENT ?TO)
                           (NOT (IN ?CONTENT ?FROM))))
       (instance pddl-action :init
                 :name "mix"
                 :parameters '((?MIXTURE ?ING-ONE ?ING-TWO object) (?VESSEL vessel))
                 :precondition '((IN ?ING-ONE ?VESSEL)
                                 (IN ?ING-TWO ?VESSEL)
                                 (NOT (= ?ING-ONE ?ING-TWO))
                                 (NOT (IN ?MIXTURE ?VESSEL))
                                 (NOT (MIXED ?MIXTURE ?ING-ONE ?ING-TWO))
                                 )
                 :effect '((MIXED ?MIXTURE ?ING-ONE ?ING-TWO)
                           (IN ?MIXTURE ?VESSEL)
                           (NOT (IN ?ING-ONE ?VESSEL))
                           (NOT (IN ?ING-TWO ?VESSEL))
                           ))
       ))

;;add action to domain
(dolist (act *actions*)
  (send *domain* :add :action act))

;;
;; solve planning
;;
(pprint (setq *result0* (solve-pddl-planning *domain* *mix-testproblem*)))

(setq gr (make-graph-from-pddl-results (list *result0*) :node-name :pprint))

(send gr :write-to-pdf "mix_test.pdf")

(when (ros::get-param "~display_graph" "true")
  (piped-fork "xdg-open mix_test.pdf"))

(if *exit-on-end* (ros::exit))
