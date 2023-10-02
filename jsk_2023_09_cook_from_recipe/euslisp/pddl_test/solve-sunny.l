#!/usr/bin/env roseus

(setq *exit-on-end* (string= "__log:=" (subseq (car (last lisp::*eustop-argument*)) 0 7)))

(load "package://pddl_planner/src/pddl-result-graph.l")
(load "package://pddl_planner/src/eus-pddl-client.l")

;; load domain
(load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/cooking-pddl-domain.l")

;;
;; problem and solve
;;

;;set cooking-variables
(setq *cooking-variables* '((OIL . object)
                            (EGG . object)
                            (THIRTY-SECONDS . how)
                            (COOKED-EGG . state)
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
                                          (ON EGG STOVE) ;; TODO need update
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

(send gr :write-to-pdf "kanazawa_cook_sunny.pdf")

(when (ros::get-param "~display_graph" "true")
  (piped-fork "xdg-open kanazawa_cook_sunny.pdf"))

(if *exit-on-end* (ros::exit))
