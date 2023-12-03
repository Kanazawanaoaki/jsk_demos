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

(setq *file-name* "kanazawa_cook_read_file_dish.pdf")
(setq *plan-list* nil)

(defun convert-basic-list-to-target-list (basic-list)
  (let ((target-list (list))
        (step-cond '((NOT (HOLD-OBJECT ARM1))
                          (NOT (HOLD-OBJECT ARM2))))
        (end-cond '((NOT (STOVE-ON))
                         (NOT (WATERFLOW))
                         (NOT (HOLD-OBJECT ARM1))
                         (NOT (HOLD-OBJECT ARM2))))
        )
    (dolist (l basic-list)
      (setq target-list (append target-list (list (append l step-cond))))
      )
    (setq target-list (append target-list (list end-cond)))
    target-list))

(defun cook-condition-conversion ()
  (setq *cooking-target-conditions* (convert-basic-list-to-target-list *basic-cooking-target-conditions*))
  (print *cooking-target-conditions*)

  (setq *cooking-result-list* (exec-pddl-state *cooking-initial-condition* *cooking-target-conditions* *cooking-variables* *domain*))
  (setq *plan-list* (view-pddl-result *cooking-result-list* *file-name*))
  (setq *current-final-condition* (show-final-condition *cooking-result-list*))
  )

(defun read-file (file-name)
  (format t "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/recipes/~A ~%" file-name)
  (load (format nil "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/recipes/~A" file-name))
  (cook-condition-conversion)
  )

(defun dump-plan-file (file-name)
  (if (null *plan-list*)
      (format t "now plan-list is nill please exec ~%")
    (progn
      (format t "now plan is ~% ~A ~%" *plan-list*)
      (dump-loadable-structure (format nil "recipes/planed/~A" file-name) *plan-list*)
      (format t "data dumped in recipes/planed/~A ~%" file-name)
      ))
  )

;; ;; sunny-side-up.l
;; ;;set cooking-variables
;; (setq *cooking-variables* '((OIL . ingredient)
;;                             (SALAD-OIL . ingredient)
;;                             (EGG . ingredient)
;;                             (THIRTY-SECONDS . state)
;;                             (COOKED-EGG . state)
;;                             ))

;; ;; 調理の初期条件
;; (setq *cooking-initial-condition* '((ROBOT-AT STOVE)
;;                                     (ON OIL STOVE)
;;                                     (ON SALAD-OIL STOVE)
;;                                     (IN EGG BOWL)
;;                                     (ON BOWL STOVE)
;;                                     (ON FRYING-PAN STOVE)
;;                                     (NOT (STOVE-ON))
;;                                     ))

;; ;; poached-egg.l
;; ;;set cooking-variables
;; (setq *cooking-variables* '((EGG . ingredient)
;;                             (COOKED-EGG . state)
;;                             (BOILED-WATER . state)
;;                             (VORTEXED-WATER . state)
;;                             (THREE-MINUTES . state)
;;                             ))

;; ;; 調理の初期条件
;; (setq *cooking-initial-condition* '((ROBOT-AT STOVE)
;;                                     (ON MEASURING-CUP KITCHEN)
;;                                     (IN EGG BOWL)
;;                                     (ON BOWL STOVE)
;;                                     (ON POT STOVE)
;;                                     (ON SPOON STOVE)
;;                                     (NOT (STOVE-ON))
;;                                     (NOT (WATERFLOW))
;;                                     ))

;; ;; scrambled-egg.l
;; ;;set cooking-variables
;; (setq *cooking-variables* '((EGG . ingredient)
;;                             (MILK . ingredient)
;;                             (SALT . ingredient)
;;                             (BUTTER . ingredient)
;;                             (SMALL-BOWL . vessel)
;;                             (EGG-MIXTURE . mixture)
;;                             (MELTED . state)
;;                             (MELT . state)
;;                             (SURROUNDINGS-HARDENED . state)
;;                             (WHOLE-MIXTURE-TENDER . state)
;;                             ))

