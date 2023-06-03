(defun pour (ing tool)
  (format t "pour ~A to ~A ~%" ing tool)
  )

(defun fire-on (tool)
  (format t "on ~A  ~%" tool)
  )

(defun fire-off (tool)
  (format t "off ~A ~%" tool)
  )

(defun START-CONDITION (condition action)
  (format t "start ~A action if ~A condition ~%" action condition)
  (eval action)
  )

(format t "~%")
(load "package://jsk_2022_10_egg_dishes/recipes/converted/lisp-converted-butter-sunny-side-up_converted.txt")

