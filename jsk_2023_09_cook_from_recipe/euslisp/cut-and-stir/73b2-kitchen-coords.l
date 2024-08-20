(load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/pr2_cut_food.l")

(defun 73b2-kitchen-coords-init (&key (type :curry))
  ;; set global coords

  ;; (setq *kitchen-spot* (make-coords :pos (float-vector 1110 8500 30000) :rpy (float-vector pi 0 0))) ;; original

  ;; (setq *kitchen-plane-coords* (make-coords :pos #f(815 -15 835)))
  (setq *kitchen-plane-coords* (make-coords :pos #f(815 -15 830)))
  (setq *kitchen-plane-end-1* (make-coords :pos #f(1100 330 840)))
  (setq *kitchen-plane-end-2* (make-coords :pos #f(1100 -360 840)))
  (setq *kitchen-plane-end-3* (make-coords :pos #f(530 330 840)))
  (setq *kitchen-plane-end-4* (make-coords :pos #f(530 -360 840)))

  (case type
        (:curry
         (setq *knife-coords* (make-coords :pos (float-vector 608.887 -297.217 838.11) :rpy (float-vector 0.062 0.168 -1.546))) ;; knife fix v3 upper

         (setq *peeler-coords* (make-coords :pos (float-vector 585.801 -107.456 852.203) :rpy (float-vector -0.006 -0.008 -1.56))) ;; ピーラー fix v3 upper

         (setq *potato-peeler-coords* (make-coords :pos (float-vector 602.942 -206.253 848.018) :rpy (float-vector -0.019 0.112 -1.557))) ;; じゃがいもピーラー fix v3 upper

         ;; (setq *spatula-coords-1* (make-coords :pos (float-vector 630 8549 30872) :rpy (float-vector 3.084 -0.042 1.542))) ;; ヘラ，平置き original
         ;; (setq *spatula-coords-1* (make-coords :pos (float-vector 480.0 -49.0 872.0) :rpy (float-vector -0.058 -0.042 1.542))) ;; ヘラ，平置き fix
         ;; (setq *spatula-coords-1* (make-coords :pos (float-vector 600.0 -49.0 872.0) :rpy (float-vector -0.058 -0.042 1.542))) ;; ヘラ，平置き fix v2
         (setq *spatula-coords-1* (make-coords :pos (float-vector 600.0 51.0 872.0) :rpy (float-vector -0.058 -0.042 1.542))) ;; ヘラ，平置き fix v2 upper

         ;; (setq *ladle-coords-1* (make-coords :pos (float-vector 630 8313 30877) :rpy (float-vector 3.128 -0.098 1.514))) ;; おたま，平置き original
         ;; (setq *ladle-coords-1* (make-coords :pos (float-vector 480.0 187.0 877.0) :rpy (float-vector -0.014 -0.098 1.514))) ;; おたま，平置き fix
         ;; (setq *ladle-coords-1* (make-coords :pos (float-vector 600.0 187.0 877.0) :rpy (float-vector -0.014 -0.098 1.514))) ;; おたま，平置き fix v2
         (setq *ladle-coords-1* (make-coords :pos (float-vector 600.0 287.0 877.0) :rpy (float-vector -0.014 -0.098 1.514))) ;; おたま，平置き fix v2 upper

         ;; (setq *pot-coords* (make-coords :pos (float-vector 450 8080 30850) :rpy (float-vector 3.142 0 0))) ;; original
         ;; (setq *pot-coords* (make-coords :pos (float-vector 660.0 420.0 850.0) :rpy (float-vector 0 0 0))) ;; fix
         (setq *pot-coords* (make-coords :pos (float-vector 780.0 420.0 850.0) :rpy (float-vector 0 0 0))) ;; pot fix v2

         ;; (setq *shelf-door-coords* (make-coords :pos (float-vector 400 8840 31445) :rpy (float-vector 3.14 0 0))) ;; orginal
         ;; (setq *shelf-door-coords* (make-coords :pos (float-vector 710.0 -340.0 1445.0) :rpy (float-vector -0.002 0.0 0.0))) ;; fix
         (setq *shelf-door-coords* (make-coords :pos (float-vector 830.0 -340.0 1445.0) :rpy (float-vector -0.002 0.0 0.0))) ;; shelf fix v2

         ;; (setq *mcup-coords* (make-coords :pos (float-vector 530 7710 30850) :rpy (float-vector -0.948 0 0))) ;; original
         (setq *mcup-coords* (make-coords :pos (float-vector 580.0 790.0 850.0) :rpy (float-vector 2.194 0.0 0.0))) ;; fix

         ;; (setq *rcup-coords* (make-coords :pos (float-vector 320 8525 30840))) ;; original
         (setq *rcup-coords* (make-coords :pos (float-vector 790.0 -25.0 840.0) :rpy (float-vector (- pi) 0.0 0.0))) ;; fix

         (setq *gray-bowl-kitchen-coords* (make-coords :pos (float-vector 880.0 -160.0 840.0) :rpy (float-vector 0 0 0))) ;; fix

         ;; (setq *oil-dispenser-coords* (make-coords :pos (float-vector 300 8280 30845) :rpy (float-vector 3.14 0.0 0.0))) ;; original
         (setq *oil-dispenser-coords* (make-coords :pos (float-vector 810.0 220.0 845.0) :rpy (float-vector 0.0 0.0 0.0))) ;; fix

         ;; (setq *cutting-board-coords* (make-coords :pos (float-vector 560 8420 30840) :rpy (float-vector 0 0 0))) ;; original
         ;; (setq *cutting-board-coords* (make-coords :pos (float-vector 550.0 80.0 840.0) :rpy (float-vector (- pi) 0 0))) ;; fix
         (setq *cutting-board-coords* (make-coords :pos (float-vector 660.0 130.0 840.0) :rpy (float-vector (- pi) 0 0))) ;; fix v2
         )
        (:old-curry
         ;; (setq *knife-coords* (make-coords :pos (float-vector 600 8715 30857) :rpy (float-vector 3.14 0.073 1.498))) ;; original
         ;; (setq *knife-coords* (make-coords :pos (float-vector 510.0 -215.0 857.0) :rpy (float-vector -0.002 0.073 1.498))) ;; fix
         ;; (setq *knife-coords* (make-coords :pos (float-vector 630.0 -215.0 857.0) :rpy (float-vector -0.002 0.073 1.498))) ;; knife fix v2
         ;; (setq *knife-coords* (make-coords :pos (float-vector 630.0 -115.0 857.0) :rpy (float-vector -0.002 0.073 1.498))) ;; knife fix v2 upper
         (setq *knife-coords* (make-coords :pos (float-vector 608.887 -297.217 838.11) :rpy (float-vector 0.062 0.168 -1.546))) ;; knife fix v3 upper

         ;; (setq *peeler-coords* (make-coords :pos (float-vector 580 8815 30870) :rpy (float-vector 3.14 0.049 1.51))) ;; ピーラー original
         ;; (setq *peeler-coords* (make-coords :pos (float-vector 530.0 -315.0 870.0) :rpy (float-vector -0.002 0.049 1.51))) ;; ピーラー fix
         ;; (setq *peeler-coords* (make-coords :pos (float-vector 650.0 -315.0 870.0) :rpy (float-vector -0.002 0.049 1.51))) ;; ピーラー fix v2
         ;; (setq *peeler-coords* (make-coords :pos (float-vector 650.0 -215.0 870.0) :rpy (float-vector -0.002 0.049 1.51))) ;; ピーラー fix v2 upper
         (setq *peeler-coords* (make-coords :pos (float-vector 585.801 -107.456 852.203) :rpy (float-vector -0.006 -0.008 -1.56))) ;; ピーラー fix v3 upper

         ;; (setq *potato-peeler-coords* (make-coords :pos (float-vector 580 8915 30865) :rpy (float-vector 3.14 0.013 1.545))) ;; じゃがいもピーラー original
         ;; (setq *potato-peeler-coords* (make-coords :pos (float-vector 530.0 -415.0 865.0) :rpy (float-vector -0.002 0.013 1.545))) ;; じゃがいもピーラー fix
         ;; (setq *potato-peeler-coords* (make-coords :pos (float-vector 650.0 -415.0 865.0) :rpy (float-vector -0.002 0.013 1.545))) ;; じゃがいもピーラー fix v2
         ;; (setq *potato-peeler-coords* (make-coords :pos (float-vector 650.0 -315.0 865.0) :rpy (float-vector -0.002 0.013 1.545))) ;; じゃがいもピーラー fix v2 upper
         (setq *potato-peeler-coords* (make-coords :pos (float-vector 602.942 -206.253 848.018) :rpy (float-vector -0.019 0.112 -1.557))) ;; じゃがいもピーラー fix v3 upper

         ;; (setq *spatula-coords-1* (make-coords :pos (float-vector 630 8549 30872) :rpy (float-vector 3.084 -0.042 1.542))) ;; ヘラ，平置き original
         ;; (setq *spatula-coords-1* (make-coords :pos (float-vector 480.0 -49.0 872.0) :rpy (float-vector -0.058 -0.042 1.542))) ;; ヘラ，平置き fix
         ;; (setq *spatula-coords-1* (make-coords :pos (float-vector 600.0 -49.0 872.0) :rpy (float-vector -0.058 -0.042 1.542))) ;; ヘラ，平置き fix v2
         (setq *spatula-coords-1* (make-coords :pos (float-vector 600.0 51.0 872.0) :rpy (float-vector -0.058 -0.042 1.542))) ;; ヘラ，平置き fix v2 upper

         ;; (setq *ladle-coords-1* (make-coords :pos (float-vector 630 8313 30877) :rpy (float-vector 3.128 -0.098 1.514))) ;; おたま，平置き original
         ;; (setq *ladle-coords-1* (make-coords :pos (float-vector 480.0 187.0 877.0) :rpy (float-vector -0.014 -0.098 1.514))) ;; おたま，平置き fix
         ;; (setq *ladle-coords-1* (make-coords :pos (float-vector 600.0 187.0 877.0) :rpy (float-vector -0.014 -0.098 1.514))) ;; おたま，平置き fix v2
         (setq *ladle-coords-1* (make-coords :pos (float-vector 600.0 287.0 877.0) :rpy (float-vector -0.014 -0.098 1.514))) ;; おたま，平置き fix v2 upper

         ;; (setq *pot-coords* (make-coords :pos (float-vector 450 8080 30850) :rpy (float-vector 3.142 0 0))) ;; original
         ;; (setq *pot-coords* (make-coords :pos (float-vector 660.0 420.0 850.0) :rpy (float-vector 0 0 0))) ;; fix
         (setq *pot-coords* (make-coords :pos (float-vector 780.0 420.0 850.0) :rpy (float-vector 0 0 0))) ;; pot fix v2

         ;; (setq *shelf-door-coords* (make-coords :pos (float-vector 400 8840 31445) :rpy (float-vector 3.14 0 0))) ;; orginal
         ;; (setq *shelf-door-coords* (make-coords :pos (float-vector 710.0 -340.0 1445.0) :rpy (float-vector -0.002 0.0 0.0))) ;; fix
         (setq *shelf-door-coords* (make-coords :pos (float-vector 830.0 -340.0 1445.0) :rpy (float-vector -0.002 0.0 0.0))) ;; shelf fix v2

         ;; (setq *mcup-coords* (make-coords :pos (float-vector 530 7710 30850) :rpy (float-vector -0.948 0 0))) ;; original
         (setq *mcup-coords* (make-coords :pos (float-vector 580.0 790.0 850.0) :rpy (float-vector 2.194 0.0 0.0))) ;; fix

         ;; (setq *rcup-coords* (make-coords :pos (float-vector 320 8525 30840))) ;; original
         (setq *rcup-coords* (make-coords :pos (float-vector 790.0 -25.0 840.0) :rpy (float-vector (- pi) 0.0 0.0))) ;; fix

         ;; (setq *bowl-1-kitchen-coords* (make-coords :pos (float-vector 279 8747 30823) :rpy (float-vector 0 0 0))) ;; original
         (setq *bowl-1-kitchen-coords* (make-coords :pos (float-vector 831.0 -247.0 823.0) :rpy (float-vector (- pi) 0 0))) ;; fix

         ;; (setq *oil-dispenser-coords* (make-coords :pos (float-vector 300 8280 30845) :rpy (float-vector 3.14 0.0 0.0))) ;; original
         (setq *oil-dispenser-coords* (make-coords :pos (float-vector 810.0 220.0 845.0) :rpy (float-vector 0.0 0.0 0.0))) ;; fix

         ;; (setq *cutting-board-coords* (make-coords :pos (float-vector 560 8420 30840) :rpy (float-vector 0 0 0))) ;; original
         ;; (setq *cutting-board-coords* (make-coords :pos (float-vector 550.0 80.0 840.0) :rpy (float-vector (- pi) 0 0))) ;; fix
         (setq *cutting-board-coords* (make-coords :pos (float-vector 660.0 130.0 840.0) :rpy (float-vector (- pi) 0 0))) ;; fix v2
         )
        (:scrambled-egg
         (setq *gray-bowl-kitchen-coords* (make-coords :pos (float-vector 880.0 -160.0 840.0) :rpy (float-vector 0 0 0))) ;; fix

         )
        )

  )


(defun 73b2-stove-coords-init (&key (type :curry))
  ;; set global coords

  ;; (setq *kitchen-spot* (make-coords :pos (float-vector 1110 8500 30000) :rpy (float-vector pi 0 0))) ;; original
  ;; (setq *stove-spot* (make-coords :pos (float-vector 1200 8100 30000) :rpy (float-vector pi 0 0))) ;; original


  ;; (setq *kitchen-plane-coords* (make-coords :pos #f(815 -15 835)))
  (setq *kitchen-plane-coords* (make-coords :pos #f(815 -15 830)))
  (setq *kitchen-plane-end-1* (make-coords :pos #f(1100 330 840)))
  (setq *kitchen-plane-end-2* (make-coords :pos #f(1100 -360 840)))
  (setq *kitchen-plane-end-3* (make-coords :pos #f(530 330 840)))
  (setq *kitchen-plane-end-4* (make-coords :pos #f(530 -360 840)))

  (case type
        (:curry

         )
        (:old-curry
         ;; (setq *spatula-coords-1* (make-coords :pos (float-vector 630 8549 30872) :rpy (float-vector 3.084 -0.042 1.542))) ;; ヘラ，平置き original
         (setq *spatula-coords-1* (make-coords :pos (float-vector 570.0 -449.0 872.0) :rpy (float-vector -0.058 -0.042 1.542))) ;; ヘラ，平置き fix

         ;; (setq *ladle-coords-1* (make-coords :pos (float-vector 630 8313 30877) :rpy (float-vector 3.128 -0.098 1.514))) ;; おたま，平置き original
         (setq *ladle-coords-1* (make-coords :pos (float-vector 570.0 -213.0 877.0) :rpy (float-vector -0.014 -0.098 1.514))) ;; おたま，平置き fix

         ;; (setq *mcup-coords* (make-coords :pos (float-vector 530 7710 30850) :rpy (float-vector -0.948 0 0))) ;; 計量カップ original
         (setq *mcup-coords* (make-coords :pos (float-vector 670.0 390.0 850.0) :rpy (float-vector 2.194 0.0 0.0))) ;; 計量カップ fix

         ;; (setq *bowl-1-stove-coords* (make-coords :pos (float-vector 330 8661 30840) :rpy (float-vector -0.423 0 0))) ;; bowl1 original
         (setq *bowl-1-stove-coords* (make-coords :pos (float-vector 870.0 -561.0 840.0) :rpy (float-vector 2.719 0.0 0.0))) ;; bowl1 fix

         ;; (setq *bowl-2-stove-coords* (make-coords :pos (float-vector 480 7845 30850) :rpy (float-vector -0.175 0 0))) ;; bowl-2 original
         (setq *bowl-2-stove-coords* (make-coords :pos (float-vector 720.0 255.0 850.0) :rpy (float-vector 2.967 0.0 0.0))) ;; bowl-2 fix

         ;; (setq *bowl-3-stove-coords* (make-coords :pos (float-vector 555 7585 30840) :rpy (float-vector 1.048 0 0))) ;; bowl-3 original
         (setq *bowl-3-stove-coords* (make-coords :pos (float-vector 645.0 515.0 840.0) :rpy (float-vector -2.094 0.0 0.0))) ;; bowl-3 fix

         ;; (setq *oil-dispenser-stove-coords* (make-coords :pos (float-vector 400 7570 30845) :rpy (float-vector 3.14 0.0 0.0))) ;; oil dispenser original
         (setq *oil-dispenser-stove-coords* (make-coords :pos (float-vector 800.0 530.0 845.0) :rpy (float-vector -0.002 0.0 0.0))) ;; oil dispenser fix

         ;; (setq *pot-coords* (make-coords :pos (float-vector 450 8080 30850) :rpy (float-vector 3.142 0 0))) ;; pot original
         (setq *pot-coords* (make-coords :pos (float-vector 750.0 20.0 850.0) :rpy (float-vector 0.0 0.0 0.0))) ;; pot fix

         )
        )
  )

(warn "please run (curry-kitchen-view) ~%")

(defun curry-kitchen-view ()
  (73b2-kitchen-coords-init :type :curry)

  (unless (boundp '*knife*)
    (progn
      (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/knife-new-attention.l")
      (setq *knife* (knife))
      ))

  (unless (boundp '*peeler*)
    (progn
      (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/peeler.l")
      (setq *peeler* (peeler))
      ))

  (unless (boundp '*potato-peeler*)
    (progn
      (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/potato-peeler.l")
      (setq *potato-peeler* (peeler))
      ))

  (unless (boundp '*spatula*)
    (progn
      (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/spatula.l")
      (setq *spatula* (spatula))
      ))

  (unless (boundp '*ladle*)
    (progn
      (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/ladle.l")
      (setq *ladle* (ladle))
      ))

  (unless (boundp '*shelf-door*)
    (progn
      (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/shelf-door.l")
      (setq *shelf-door* (shelf-door))
      ))

  (unless (boundp '*cutting-board*)
    (progn
      (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/cutting-board.l")
      (setq *cutting-board* (cutting-board))
      ))

  (unless (boundp '*gray-bowl*)
    (progn
      (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/gray-bowl.l")
      (setq *gray-bowl* (gray-bowl))
      ))

  (unless (boundp '*pot*)
    (progn
      (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/cooking-pot-73b2.l")
      (setq *pot* (cooking-pot))
      ))

  (unless (boundp '*cutting-board*)
    (progn
      (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/cutting-board.l")
      (setq *cutting-board* (cutting-board))
      ))

  (unless (boundp '*kitchen-plane*)
    (progn
      (load "package://jsk_2023_09_cook_from_recipe/euslisp/cut-and-stir/models/kitchen-plane.l")
      (setq *kitchen-plane* (kitchen-plane :cube-x 570 :cube-y 690 :cube-z 10))
      ))

  (unless (boundp '*arrow*)
    (progn
      (load "models/arrow-object.l")
      (setq *arrow* (arrow))
      ))

  (dissoc-object *knife*)
  (send *knife* :newcoords (send *knife-coords* :copy-worldcoords))

  (dissoc-object *peeler*)
  (send *peeler* :newcoords (send *peeler-coords* :copy-worldcoords))

  (dissoc-object *potato-peeler*)
  (send *potato-peeler* :newcoords (send *potato-peeler-coords* :copy-worldcoords))

  (dissoc-object *spatula*)
  (send *spatula* :newcoords (send *spatula-coords-1* :copy-worldcoords))

  (dissoc-object *ladle*)
  (send *ladle* :newcoords (send *ladle-coords-1* :copy-worldcoords))

  (dissoc-object *pot*)
  (send *pot* :newcoords (send *pot-coords* :copy-worldcoords))

  (dissoc-object *gray-bowl*)
  (send *gray-bowl* :newcoords (send *gray-bowl-kitchen-coords* :copy-worldcoords))

  (dissoc-object *cutting-board*)
  (send *cutting-board* :newcoords (send *cutting-board-coords* :copy-worldcoords))

  (send *kitchen-plane* :newcoords  (send *kitchen-plane-coords* :copy-worldcoords))

  ;; set equipment
  (dissoc-object *shelf-door*)
  (send *shelf-door* :newcoords (send *shelf-door-coords* :copy-worldcoords))

  (setq *shelf-look-coords* (send (send *shelf-door* :handle-handle0) :copy-worldcoords))

  (objects (list *pr2* *kitchen-plane* *peeler* *knife* *potato-peeler* *spatula* *ladle* *shelf-door* *gray-bowl* *cutting-board* *pot*))
  )
