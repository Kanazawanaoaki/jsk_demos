;;
;; utils
;;

(defun exec-pddl-state (cooking-initial-condition cooking-target-conditions cooking-variables domain)
  (setq cooking-result-list (list))
  (setq current-condition cooking-initial-condition)

  (dolist (current-target cooking-target-conditions)
    (setq current-problem (instance pddl-problem :init :name 'current_problem :domain 'kanazawa_cook))
    (send current-problem :objects cooking-variables)
    (send current-problem :initial-condition current-condition)
    (send current-problem :goal-condition current-target)
    (pprint (setq current-result (solve-pddl-planning domain current-problem)))
    (setq current-condition (elt (elt current-result 1) (- (length (elt current-result 1) ) 1)))
    (setq cooking-result-list (append cooking-result-list (list current-result)))
    )
  cooking-result-list)


(defun view-pddl-result (cooking-result-list file-name)
  (setq gr (make-graph-from-pddl-results cooking-result-list :node-name :pprint))

  ;; (send gr :write-to-pdf "kanazawa_cook_sunny_side_up.pdf")
  (send gr :write-to-pdf file-name)

  (when (ros::get-param "~display_graph" "true")
    ;; (piped-fork "xdg-open kanazawa_cook_sunny_side_up.pdf"))
    (piped-fork (format nil "xdg-open ~A" file-name)))

  (format t ";;The plan by cooking PDDL is as follows: ~%")
  (setq plan-list (list))
  (dolist (cooking-result cooking-result-list)
    (if (> (length cooking-result) 2)
        (progn
          (dolist (plan-unit (cdr (elt cooking-result 2)))
            (print plan-unit)
            (setq plan-list (append plan-list (list plan-unit)))
            ))))
  plan-list)

(defun show-final-condition (cooking-result-list)
  (setq current-result (elt cooking-result-list (- (length cooking-result-list)1)))
  (setq current-final-condition (elt (elt current-result 1) (- (length (elt current-result 1) ) 1)))
  (format t ";; final condition is ~%")
  (print current-final-condition)
  current-final-condition)

