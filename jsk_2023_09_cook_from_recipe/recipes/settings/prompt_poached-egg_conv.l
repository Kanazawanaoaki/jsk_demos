;; set cooking-variables
(setq *cooking-variables* '((EGG . ingredient)
                            (BOILED-WATER . state)
                            (VORTEXED-WATER . state)
                            (THREE-MINUTES . state)
                            ))

;; set cooking-initial-condition
(setq *cooking-initial-condition* '((ROBOT-AT STOVE)
                                    (ON MEASURING-CUP KITCHEN)
                                    (IN EGG BOWL)
                                    (ON BOWL STOVE)
                                    (ON POT STOVE)
                                    (ON SPOON STOVE)
                                    (NOT (STOVE-ON POT))
                                    (NOT (STOVE-ON FRYING-PAN))
                                    (NOT (WATERFLOW))
                                    ))
