;; set cooking-variables
(setq *cooking-variables* '((SALAD-OIL . ingredient)
                            (EGG . ingredient)
                            (THIRTY-SECONDS . state)
                            (COOKED-EGG . state)
                            ))

;; set cooking-initial-condition
(setq *cooking-initial-condition* '((ROBOT-AT STOVE)
                                    (ON SALAD-OIL KITCHEN)
                                    (IN EGG BOWL)
                                    (ON BOWL KITCHEN)
                                    (ON FRYING-PAN KITCHEN)
                                    (NOT (STOVE-ON POT))
                                    (NOT (STOVE-ON FRYING-PAN))
                                    (NOT (WATERFLOW))
                                    ))
