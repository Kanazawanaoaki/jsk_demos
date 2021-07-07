#!/usr/bin/env roseus

;; robot initialize
(load "package://pr2eus/pr2.l")   
(setq *robot* (pr2)) 

;; set kitchen
(load "models/room73b2-kitchen-object.l")
(setq *kitchen* (room73b2-kitchen))
(send *kitchen* :locate #f(800 -200 0))
(send *kitchen* :rotate (deg2rad 180) :z :world)

;; set knife
(load "models/knife-object.l")
(setq *knife* (knife))
(send *knife* :locate #f(550.0 -200.0 850.0))


;; set まな板
(load "model/cutting-board.l")
(setq *cutting-board* (cutting-board))
(send *cutting-board* :locate #f(650 0 825))

;; set 調理鍋
(load "model/cooking-pot.l")
(setq *pot* (cooking-pot))
(send *pot* :locate #f(680 500 830))

;; ;; set tray
;; (load "models/tray-object.l")
;; (setq *tray* (tray))
;; (send *tray* :locate #f(800 0 1000))



(setq *env-list* (list *kitchen* *knife* *cutting-board* *pot*))

(objects (append *env-list* (list *robot*))) 


