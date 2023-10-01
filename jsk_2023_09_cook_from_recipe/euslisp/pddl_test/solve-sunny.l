#!/usr/bin/env roseus

(setq *exit-on-end* (string= "__log:=" (subseq (car (last lisp::*eustop-argument*)) 0 7)))

(load "package://pddl_planner/src/pddl-result-graph.l")
(load "package://pddl_planner/src/eus-pddl-client.l")

;;
;; domain
;;
(setq *domain* (instance pddl-domain :init :name 'kanazawa_cook))
(send *domain* :requirements '(:typing))
(send *domain* :types '(object spot arm how state))
(send *domain* :constants '(OIL EGG FRYING-PAN - object LARM RARM - arm STOVE - spot THIRTY-SECONDS - how COOKED-EGG - state))
(send *domain* :predicates '((ON ?obj - object ?spot - spot)
                             (IN ?obj1 - object ?obj2 - object)
                             (ROBOT-AT ?spot - spot)
                             (HOLD ?obj - object ?arm - arm)
                             (HEATED ?obj - object ?how - how)
                             (COOKED ?obj - object ?state - state)
                             (WATERFLOW)
                             (STOVE-ON)
                             (WASHED ?obj - object)
                             ))
;;making action
(setq *actions*
      (list
       (instance pddl-action :init
                 :name "hold"
                 :parameters '((?OBJECT object) (?ARM arm) (?SPOT spot))
                 :precondition '((ON ?OBJECT ?SPOT)
                                 (ROBOT-AT ?SPOT))
                 :effect '((HOLD ?OBJECT ?ARM)
                           (NOT (ON ?OBJECT ?SPOT))))
       (instance pddl-action :init
                 :name "place"
                 :parameters '((?OBJECT object) (?ARM arm) (?SPOT spot))
                 :precondition '((HOLD ?OBJECT ?ARM)
                                 (ROBOT-AT ?SPOT))
                 :effect '((NOT (HOLD ?OBJECT ?ARM))
                           (ON ?OBJECT ?SPOT)))
       (instance pddl-action :init
                 :name "move-to"
                 :parameters '((?FROM ?TO spot))
                 :precondition '((ROBOT-AT ?FROM))
                 :effect '((ROBOT-AT ?TO)
                           (NOT (ROBOT-AT ?FROM))))
       (instance pddl-action :init
                 :name "open-tap"
                 :parameters '()
                 :precondition '((ROBOT-AT SINK)
                                 (NOT (WATERFLOW)))
                 :effect '((WATERFLOW)))
       (instance pddl-action :init
                 :name "close-tap"
                 :parameters '()
                 :precondition '((ROBOT-AT SINK)
                                 (WATERFLOW))
                 :effect '((NOT (WATERFLOW))))
       (instance pddl-action :init
                 :name "turn-on-stove"
                 :parameters '()
                 :precondition '((ROBOT-AT STOVE)
                                 (NOT (STOVE-ON)))
                 :effect '((STOVE-ON)))
       (instance pddl-action :init
                 :name "turn-off-stove"
                 :parameters '()
                 :precondition '((ROBOT-AT STOVE)
                                 (STOVE-ON))
                 :effect '((NOT (STOVE-ON))))
       (instance pddl-action :init
                 :name "wash"
                 :parameters '((?OBJECT object) (?ARM arm))
                 :precondition '((HOLD ?OBJECT ?ARM)
                                 (ROBOT-AT SINK)
                                 (WATERFLOW)
                                 (NOT (WASHED ?OBJECT)))
                 :effect '((WASHED ?OBJECT)))

       (instance pddl-action :init
                 :name "pour"
                 :parameters '((?FROM ?TO object) (?ARM arm) (?SPOT spot))
                 :precondition '((HOLD ?FROM ?ARM)
                                 (ROBOT-AT ?SPOT)
                                 (ON ?TO ?SPOT)
                                 )
                 :effect '((IN ?FROM ?TO)))
       (instance pddl-action :init
                 :name "heat"
                 :parameters '((?OBJECT object) (?HOW how))
                 :precondition '((IN ?OBJECT FRYING-PAN)
                                 (ON FRYING-PAN STOVE)
                                 (ROBOT-AT STOVE)
                                 (STOVE-ON)
                                 )
                 :effect '((HEATED ?OBJECT ?HOW)
                           ))
       (instance pddl-action :init
                 :name "cook"
                 :parameters '((?OBJECT object) (?STATE state))
                 :precondition '((IN ?OBJECT FRYING-PAN)
                                 (ON FRYING-PAN STOVE)
                                 (ROBOT-AT STOVE)
                                 (STOVE-ON)
                                 )
                 :effect '((COOKED ?OBJECT ?STATE)
                           ))
       ))

;;add action to domain
(dolist (act *actions*)
  (send *domain* :add :action act))



;;
;; problem and solve
;;
(setq *cooking-variables* '((STOVE . spot)
                            (SINK . spot)
                            (KITCHEN . spot)
                            ))

;; 調理の初期条件
(setq *cooking-initial-condision* '((ROBOT-AT STOVE)
                                    (ON OIL STOVE)
                                    (ON EGG STOVE)
                                    (ON FRYING-PAN STOVE)
                                    (NOT (STOVE-ON))
                                    ))
;; 調理レシピ記述から
(setq *cooking-target-conditions* (list '((IN OIL FRYING-PAN) ;; pour(salad oil, frying pan)
                                    (ON OIL STOVE)
                                    (ON FRYING-PAN STOVE))
                                  '((IN OIL FRYING-PAN) ;; heat(oil, 30 seconds)
                                    (ON FRYING-PAN STOVE)
                                    (HEATED OIL THIRTY-SECONDS))
                                  '((IN EGG FRYING-PAN) ;; pour(egg, frying pan)
                                    (ON EGG STOVE)
                                    (ON FRYING-PAN STOVE))
                                  '((IN EGG FRYING-PAN) ;; cook(egg, cooked egg)
                                    (ON EGG STOVE)
                                    (COOKED EGG COOKED-EGG))
                                  '((NOT (STOVE-ON)) ;; end
                                    (NOT (WATERFLOW)))
                                  ))

(setq *cooking-result-list* (list))
(setq current-condition *cooking-initial-condision*)

(dolist (current-target *cooking-target-conditions*)
  (setq current-problem (instance pddl-problem :init :name 'current_problem :domain 'kanazawa_cook))
  (send current-problem :objects *cooking-variables*)
  (send current-problem :initial-condition current-condition)
  (send current-problem :goal-condition current-target)
  (pprint (setq current-result (solve-pddl-planning *domain* current-problem)))
  (setq current-condition (elt (elt current-result 1) (- (length (elt current-result 1) ) 1)))
  (setq *cooking-result-list* (append *cooking-result-list* (list current-result)))
  )


(setq gr (make-graph-from-pddl-results *cooking-result-list* :node-name :pprint))

(send gr :write-to-pdf "kanazawa_cook.pdf")

(when (ros::get-param "~display_graph" "true")
  (piped-fork "xdg-open kanazawa_cook.pdf"))

;; (if *exit-on-end* (ros::exit))
