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

(setq *file-name* "kanazawa_cook_poached_egg.pdf")

;;set cooking-variables
(setq *cooking-variables* '((EGG . ingredient)
                            (COOKED-EGG . state)
                            (BOILED-WATER . state)
                            (VORTEXED-WATER . state)
                            (THREE-MINUTES . state)
                            ))

;; 調理の初期条件
(setq *cooking-initial-condition* '((ROBOT-AT STOVE)
                                    (ON MEASURING-CUP KITCHEN)
                                    (IN EGG BOWL)
                                    (ON BOWL STOVE)
                                    (ON POT STOVE)
                                    (ON SPOON STOVE)
                                    (NOT (STOVE-ON))
                                    (NOT (WATERFLOW))
                                    ))

;; TODO 卵を割る話など
;; 調理レシピ記述から
(setq *cooking-target-conditions* (list
                                   ;; '((IN WATER POT) ;; boil(water, boiled water, pot)
                                   ;;   (BOILED WATER BOILED-WATER)
                                   ;;   ;; (ON POT STOVE)
                                   ;;   (NOT (HOLD-OBJECT ARM1))
                                   ;;   (NOT (HOLD-OBJECT ARM2))
                                   ;;   )
                                   ;; '((SET-STOVE LOW) ;; set(stove, low)
                                   ;;   (NOT (HOLD-OBJECT ARM1))
                                   ;;   (NOT (HOLD-OBJECT ARM2))
                                   ;;   )
                                   ;; '((IN WATER POT) ;; mix(water, vortexed water,spoon)
                                   ;;   (STIRRED WATER VORTEXED-WATER SPOON)
                                   ;;   (NOT (HOLD-OBJECT ARM1))
                                   ;;   (NOT (HOLD-OBJECT ARM2))
                                   ;;   )
                                   ;; '((IN EGG POT) ;; pour(egg, pot, gently)
                                   ;;   (NOT (HOLD-OBJECT ARM1))
                                   ;;   (NOT (HOLD-OBJECT ARM2))
                                   ;;   )
                                   ;; '((BOILED EGG THREE-MINUTES) ;; boil(egg, 3 minutes)
                                   ;;   (NOT (HOLD-OBJECT ARM1))
                                   ;;   (NOT (HOLD-OBJECT ARM2))
                                   ;;   )
                                   '((NOT (STOVE-ON)) ;; end
                                     (NOT (WATERFLOW))
                                     (NOT (HOLD-OBJECT ARM1))
                                     (NOT (HOLD-OBJECT ARM2))
                                     (BOILED EGG THREE-MINUTES)
                                     (BOILED WATER BOILED-WATER)
                                     (IN EGG POT)
                                     (IN WATER POT)
                                     (ON BOWL STOVE)
                                     (ON MEASURING-CUP STOVE)
                                     (ON POT STOVE)
                                     (ON SPOON STOVE)
                                     (ROBOT-AT STOVE)
                                     (STIRRED WATER VORTEXED-WATER SPOON)
                                     )
                                   ))


(setq *cooking-result-list* (exec-pddl-state *cooking-initial-condition* *cooking-target-conditions* *cooking-variables* *domain*))
(setq *plan-list* (view-pddl-result *cooking-result-list* *file-name*))
(setq *current-final-condition* (show-final-condition *cooking-result-list*))

(if *exit-on-end* (ros::exit))
