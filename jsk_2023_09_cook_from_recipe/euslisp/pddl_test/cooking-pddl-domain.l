;;
;; domain
;;


(setq *domain* (instance pddl-domain :init :name 'kanazawa_cook))
(send *domain* :requirements '(:typing))
(send *domain* :types '(object spot arm how state))
(send *domain* :constants '(WATER - object MIXTURE - mixture FRYING-PAN POT BOWL MEASURING-CUP - vessel SPOON KNIFE WHISK - tool LARM RARM - arm SINK STOVE KITCHEN - spot LOW MIDDLE HIGH - state))
(send *domain* :predicates '((ON ?obj - object ?spot - spot)
                             (IN ?obj - object ?vessel - vessel)
                             (ROBOT-AT ?spot - spot)
                             (HOLD ?obj - object ?arm - arm)
                             (HEATED ?obj - object ?state - state)
                             (COOKED ?obj - object ?state - state)
                             (BOILED ?obj - object ?state - state)
                             (STIRRED ?obj - object ?state - state ?tool - tool)
                             (MIXED ?mixture - mixture ?ing1 - object ?ing2 - object ?tool -tool)
                             (WASHED ?obj - object)
                             (WATERFLOW)
                             (STOVE-ON)
                             (SET-STOVE ?state -state)
                             ))
;;making action
(setq *actions*
      (list
       (instance pddl-action :init
                 :name "hold"
                 :parameters '((?OBJECT object) (?ARM arm) (?SPOT spot))
                 :precondition '((ON ?OBJECT ?SPOT)
                                 (ROBOT-AT ?SPOT))
                 :effect '((HOLD ?OBJECT ?ARM)
                           (NOT (ON ?OBJECT ?SPOT))))
       (instance pddl-action :init
                 :name "place"
                 :parameters '((?OBJECT object) (?ARM arm) (?SPOT spot))
                 :precondition '((HOLD ?OBJECT ?ARM)
                                 (ROBOT-AT ?SPOT))
                 :effect '((NOT (HOLD ?OBJECT ?ARM))
                           (ON ?OBJECT ?SPOT)))
       (instance pddl-action :init
                 :name "move-to"
                 :parameters '((?FROM ?TO spot))
                 :precondition '((ROBOT-AT ?FROM)
                                 (NOT (WATERFLOW))
                                 (NOT (STOVE-ON))
                                 )
                 :effect '((ROBOT-AT ?TO)
                           (NOT (ROBOT-AT ?FROM))))
       (instance pddl-action :init
                 :name "open-tap"
                 :parameters '()
                 :precondition '((ROBOT-AT SINK)
                                 (NOT (WATERFLOW)))
                 :effect '((WATERFLOW)))
       (instance pddl-action :init
                 :name "close-tap"
                 :parameters '()
                 :precondition '((ROBOT-AT SINK)
                                 (WATERFLOW))
                 :effect '((NOT (WATERFLOW))))
       (instance pddl-action :init
                 :name "turn-on-stove"
                 :parameters '()
                 :precondition '((ROBOT-AT STOVE)
                                 (NOT (STOVE-ON)))
                 :effect '((STOVE-ON)
                           (SET-STOVE MIDDLE)))
       (instance pddl-action :init
                 :name "set-stove"
                 :parameters '((?BEFORE ?AFTER state))
                 :precondition '((ROBOT-AT STOVE)
                                 (STOVE-ON)
                                 (SET-STOVE ?BEFORE)
                                 (NOT (SET-STOVE ?AFTER)))
                 :effect '((SET-STOVE ?AFTER)
                           (NOT (SET-STOVE ?BEFORE))))
       (instance pddl-action :init
                 :name "turn-off-stove"
                 :parameters '()
                 :precondition '((ROBOT-AT STOVE)
                                 (STOVE-ON))
                 :effect '((NOT (STOVE-ON))))
       (instance pddl-action :init
                 :name "wash"
                 :parameters '((?OBJECT object) (?ARM arm))
                 :precondition '((HOLD ?OBJECT ?ARM)
                                 (ROBOT-AT SINK)
                                 (WATERFLOW)
                                 (NOT (WASHED ?OBJECT)))
                 :effect '((WASHED ?OBJECT)))

       (instance pddl-action :init
                 :name "pour"
                 :parameters '((?OBJECT object) (?VESSEL vessel) (?ARM arm) (?SPOT spot))
                 :precondition '((HOLD ?OBJECT ?ARM)
                                 (ROBOT-AT ?SPOT)
                                 (ON ?VESSEL ?SPOT)
                                 )
                 :effect '((IN ?OBJECT ?VESSEL)))
       (instance pddl-action :init
                 :name "transfer"
                 :parameters '((?CONTENT object) (?FROM ?TO vessel) (?ARM arm) (?SPOT spot))
                 :precondition '((HOLD ?FROM ?ARM)
                                 (ROBOT-AT ?SPOT)
                                 (ON ?TO ?SPOT)
                                 (IN ?CONTENT ?FROM)
                                 )
                 :effect '((IN ?CONTENT ?TO)
                           (NOT (IN ?CONTENT ?FROM))))
       (instance pddl-action :init
                 :name "heat"
                 :parameters '((?OBJECT object) (?STATE state))
                 :precondition '((IN ?OBJECT FRYING-PAN)
                                 (ON FRYING-PAN STOVE)
                                 (ROBOT-AT STOVE)
                                 (STOVE-ON)
                                 )
                 :effect '((HEATED ?OBJECT ?STATE)
                           ))
       (instance pddl-action :init
                 :name "cook"
                 :parameters '((?OBJECT object) (?STATE state))
                 :precondition '((IN ?OBJECT FRYING-PAN)
                                 (ON FRYING-PAN STOVE)
                                 (ROBOT-AT STOVE)
                                 (STOVE-ON)
                                 )
                 :effect '((COOKED ?OBJECT ?STATE)
                           ))
       (instance pddl-action :init
                 :name "boil"
                 :parameters '((?OBJECT object) (?STATE state))
                 :precondition '((IN ?OBJECT POT)
                                 (ON POT STOVE)
                                 (ROBOT-AT STOVE)
                                 (STOVE-ON)
                                 )
                 :effect '((BOILED ?OBJECT ?STATE)
                           ))
       (instance pddl-action :init
                 :name "stir"
                 :parameters '((?OBJECT object) (?TOOL tool) (?VESSEL vessel) (?STATE state) (?SPOT spot) (?ARM arm))
                 :precondition '((IN ?OBJECT ?VESSEL)
                                 (ON ?VESSEL ?SPOT)
                                 (ROBOT-AT ?SPOT)
                                 (HOLD ?TOOL ?ARM)
                                 (NOT (STIRRED ?OBJECT ?STATE ?TOOL))
                                 )
                 :effect '((STIRRED ?OBJECT ?STATE ?TOOL)
                           ))
       (instance pddl-action :init
                 :name "mix"
                 :parameters '((?MIXTURE mixture) (?ING-ONE ?ING-TWO object) (?VESSEL vessel) (?TOOL tool) (?SPOT spot) (?ARM arm))
                 :precondition '((IN ?ING-ONE ?VESSEL)
                                 (IN ?ING-TWO ?VESSEL)
                                 (NOT (= ?ING-ONE ?ING-TWO))
                                 (ON ?VESSEL ?SPOT)
                                 (ROBOT-AT ?SPOT)
                                 (HOLD ?TOOL ?ARM)
                                 (NOT (MIXED ?MIXTURE ?ING-ONE ?ING-TWO ?TOOL))
                                 (NOT (IN ?MIXTURE ?VESSEL))
                                 )
                 :effect '((MIXED ?MIXTURE ?ING-ONE ?ING-TWO ?TOOL)
                           (IN ?MIXTURE ?VESSEL)
                           (NOT (IN ?ING-ONE ?VESSEL))
                           (NOT (IN ?ING-TWO ?VESSEL))
                           ))
       (instance pddl-action :init
                 :name "fetch-water"
                 :parameters '((?ARM arm))
                 :precondition '((HOLD MEASURING-CUP ?ARM)
                                 (ON POT STOVE)
                                 (ROBOT-AT SINK)
                                 (WATERFLOW)
                                 (NOT (IN WATER MEASURING-CUP))
                                 )
                 :effect '((IN WATER MEASURING-CUP)
                           ))
       ))

;;add action to domain
(dolist (act *actions*)
  (send *domain* :add :action act))

