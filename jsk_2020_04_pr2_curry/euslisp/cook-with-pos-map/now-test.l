(require :pr2-interface "package://pr2eus/pr2-interface.l")
(setq *pr2* (instance pr2-sensor-robot :init :pr1040)))
;; (setq *pr2* (instance pr2-sensor-robot :init :pr1012)))
;; (setq *pr2* (instance pr2-sensor-robot :init)))
(objects (list *pr2*))

;; (unless (boundp '*pr2*) (setq *pr2* (instance pr2-sensor-robot :init)))
;; (pr2-init)
;; (objects (list *pr2*))
