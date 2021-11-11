#!/usr/bin/env roseus

(load "package://pddl_planner/src/pddl-result-graph.l")
(load "package://pddl_planner/src/eus-pddl-client.l")

;;
;; problem
;;
(setq *hot-in-microwave-problem* (instance pddl-problem :init :name 'hot_in_microwave :domain 'kanazawa_microwave))

;;使用する変数の宣言
(send *hot-in-microwave-problem* :objects
      '((WATER . object)
        (POT . object)
        (IH . object) ;; 家電？
        )
      )

;;初期条件
(send *hot-in-microwave-problem* :initial-condition
      '((NORMAL WATER)
        (ON POT IH)
        (OFF IH)))

;;終了条件
(send *hot-in-microwave-problem* :goal-condition
      '((BOILED WATER)
        (ON POT IH)
        (OFF IH)))

;;
;; domain
;;
(setq *domain* (instance pddl-domain :init :name 'okada_ias))
(send *domain* :requirements '(:typing))
(send *domain* :types '(object spot arm))
(send *domain* :constants '(CUP BOTTLE - object LARM RARM - arm SINK - spot))
(send *domain* :predicates '((ON ?obj - object ?spot - spot)
                             (AT ?spot - spot)
                             (HOLD ?obj - object ?arm - arm)
                             (WATERFLOW)
                             (WASHED ?obj - object)
                             (POURED ?obj - object)
                             ))