;; ;; 調理の初期条件
;; (setq *cooking-initial-condition* '((ROBOT-AT STOVE)
;;                                     (IN EGG BOWL)
;;                                     (ON BOWL KITCHEN)
;;                                     (ON SALT KITCHEN)
;;                                     (ON MILK KITCHEN)
;;                                     (ON WHISK KITCHEN)
;;                                     (IN BUTTER SMALL-BOWL)
;;                                     (ON SMALL-BOWL STOVE)
;;                                     (ON FRYING-PAN STOVE)
;;                                     (ON WOODEN-SPATULA STOVE)
;;                                     (NOT (STOVE-ON))
;;                                     (NOT (WATERFLOW))
;;                                     ))



;; generated-sunny-side-up-func-conv.l
;;set cooking-variables
(setq *cooking-variables* '((EGG . ingredient)
                            (SALAD-OIL . ingredient)
                            (THIRTY-SECONDS . state)
                            (HEAT-THROUGH . state)

                            (OIL . ingredient)
                            ;; (COOKED-EGG . state)
                            ))

;; 調理の初期条件
(setq *cooking-initial-condition* '((ROBOT-AT STOVE)
                                    (ON OIL STOVE)
                                    (ON SALAD-OIL STOVE)
                                    (IN EGG BOWL)
                                    (ON BOWL STOVE)
                                    (ON FRYING-PAN STOVE)
                                    (NOT (STOVE-ON))
                                    ))

;; ;; generated-poached-egg-func-conv.l
;; ;;set cooking-variables
;; (setq *cooking-variables* '((EGG . ingredient)
;;                             (COOKED-EGG . state)
;;                             (BOILING . state)
;;                             (WHIRLPOOL . state)
;;                             (THREE-MINUTES . state)
;;                             (LOW-HEAT . state)

;;                             (COOKED-EGG . state)
;;                             (BOILED-WATER . state)
;;                             (VORTEXED-WATER . state)
;;                             ))

;; ;; 調理の初期条件
;; (setq *cooking-initial-condition* '((ROBOT-AT STOVE)
;;                                     (ON MEASURING-CUP KITCHEN)
;;                                     (IN EGG BOWL)
;;                                     (ON BOWL STOVE)
;;                                     (ON POT STOVE)
;;                                     (ON SPOON STOVE)
;;                                     (NOT (STOVE-ON))
;;                                     (NOT (WATERFLOW))
;;                                     ))

;; ;; generated-scrambled-egg-func-conv.l
;; ;;set cooking-variables
;; (setq *cooking-variables* '((EGG . ingredient)
;;                             (MILK . ingredient)
;;                             (SALT . ingredient)
;;                             (BUTTER . ingredient)
;;                             (SMALL-BOWL . vessel)
;;                             (EGG-MIXTURE . mixture)
;;                             (MELTED-BUTTER . state)
;;                             (MELT . state)
;;                             (HALF-COOKED-EGG . state)
;;                             (SOFT-SCRAMBLED-EGG . state)

;;                             (SPATULA . tool)
;;                             ;; (MELTED . state)
;;                             ;; (SURROUNDINGS-HARDENED . state)
;;                             ;; (WHOLE-MIXTURE-TENDER . state)
;;                             ))

;; ;; 調理の初期条件
;; (setq *cooking-initial-condition* '((ROBOT-AT STOVE)
;;                                     (IN EGG BOWL)
;;                                     (ON BOWL KITCHEN)
;;                                     (ON SALT KITCHEN)
;;                                     (ON MILK KITCHEN)
;;                                     (ON WHISK KITCHEN)
;;                                     (IN BUTTER SMALL-BOWL)
;;                                     (ON SMALL-BOWL STOVE)
;;                                     (ON FRYING-PAN STOVE)
;;                                     (ON WOODEN-SPATULA STOVE)
;;                                     (ON SPATULA STOVE)
;;                                     (NOT (STOVE-ON))
;;                                     (NOT (WATERFLOW))
;;                                     ))

;; (if *exit-on-end* (ros::exit))
