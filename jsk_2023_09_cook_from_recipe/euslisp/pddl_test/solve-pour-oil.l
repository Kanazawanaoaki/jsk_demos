#!/usr/bin/env roseus

(setq *exit-on-end* (string= "__log:=" (subseq (car (last lisp::*eustop-argument*)) 0 7)))

(load "package://pddl_planner/src/pddl-result-graph.l")
(load "package://pddl_planner/src/eus-pddl-client.l")

;;
;; domain
;;
(setq *domain* (instance pddl-domain :init :name 'kanazawa_cook))
(send *domain* :requirements '(:typing))
(send *domain* :types '(object spot arm how))
(send *domain* :constants '(OIL FRYING-PAN - object LARM RARM - arm STOVE - spot THIRTY-SECONDS - HOW))
(send *domain* :predicates '((ON ?obj - object ?spot - spot)
                             (IN ?obj1 - object ?obj2 - object)
                             (ROBOT-AT ?spot - spot)
                             (HOLD ?obj - object ?arm - arm)
                             (HEAT ?obj - object ?how - how)
                             ;; (HEAT ?obj - object)
                             (WATERFLOW)
                             (STOVE-ON)
                             (WASHED ?obj - object)
                             (POURED ?obj - object)
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
                 ;; :name "turn-on-stove"
                 :name "stove-on"
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
                 :name "wash-cup"
                 :parameters '((?OBJECT object))
                 :precondition '((HOLD ?OBJECT LARM)
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
                 :effect '((HEAT ?OBJECT ?HOW)
                           ))
       ))

;;add action to domain
(dolist (act *actions*)
  (send *domain* :add :action act))



;;
;; problem
;;
(setq *pour-oil-problem* (instance pddl-problem :init :name 'pour_oil :domain 'kanazawa_cook))

;;使用する変数の宣言
(send *pour-oil-problem* :objects
      '((STOVE . spot)
        (SINK . spot)
        (KITCHEN . spot)))

;;初期条件
(send *pour-oil-problem* :initial-condition
      '((ROBOT-AT STOVE)
        (ON OIL STOVE)
        (ON FRYING-PAN STOVE)
        (NOT (STOVE-ON))
        ))

;;終了条件
(send *pour-oil-problem* :goal-condition
      '((IN OIL FRYING-PAN)
        (ON OIL STOVE)
        (NOT (STOVE-ON))
        (ON FRYING-PAN STOVE)))


(setq *heat-oil-problem* (instance pddl-problem :init :name 'heat_oil :domain 'kanazawa_cook))

;;使用する変数の宣言
(send *heat-oil-problem* :objects
      '((STOVE . spot)
        (SINK . spot)
        (KITCHEN . spot)))

;;初期条件
(send *heat-oil-problem* :initial-condition
      '((ROBOT-AT STOVE)
        (IN OIL FRYING-PAN)
        (ON OIL STOVE)
        ;; (NOT (STOVE-ON))
        (ON FRYING-PAN STOVE)))

;; (elt (elt *result0* 1) (- (length (elt *result0* 1) ) 1))

;;終了条件
(send *heat-oil-problem* :goal-condition
      '((IN OIL FRYING-PAN)
        (ON OIL STOVE)
        (ON FRYING-PAN STOVE)
        (STOVE-ON)
        (HEAT OIL THIRTY-SECONDS)
        ;; (HEAT OIL)
        ))


;;
;; solve planning
;;

(pprint (setq *result0* (solve-pddl-planning *domain* *pour-oil-problem*)))


(pprint (setq *result1* (solve-pddl-planning *domain* *heat-oil-problem*)))

(setq gr (make-graph-from-pddl-results (list *result0* *result1*) :node-name :pprint))
;; (setq gr (make-graph-from-pddl-results (list *result0*) :node-name :pprint))

(send gr :write-to-pdf "kanazawa_cook.pdf")

(when (ros::get-param "~display_graph" "true")
  (piped-fork "xdg-open kanazawa_cook.pdf"))

;; (if *exit-on-end* (ros::exit))
