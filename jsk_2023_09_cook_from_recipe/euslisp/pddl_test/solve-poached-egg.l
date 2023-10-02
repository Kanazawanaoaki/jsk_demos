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
(setq *cooking-variables* '((WATER . object)
                            (EGG . object)
                            ;; (THIRTY-SECONDS . state)
                            (COOKED-EGG . state)
                            (BOILED-WATER . state)
                            (VORTEXED-WATER . state)
                            (THREE-MINUTES . state)
                            ))

;; 調理の初期条件
(setq *cooking-initial-condision* '((ROBOT-AT STOVE)
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
(setq *cooking-target-conditions* (list '((IN WATER POT) ;; boil(water, boiled water, pot)
                                          (BOILED WATER BOILED-WATER)
                                          (ON POT STOVE))
                                        '((SET-STOVE LOW)) ;; set(stove, low)
                                        '((IN WATER POT) ;; mix(water, vortexed water,spoon)
                                          (STIRRED WATER VORTEXED-WATER SPOON)
                                          (ON SPOON STOVE))
                                        '((IN EGG POT) ;; pour(egg, pot, gently)
                                          (ON BOWL STOVE))
                                        '((BOILED EGG THREE-MINUTES)) ;; boil(egg, 3 minutes)
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

(send gr :write-to-pdf "kanazawa_cook_poached_egg.pdf")

(when (ros::get-param "~display_graph" "true")
  (piped-fork "xdg-open kanazawa_cook_poached_egg.pdf"))

(format t ";;The plan by cooking PDDL is as follows: ~%")
(setq *plan-list* (list))
(dolist (cooking-result *cooking-result-list*)
  (if (> (length cooking-result) 2)
      (progn
        (dolist (plan-unit (cdr (elt cooking-result 2)))
          (print plan-unit)
          (setq *plan-list* (append *plan-list* (list plan-unit)))
          ))))

(if *exit-on-end* (ros::exit))
