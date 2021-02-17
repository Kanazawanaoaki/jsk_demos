(require :pr2-interface "package://pr2eus/pr2-interface.l")
(unless (boundp '*pr2*) (setq *pr2* (instance pr2-sensor-robot :init)))


(defun hoge (&rest args &key (arm :rarm) &allow-other-keys)
  (setq tmp (send *pr2* arm))
  )
