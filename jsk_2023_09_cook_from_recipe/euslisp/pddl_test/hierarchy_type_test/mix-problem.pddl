(define (problem mix-test-problem)

	(:domain mix-test)

	(:objects
        EGG - ingredient
        MILK - ingredient
        EGG-MIXTURE - mixture
        BOWL CUP - vessel
        COOKED - state
        )

	(:init
		;; spatial-map
        (in MILK CUP)
        (IN EGG BOWL)

    )
	(:goal
		(and
        (in EGG-MIXTURE BOWL)
        (mixed EGG-MIXTURE MILK EGG)
        (cooked EGG-MIXTURE COOKED)
		))

	(:metric minimize (total-time))
)