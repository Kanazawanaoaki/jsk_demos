#!/usr/bin/env roseus

(setq *exit-on-end* (string= "__log:=" (subseq (car (last lisp::*eustop-argument*)) 0 7)))

(load "package://pddl_planner/src/pddl-result-graph.l")
(load "package://pddl_planner/src/eus-pddl-client.l")

;; load domain
(load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/cooking-pddl-domain.l")
(load "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/cooking-pddl-utils.l")

;;
;; problem and solve
;;

(setq *file-name* "kanazawa_cook_read_file_dish.pdf")
(setq *plan-list* nil)

(defun convert-basic-list-to-target-list (basic-list)
  (let ((target-list (list))
        (step-cond '((NOT (HOLD-OBJECT ARM1))
                     (NOT (HOLD-OBJECT ARM2))))
        (end-cond '((NOT (STOVE-ON POT))
                    (NOT (STOVE-ON FRYING-PAN))
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
  (let ((file-path))
    ;; load conditions file
    (setq file-path (format nil "package://jsk_2023_09_cook_from_recipe/recipes/output_conditions/~A" file-name))
    (format t "Input file path is : ~A ~%" file-path)
    (load file-path)
    ;; load setting file
    (setq file-path (format nil "package://jsk_2023_09_cook_from_recipe/recipes/settings/~A" file-name))
    (load file-path)
    (cook-condition-conversion)
    ))

(defun dump-plan-file (file-name)
  (if (null *plan-list*)
      (format t "now plan-list is nill please exec (read-file)!! ~%")
    (progn
      (format t "now plan is ~% ~A ~%" *plan-list*)
      (dump-loadable-structure (format nil "planned/~A" file-name) *plan-list*)
      (format t "data dumped in planned/~A ~%" file-name)
      ))
  )

(format t "~% Please run (read-file [file-name]) ~%")
