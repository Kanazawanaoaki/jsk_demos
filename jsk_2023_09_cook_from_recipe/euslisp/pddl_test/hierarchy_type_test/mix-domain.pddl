(define (domain mix-test)

	(:requirements :typing :durative-actions)

	(:types ingredient vessel tool - object
            mixture - ingredient
            state)

	(:predicates
        (in ?obj - ingredient ?vessel - vessel)
        (mixed ?mixture - mixture ?ing1 - ingredient ?ing2 - ingredient)
        (cooked ?ing - ingredient ?state - state)
	)

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;
	;; Robot : Transit/Transfer
	;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	(:durative-action transfer
		:parameters (?CONTENT - ingredient ?FROM - vessel ?TO - vessel)
	        :duration (= ?duration 1)
		:condition (and
                   (at start (in ?CONTENT ?FROM))
                )
		:effect (and
                (at start (not (in ?CONTENT ?FROM)))
                (at end (in ?CONTENT ?TO))
                ))

	(:durative-action mix
		:parameters (?MIXTURE - mixture ?ING-ONE - ingredient ?ING-TWO - ingredient ?VESSEL - vessel)
	        :duration (= ?duration 1)
		:condition (and
                (at start (in ?ING-ONE ?VESSEL))
                (at start (in ?ING-TWO ?VESSEL))
                (at start (not (= ?ING-ONE ?ING-TWO)))
                (at start (not (in ?MIXTURE ?VESSEL)))
                (at start (not (mixed ?MIXTURE ?ING-ONE ?ING-TWO)))
                )
		:effect (and
                (at start (not (in ?ING-ONE ?VESSEL)))
                (at start (not (in ?ING-TWO ?VESSEL)))
                (at end (mixed ?MIXTURE ?ING-ONE ?ING-TWO))
                (at end (in ?MIXTURE ?VESSEL))
                ))

	(:durative-action cook
		:parameters (?OBJECT - ingredient ?STATE - state ?VESSEL - vessel)
	        :duration (= ?duration 1)
		:condition (and
                (at start (not (COOKED ?OBJECT ?STATE)))
                (at start (in ?OBJECT ?VESSEL))
                )
		:effect (and
                (at end (cooked ?OBJECT ?STATE))
                ))
)