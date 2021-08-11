(defun grasp-vegs-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/primitive/my-cook-primitive-funcs.l")
  
  ;; set global coodes
  (setq *potato-stand-coords* (make-coords :pos (float-vector 310.071 8313.284 30947) :rpy (float-vector 3.142 0 0)))
  (setq *carrot-stand-coords* (make-coords :pos (float-vector 309.029 8399.786 30947) :rpy (float-vector 3.142 0 0)))
  (setq *onion-stand-coords* (make-coords :pos (float-vector 314.539 8479.935 30947) :rpy (float-vector 3.142 0 0)))
  
  ;; set objscts
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/cutting-board.l")
  (setq *cutting-board* (cutting-board))
  (send *cutting-board* :newcoords (send *cutting-board-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/potato-new-type.l")
  (setq *potato* (potato :w 90 :l 60 :h 60))
  ;; (send *potato* :transform (make-coords :pos (float-vector 310.071 8313.284 30937.902) :rpy (float-vector 3.142 0 0)))
  (send *potato* :newcoords (send *potato-stand-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/carrot-ellipsoid-model.l")
  (setq *carrot* (carrot :w 140 :l 50 :h 50))
  ;; (send *carrot* :transform (make-coords :pos (float-vector 309.029 8399.786 30942.039) :rpy (float-vector 3.142 0 0)))
  (send *carrot* :newcoords (send *carrot-stand-coords* :copy-worldcoords))
  
  (setq *onion* (make-cube 100 50 40))
  (send *onion* :set-color :green)
  ;; (send *onion* :transform (make-coords :pos (float-vector 314.539 8479.935 30946.933) :rpy (float-vector 3.142 0 0)))
  (send *onion* :newcoords (send *onion-stand-coords* :copy-worldcoords))
  
  (move-to-kitchen-irt)
  (objects (list *pr2* *scene* *cutting-board* *potato* *carrot* *onion*))
  (update-view)  
  )

(grasp-vegs-init)

(warn "If you use real robot, run (update-pos) ~%")
(warn "please run (now-transfer) or (now-transfer-bowl-1) ~%")


(defun before-receive-larm ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 250) :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis nil
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  ;;少し前に
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate #f(-200 50 50) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  )

(defun grasp-carrot-with-fail-detection ()
  (setq tmp-coords (send *carrot* :copy-worldcoords))
  (grasp-carrot)
  
  ;; 失敗を検知する
  (grasp-fail-detection-larm :g-thre 10)
  (if (equal *fail-flag* t) ;; 一度失敗したらもう一度挑戦する
      (progn
        (if (not (eql (send *carrot* :parent) nil))
            (send (send *carrot* :parent) :dissoc *carrot*))
        (send *carrot* :newcoords tmp-coords)
        (grasp-carrot)
        (grasp-fail-detection-larm :g-thre 10)
        (if (equal *fail-flag* t) ;; 二度失敗したら人に助けてもらう
            (progn
              (send *ri* :speak-jp "人参の把持が失敗しました，渡す準備をして合図をして下さい")
              (receive-with-dialogue-larm)
              (send *ri* :start-grasp :rarm :wait t)
              ))
        ))
  
  )




(defun now-grasp-carrot-with-fail-detection ()
  (before-receive-larm)
  (grasp-carrot-with-fail-detection)
  (after-grasp-vegs)
  (vegs-carry-pose)  
  )
