#!/usr/bin/env roseus

;; robot initialize
(load "package://pr2eus/pr2.l")   
(setq *robot* (pr2)) 

;; set kitchen
(load "models/room73b2-kitchen-object.l")
(setq *kitchen* (room73b2-kitchen))
(send *kitchen* :locate #f(800 -200 0))
(send *kitchen* :rotate (deg2rad 180) :z :world)

;; set frige
(load "models/room73b2-toshiba-clacio-refrigerator-object.l")
(setq *frige* (room73b2-toshiba-clacio-refrigerator))
(send *frige* :locate #f(-325 -1675 0))
(send *frige* :rotate (deg2rad 90) :z :world)

;; set knife
(load "models/knife-object.l")
(setq *knife* (knife))
(send *knife* :locate #f(550.0 -200.0 850.0))

;; set peeler
(load "model/peeler.l")
(setq *peeler* (peeler))
(send *peeler* :locate #f(550.0 -250.0 850.0))

;; set まな板
(load "model/cutting-board.l")
(setq *cutting-board* (cutting-board))
(send *cutting-board* :locate #f(650 0 825))

;; set 調理鍋
(load "model/cooking-pot.l")
(setq *pot* (cooking-pot))
(send *pot* :locate #f(680 500 830))

;; set onion
(load "model/onion.l")
(setq *onion* (onion))
(send *onion* :locate #f(850 200 845))

;; set tomato
(load "model/tomato.l")
(setq *tomato* (tomato))
(send *tomato* :locate #f(850 100 845))

;; set carrot
(load "model/carrot.l")
(setq *carrot* (carrot))
(send *carrot* :locate #f(850 0 845))

;; set potato
(load "model/potato.l")
(setq *potato* (potato))
(send *potato* :locate #f(850 -100 845))



(setq *env-list* (list *kitchen* *knife* *peeler* *cutting-board* *pot* *frige* *onion* *tomato* *carrot* *potato*))

(objects (append *env-list* (list *robot*))) 


