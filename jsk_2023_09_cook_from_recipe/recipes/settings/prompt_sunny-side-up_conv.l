;; set cooking-variables
(setq *cooking-variables* '((OIL . ingredient)
                            (SALAD-OIL . ingredient)
                            (EGG . ingredient)
                            (THIRTY-SECONDS . state)
                            (COOKED-EGG . state)
                            ))

;; set cooking-initial-condition
(setq *cooking-initial-condition* '((ROBOT-AT STOVE)
                                    (ON OIL STOVE)
                                    (ON SALAD-OIL STOVE)
                                    (IN EGG BOWL)
                                    (ON BOWL STOVE)
                                    (ON FRYING-PAN STOVE)
                                    (NOT (STOVE-ON POT))
                                    (NOT (STOVE-ON FRYING-PAN))
                                    (NOT (WATERFLOW))
                                    ))
