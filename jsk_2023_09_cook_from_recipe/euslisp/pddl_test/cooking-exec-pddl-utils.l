;;
;; utils
;;

(defun load-planed-file (file-name)
  (format t "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/recipes/planed/~A ~%" file-name)
  (load (format nil "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/recipes/planed/~A" file-name))
  )

;; def variables
(setq water "water")
(setq mixture "mixture")
(setq frying-pan "frying-pan")
(setq pot "pot")
(setq bowl "bowl")
(setq measuring-cup "measuring-cup")
(setq spoon "spoon")
(setq knife "knife")
(setq whisk "whisk")
(setq wooden-spatula "wooden-spatula")
(setq arm1 "arm1")
(setq arm2 "arm2")
(setq sink "sink")
(setq stove "stove")
(setq kitchen "kitchen")
(setq low "low")
(setq middle "middle")
(setq high "high")

;; egg


;; ;; generated-poached-egg-func-conv.l
;; ;;set cooking-variables
;; (setq *cooking-variables* '((EGG . ingredient)
;;                             (COOKED-EGG . state)
;;                             (BOILING . state)
;;                             (WHIRLPOOL . state)
;;                             (THREE-MINUTES . state)
;;                             (LOW-HEAT . state)

;;                             (COOKED-EGG . state)
;;                             (BOILED-WATER . state)
;;                             (VORTEXED-WATER . state)
;;                             ))

;; ;; 調理の初期条件
;; (setq *cooking-initial-condition* '((ROBOT-AT STOVE)
;;                                     (ON MEASURING-CUP KITCHEN)
;;                                     (IN EGG BOWL)
;;                                     (ON BOWL STOVE)
;;                                     (ON POT STOVE)
;;                                     (ON SPOON STOVE)
;;                                     (NOT (STOVE-ON))
;;                                     (NOT (WATERFLOW))
;;                                     ))

;; ;; generated-scrambled-egg-func-conv.l
;; ;;set cooking-variables
;; (setq *cooking-variables* '((EGG . ingredient)
;;                             (MILK . ingredient)
;;                             (SALT . ingredient)
;;                             (BUTTER . ingredient)
;;                             (SMALL-BOWL . vessel)
;;                             (EGG-MIXTURE . mixture)
;;                             (MELTED-BUTTER . state)
;;                             (MELT . state)
;;                             (HALF-COOKED-EGG . state)
;;                             (SOFT-SCRAMBLED-EGG . state)

;;                             (SPATULA . tool)
;;                             ;; (MELTED . state)
;;                             ;; (SURROUNDINGS-HARDENED . state)
;;                             ;; (WHOLE-MIXTURE-TENDER . state)
;;                             ))

;; ;; 調理の初期条件
;; (setq *cooking-initial-condition* '((ROBOT-AT STOVE)
;;                                     (IN EGG BOWL)
;;                                     (ON BOWL KITCHEN)
;;                                     (ON SALT KITCHEN)
;;                                     (ON MILK KITCHEN)
;;                                     (ON WHISK KITCHEN)
;;                                     (IN BUTTER SMALL-BOWL)
;;                                     (ON SMALL-BOWL STOVE)
;;                                     (ON FRYING-PAN STOVE)
;;                                     (ON WOODEN-SPATULA STOVE)
;;                                     (ON SPATULA STOVE)
;;                                     (NOT (STOVE-ON))
;;                                     (NOT (WATERFLOW))
;;                                     ))
