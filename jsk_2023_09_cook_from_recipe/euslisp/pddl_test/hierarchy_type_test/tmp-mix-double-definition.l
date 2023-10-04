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
      '((EGG . ingredient)
        ))

;;初期条件
(send *mix-testproblem* :initial-condition
      '((IN MILK CUP)
        (IN EGG BOWL)
        ))

;;終了条件
(send *mix-testproblem* :goal-condition
      '((IN EGG-MIXTURE BOWL)
        (MIXED EGG-MIXTURE MILK EGG)
        (COOKED EGG-MIXTURE COOKED)
        ))

;;
;; domain
;;
(setq *domain* (instance pddl-domain :init :name 'mix_test))
(send *domain* :requirements '(:typing))
;; (send *domain* :types '(object ingredient vessel state))
;; (send *domain* :constants '(EGG MILK EGG-MIXTURE - ingredient BOWL CUP - vessel COOKED - state))
(send *domain* :types '(ingredient vessel tool  - object
                                   mixutre - ingredient ;; これは意味ない
                                   state))
;; (send *domain* :constants '(EGG MILK - ingredient EGG-MIXTURE - mixture BOWL CUP - vessel COOKED - state))
(send *domain* :constants '(EGG MILK EGG-MIXTURE - ingredient EGG-MIXTURE - mixture BOWL CUP - vessel COOKED - state))

(send *domain* :predicates '((IN ?obj - ingredient ?vessel - vessel)
                             ;; (MIXED ?mixture - ingredient ?ing1 - ingredient ?ing2 - ingredient)
                             (MIXED ?mixture - mixture ?ing1 - ingredient ?ing2 - ingredient)
                             (COOKED ?ing - ingredient ?state - state)
                             ))
;;making action
(setq *actions*
      (list
       (instance pddl-action :init
                 :name "transfer"
                 :parameters '((?CONTENT ingredient) (?FROM ?TO  vessel))
                 :precondition '((IN ?CONTENT ?FROM)
                                 )
                 :effect '((IN ?CONTENT ?TO)
                           (NOT (IN ?CONTENT ?FROM))))
       (instance pddl-action :init
                 :name "mix"
                 ;; :parameters '((?MIXTURE ?ING-ONE ?ING-TWO ingredient) (?VESSEL vessel))
                 :parameters '((?MIXTURE mixture) (?ING-ONE ?ING-TWO ingredient) (?VESSEL vessel))
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
       (instance pddl-action :init
                 :name "cook"
                 :parameters '((?OBJECT ingredient) (?STATE state) (?VESSEL vessel))
                 :precondition '((NOT (COOKED ?OBJECT ?STATE))
                                 (IN ?OBJECT ?VESSEL)
                                 )
                 :effect '((COOKED ?OBJECT ?STATE)
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
