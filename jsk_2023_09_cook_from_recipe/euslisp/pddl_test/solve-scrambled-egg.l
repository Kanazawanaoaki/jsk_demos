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
(setq *cooking-variables* '((EGG . ingredient)
                            (MILK . ingredient)
                            (SALT . ingredient)
                            (BUTTER . ingredient)
                            ;; (SCRAMBLED-EGG . object)
                            (SMALL-BOWL . vessel)
                            (EGG-MIXTURE . mixture)
                            (MELTED . state)
                            (SURROUNDINGS-HARDENED . state)
                            (WHOLE-MIXTURE-TENDER . state)
                            ))

;; 調理の初期条件
(setq *cooking-initial-condision* '((ROBOT-AT STOVE)
                                    (IN EGG BOWL)
                                    (ON BOWL KITCHEN)
                                    (ON SALT KITCHEN)
                                    (ON MILK KITCHEN)
                                    (ON WHISK KITCHEN)
                                    (IN BUTTER SMALL-BOWL)
                                    (ON SMALL-BOWL STOVE)
                                    (ON FRYING-PAN STOVE)
                                    (ON WOODEN-SPATULA STOVE)
                                    (NOT (STOVE-ON))
                                    (NOT (WATERFLOW))
                                    ))

;; TODO 卵を割る話など
;; 調理レシピ記述から
(setq *cooking-target-conditions* (list '((IN MILK BOWL) ;; pour(milk, bowl)
                                          ;; (ON MILK KITCHEN)
                                          (NOT (HOLD-OBJECT ARM1))
                                          (NOT (HOLD-OBJECT ARM2))
                                          )
                                        '((IN SALT BOWL) ;; pour(salt, bowl)
                                          ;; (ON SALT KITCHEN)
                                          (NOT (HOLD-OBJECT ARM1))
                                          (NOT (HOLD-OBJECT ARM2))
                                          )
                                        '((MIXED EGG-MIXTURE EGG MILK WHISK) ;; mix(egg milk, egg and milk mixed well)
                                          (IN EGG-MIXTURE BOWL)
                                          ;; (ON WHISK KITCHEN)
                                          (NOT (HOLD-OBJECT ARM1))
                                          (NOT (HOLD-OBJECT ARM2))
                                          )
                                        '((IN BUTTER FRYING-PAN) ;; pour(butter, frying pan)
                                          (NOT (HOLD-OBJECT ARM1))
                                          (NOT (HOLD-OBJECT ARM2))
                                          ;; (ON SMALL-BOWL STOVE)
                                          )
                                        '((HEATED BUTTER MELTED) ;; heat(butter, melt)
                                          (IN BUTTER FRYING-PAN)
                                          (NOT (HOLD-OBJECT ARM1))
                                          (NOT (HOLD-OBJECT ARM2))
                                          )
                                        '((IN EGG-MIXTURE FRYING-PAN) ;; pour(egg, frying pan)
                                          (MIXED EGG-MIXTURE EGG MILK WHISK)
                                          ;; (ON BOWL STOVE)
                                          (NOT (HOLD-OBJECT ARM1))
                                          (NOT (HOLD-OBJECT ARM2))
                                          )
                                        '((HEATED EGG-MIXTURE SURROUNDINGS-HARDENED) ;; heat(egg mixture, Egg mixture that have hardened around)
                                          (MIXED EGG-MIXTURE EGG MILK WHISK)
                                          (NOT (HOLD-OBJECT ARM1))
                                          (NOT (HOLD-OBJECT ARM2))
                                          )

                                        ;; '((STIR-FRIED SCRAMBLED-EGG EGG-MIXTURE WHOLE-MIXTURE-TENDER WOODEN-SPATULA) ;; stir-fry(egg mixture, the whole mixture will be tender, 30-40 times quickly with a wooden spatula)
                                        ;;   (IN SCRAMBLED-EGG FRYING-PAN)
                                        '((STIR-FRIED EGG-MIXTURE WHOLE-MIXTURE-TENDER WOODEN-SPATULA) ;; stir-fry(egg mixture, the whole mixture will be tender, 30-40 times quickly with a wooden spatula)
                                          (IN EGG-MIXTURE FRYING-PAN)
                                          ;; (ON WOODEN-SPATULA STOVE)
                                          (NOT (HOLD-OBJECT ARM1))
                                          (NOT (HOLD-OBJECT ARM2))
                                          )

                                        '((NOT (STOVE-ON)) ;; end
                                          (NOT (WATERFLOW))
                                          (NOT (HOLD-OBJECT ARM1))
                                          (NOT (HOLD-OBJECT ARM2))
                                          )
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

(send gr :write-to-pdf "kanazawa_cook_scrambled_egg.pdf")

(when (ros::get-param "~display_graph" "true")
  (piped-fork "xdg-open kanazawa_cook_scrambled_egg.pdf"))

(format t ";;The plan by cooking PDDL is as follows: ~%")
(setq *plan-list* (list))
(dolist (cooking-result *cooking-result-list*)
  (if (> (length cooking-result) 2)
      (progn
        (dolist (plan-unit (cdr (elt cooking-result 2)))
          (print plan-unit)
          (setq *plan-list* (append *plan-list* (list plan-unit)))
          ))))

(defun show-final-condition ()
  (setq current-result (elt *cooking-result-list* (- (length *cooking-result-list*)1)))
  (print (elt (elt current-result 1) (- (length (elt current-result 1) ) 1)))
  t)

(if *exit-on-end* (ros::exit))
