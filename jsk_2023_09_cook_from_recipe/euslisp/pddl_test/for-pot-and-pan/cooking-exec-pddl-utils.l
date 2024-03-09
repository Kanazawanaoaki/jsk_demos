;;
;; utils
;;

(setq *plan-list* nil)

(defun load-planned-file (file-name)
  (setq file-path (format nil "package://jsk_2023_09_cook_from_recipe/euslisp/pddl_test/for-pot-and-pan/planned/~A" file-name))
  (format t "Input planned-file path is : ~A ~%" file-path)
  (load file-path)
  )

(defun view-plan-list ()
  (if (null *plan-list*)
      (format t "now plan-list is nill please exec (load-planned-file)!! ~%")
    (progn
      (dolist (plan *plan-list*)
        (print plan)
        )
      ))
  )

(defun exec-plan-list ()
  (if (null *plan-list*)
      (format t "now plan-list is nill please exec (load-planned-file)!! ~%")
    (progn
      (dolist (plan *plan-list*)
        (eval plan)
        )
      ))
  )

(format t "~% Please run (read-file [file-name]) ~%")

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

(setq egg "egg")
(setq cooked-egg "cooked-egg")
(setq boiling "boiling")
(setq whirlpool "whirlpool")
(setq three-minutes "three-minutes")
(setq low-heat "low-heat")
(setq boiled-water "boiled-water")
(setq vortexed-water "vortexed-water")

(setq milk "milk")
(setq salt "salt")
(setq butter "butter")
(setq small-bowl "small-bowl")
(setq egg-mixture "egg-mixture")
(setq melted-butter "melted-butter")
(setq melt "melt")
(setq half-cooked-egg "half-cooked-egg")
(setq soft-scrambled-egg "soft-scrambled-egg")
(setq spatula "spatula")
(setq melted "melted")
(setq half-cooked-egg "half-cooked-egg")
(setq whole-mixture-tender "whole-mixture-tender")

(setq salad-oil "salad-oil")
(setq thirty-seconds "thirty-seconds")
(setq heat-through "heat-through")
(setq oil "oil")


