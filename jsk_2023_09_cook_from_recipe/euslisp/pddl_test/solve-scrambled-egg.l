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
(setq *cooking-variables* '((EGG . object)
                            (MILK . object)
                            (SALT . object)
                            (BUTTER . object)
                            (SMALL-BOWL . vessel)
                            (EGG-MIXTURE . mixture)
                            (MELTED . state)
                            (SURROUNDINGS-HARDENED . state)
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
                                    (NOT (STOVE-ON))
                                    (NOT (WATERFLOW))
                                    ))

;; TODO 卵を割る話など

;; crack(egg, bowl)
;; pour(milk, bowl)
;; pour(salt, bowl)
;; mix(egg milk, egg and milk mixed well)
;; pour(butter, frying pan)
;; heat(butter, melt)
;; pour(egg, frying pan)
;; heat(egg mixture, Egg mixture that have hardened around)
;; stir-fry(egg mixture, the whole mixture will be tender, 30-40 times quickly with a wooden spatula)
;; turn-off(stove)
;; serve(scrambled egg, dish)

;; 調理レシピ記述から
(setq *cooking-target-conditions* (list '((IN MILK BOWL) ;; pour(milk, bowl)
                                          (ON MILK KITCHEN))
                                        '((IN SALT BOWL) ;; pour(salt, bowl)
                                          (ON SALT KITCHEN))
                                        '((MIXED EGG-MIXTURE EGG MILK WHISK) ;; mix(egg milk, egg and milk mixed well)
                                          (IN EGG-MIXTURE BOWL)
                                          (ON WHISK KITCHEN))
                                        '((IN BUTTER FRYING-PAN) ;; pour(butter, frying pan)
                                          (ON SMALL-BOWL STOVE))
                                        '((HEATED BUTTER MELTED) ;; heat(butter, melt)
                                          (IN BUTTER FRYING-PAN))
                                        '((IN EGG-MIXTURE FRYING-PAN) ;; pour(egg, frying pan)
                                          (MIXED EGG-MIXTURE EGG MILK WHISK)
                                          (ON BOWL STOVE))
                                        '((HEATED EGG-MIXTURE SURROUNDINGS-HARDENED) ;; heat(egg mixture, Egg mixture that have hardened around)
                                          (MIXED EGG-MIXTURE EGG MILK WHISK))

                                        ;; '((HEATED EGG-MIXTURE SURROUNDINGS-HARDENED) ;; stir-fry(egg mixture, the whole mixture will be tender, 30-40 times quickly with a wooden spatula)
                                        ;;   (MIXED EGG-MIXTURE EGG MILK WHISK))

                                        '((NOT (STOVE-ON)) ;; end
                                          (NOT (WATERFLOW)))
                                        ))
;; (setq *cooking-target-conditions* (list '((IN WATER POT) ;; boil(water, boiled water, pot)
;;                                           (BOILED WATER BOILED-WATER)
;;                                           (ON POT STOVE))
;;                                         '((SET-STOVE LOW)) ;; set(stove, low)
;;                                         '((IN WATER POT) ;; mix(water, vortexed water,spoon)
;;                                           (MIXED WATER VORTEXED-WATER SPOON)
;;                                           (ON SPOON STOVE))
;;                                         '((IN EGG POT) ;; pour(egg, pot, gently)
;;                                           (ON BOWL STOVE))
;;                                         '((BOILED EGG THREE-MINUTES)) ;; boil(egg, 3 minutes)
;;                                         '((NOT (STOVE-ON)) ;; end
;;                                           (NOT (WATERFLOW)))
;;                                         ))

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

(if *exit-on-end* (ros::exit))
