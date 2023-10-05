#!/usr/bin/env roseus

(setq *exit-on-end* (string= "__log:=" (subseq (car (last lisp::*eustop-argument*)) 0 7)))

(load "package://pddl_planner/src/pddl-result-graph.l")
(load "package://pddl_planner/src/eus-pddl-client.l")

;; load domain
(load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/cooking-pddl-domain.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/cooking-pddl-utils.l")

;;
;; problem and solve
;;

(setq *file-name* "kanazawa_cook_sunny_side_up.pdf")

;;set cooking-variables
(setq *cooking-variables* '((OIL . ingredient)
                            (EGG . ingredient)
                            (THIRTY-SECONDS . state)
                            (COOKED-EGG . state)
                            ))

;; 調理の初期条件
(setq *cooking-initial-condition* '((ROBOT-AT STOVE)
                                    (ON OIL STOVE)
                                    (IN EGG BOWL)
                                    (ON BOWL STOVE)
                                    (ON FRYING-PAN STOVE)
                                    (NOT (STOVE-ON))
                                    ))

;; 調理レシピ記述から
(setq *cooking-target-conditions* (list '((IN OIL FRYING-PAN) ;; pour(salad oil, frying pan)
                                          ;; (ON OIL STOVE)
                                          ;; (ON FRYING-PAN STOVE)
                                          (NOT (HOLD-OBJECT ARM1))
                                          (NOT (HOLD-OBJECT ARM2))
                                          )
                                        '((IN OIL FRYING-PAN) ;; heat(oil, 30 seconds)
                                          (NOT (HOLD-OBJECT ARM1))
                                          (NOT (HOLD-OBJECT ARM2))
                                          (HEATED OIL THIRTY-SECONDS))
                                        '((IN EGG FRYING-PAN) ;; pour(egg, frying pan)
                                          (NOT (HOLD-OBJECT ARM1))
                                          (NOT (HOLD-OBJECT ARM2))
                                          ;; (ON BOWL STOVE)
                                          (ON FRYING-PAN STOVE))
                                        '((IN EGG FRYING-PAN) ;; cook(egg, cooked egg)
                                          (NOT (HOLD-OBJECT ARM1))
                                          (NOT (HOLD-OBJECT ARM2))
                                          (COOKED EGG COOKED-EGG))
                                        '((NOT (STOVE-ON)) ;; end
                                          (NOT (WATERFLOW))
                                          (NOT (HOLD-OBJECT ARM1))
                                          (NOT (HOLD-OBJECT ARM2))
                                          )
                                        ))

(setq *cooking-result-list* (exec-pddl-state *cooking-initial-condition* *cooking-target-conditions* *cooking-variables* *domain*))
(setq *plan-list* (view-pddl-result *cooking-result-list* *file-name*))
(setq *current-final-condition* (show-final-condition *cooking-result-list*))

(if *exit-on-end* (ros::exit))
