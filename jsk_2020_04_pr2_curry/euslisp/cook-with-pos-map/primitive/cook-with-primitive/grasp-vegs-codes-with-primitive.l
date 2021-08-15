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
  
  ;; (move-to-kitchen-irt)
  (move-to-spot-irt *kitchen-spot*)
  (objects (list *pr2* *scene* *cutting-board* *potato* *carrot* *onion*))
  (update-view)  
  )

(grasp-vegs-init)

(warn "If you use real robot, run (update-pos) ~%")
(warn "please run (now-transfer) or (now-transfer-bowl-1) ~%")

;; def funcs
(defun set-vegs-model (veg)
  (if (not (eql (send veg :parent) nil))
      (send (send veg :parent) :dissoc veg))
  (let (local-cds)
    (setq local-cds (make-cascoords))
    (send local-cds :newcoords (send veg :copy-worldcoords))
    (send local-cds :translate #f(-20 0 0))
    (send local-cds :rotate (deg2rad 45) :y)
    (send local-cds :assoc veg)
    (send local-cds :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
    (send local-cds :dissoc veg)
    )
  (send *viewer* :draw-objects)
  (send (send *pr2* :larm :end-coords) :assoc veg)
  )

(defun before-receive-larm ()
  ;;少し上に
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(0 0 250) :world)
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm) ;; move-arm primitive
  
  ;;少し前に
  (send *arrow* :newcoords (make-coords :pos (send (send (send *pr2* :larm :end-coords) :copy-worldcoords) :worldpos)))
  (send *arrow* :translate #f(-200 50 50) :world)
  (send *arrow* :rotate (deg2rad 90) :z :world)
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm) ;; move-arm primitive
  )

(defun grasp-carrot ()
  ;; 人参の掴む所に
  (send *arrow* :newcoords (send *carrot* :copy-worldcoords))
  (send *arrow* :translate #f(-20 0 0))
  (send *arrow* :rotate (deg2rad 45) :y)
  
  ;; (send *arrow* :translate #f(-10 -15 -5) :world)
  
  ;;gripperを開く
  (send *ri* :stop-grasp :larm :wait t)
  ;; move-gripper primitiveに変更する？
  
  (send *arrow* :translate #f(100 0 100) :world)
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm) ;; move-arm primitive

  (send *arrow* :translate #f(-100 0 -100) :world)
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm) ;; move-arm primitive
  
  ;;gripperを閉じる
  (grasp-object :arm :larm)
  (grasp-object :arm :larm :gain 0.05)
  
  (set-vegs-model *carrot*)
  
  (warn "please run (after-grasp-vegs) ~%")  
  )

(defun grasp-carrot-with-fail-detection ()
  (setq tmp-coords (send *carrot* :copy-worldcoords))
  (grasp-carrot)
  
  ;; 失敗を検知する
  ;; (grasp-fail-detection-larm :g-thre 10)
  (grasp-fail-detection :arm :larm :g-thre 10)
  (if (equal *fail-flag* t) ;; 一度失敗したらもう一度挑戦する
      (progn
        (if (not (eql (send *carrot* :parent) nil))
            (send (send *carrot* :parent) :dissoc *carrot*))
        (send *carrot* :newcoords tmp-coords)
        (grasp-carrot)
        ;; (grasp-fail-detection-larm :g-thre 10)
        (grasp-fail-detection :arm :larm :g-thre 10)
        (if (equal *fail-flag* t) ;; 二度失敗したら人に助けてもらう
            (progn
              (send *ri* :speak-jp "人参の把持が失敗しました，渡す準備をして合図をして下さい")
              (receive-with-dialogue-larm)
              (send *ri* :start-grasp :rarm :wait t)
              ))
        ))
  )

(defun after-grasp-vegs ()
  ;; 左手を少しあげる
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(100 0 100) :world)
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm :times 2000) ;; move-arm primitive 
  
  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(100 0 100) :world)
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm :times 2000) ;; move-arm primitive 

  (send *arrow* :newcoords (send (send *pr2* :larm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(100 0 0) :world)
  (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm :times 2000) ;; move-arm primitive
  
  (warn "please run (vegs-carry-pose) ~%")  
  )

(defun vegs-carry-pose ()
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 640 8445 31174) :rpy (float-vector 1.587 0 0)))
  ;; (send *pr2* :larm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :move-target *potato*
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  ;; (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 8000)
  ;; (send *ri* :wait-interpolation)
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 640.324 8425.003 31174.0) :rpy (float-vctor 1.587 0.785 0.0)))
  ;; (send *pr2* :rarm :inverse-kinematics
  ;;       (send *arrow* :copy-worldcoords)
  ;;       :rotation-axis t
  ;;       :debug-view *debug-flag*)
  (setq *lav-vc* #f(35.2692 -2.67452 58.1589 -95.2169 65.0479 -80.0523 -157.341))
  (move-arm-av *lav-vc* :arm :larm :times 8000) ;; move-arm primitive
  
  ;; (send *arrow* :newcoords (make-coords :pos (float-vector 640.324 8425.003 31174.0) :rpy (float-vctor 1.587 0.785 0.0)))
  ;; (send *arrow* :translate #f(100 0 0) :world)
  ;; (move-arm-ik (send *arrow* :copy-worldcoords) :arm :larm :times 8000) ;; move-arm primitive
  
  (warn "please go to sink spot !! ~%")  
  )



(defun now-grasp-carrot-with-fail-detection ()
  (before-receive-larm)
  (grasp-carrot-with-fail-detection)
  (after-grasp-vegs)
  (vegs-carry-pose)  
  )


(defun now-put-carrot-on-board ()
  (put-carrot-on-board)
  (reset-larm)
  )
