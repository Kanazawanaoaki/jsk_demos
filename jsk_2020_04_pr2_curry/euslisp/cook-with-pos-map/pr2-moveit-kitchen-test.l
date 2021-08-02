(defun moveit-test-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")
  
  ;; set tools
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/knife-new-attention.l")
  (setq *knife* (knife))
  (send *knife* :newcoords (send *knife-coords* :copy-worldcoords))

  (load "package://jsk_2020_04_pr2_curry/euslisp/model/peeler.l")
  (setq *peeler* (peeler))
  (send *peeler* :newcoords (send *peeler-coords* :copy-worldcoords))

  (load "package://jsk_2020_04_pr2_curry/euslisp/model/potato-peeler.l")
  (setq *potato-peeler* (peeler))
  (send *potato-peeler* :newcoords (send *potato-peeler-coords* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/spatula.l")
  (setq *spatula* (spatula))
  (send *spatula* :newcoords (send *spatula-coords-1* :copy-worldcoords))

  (load "package://jsk_2020_04_pr2_curry/euslisp/model/ladle.l")
  (setq *ladle* (ladle))
  (send *ladle* :newcoords (send *ladle-coords-1* :copy-worldcoords))
  
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/cooking-pot-73b2.l")
  (setq *pot* (cooking-pot))
  (send *pot* :newcoords (send *pot-coords* :copy-worldcoords))
  
  ;; set equipment
  (load "package://jsk_2020_04_pr2_curry/euslisp/model/shelf-door.l")
  (setq *shelf-door* (shelf-door))
  (send *shelf-door* :newcoords (send *shelf-door-coords* :copy-worldcoords))

  (setq *shelf-look-coords* (send (send *shelf-door* :handle-handle0) :copy-worldcoords))

  (unless (boundp '*bowl-1*)
    (progn
      (load "package://jsk_2020_04_pr2_curry/euslisp/model/bowl-1.l")
      (setq *bowl-1* (bowl-1))
      ))
  (if (not (eql (send *bowl-1* :parent) nil))
      (send (send *bowl-1* :parent) :dissoc *bowl-1*))
  ;; (send *bowl-1* :newcoords (send *bowl-1-stove-coords* :copy-worldcoords))
  (send *bowl-1* :newcoords (send *bowl-1-kitchen-coords* :copy-worldcoords))

  (move-to-kitchen-irt)
  (objects (list *pr2* *peeler* *knife* *potato-peeler* *scene* *spatula* *ladle* *shelf-door* *bowl-1*))
  (update-view)

  )

(defun moveit-init ()
  (load "package://pr2eus_moveit/euslisp/pr2eus-moveit.l")
  (send *ri* :set-moveit-environment (instance pr2-moveit-environment :init))
  )

(moveit-test-init)
(moveit-init)


(defun grasp-knife-moveit ()
  ;;掴む位置
  (send *arrow* :newcoords (send *knife* :copy-worldcoords))
  (send *arrow* :translate #f(-12 0 0))
  (send *arrow* :rotate (deg2rad -90) :x)
  
  ;; ここに入れる
  
  (send *arrow* :translate #f(50 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :angle-vector-motion-plan (send *pr2* :angle-vector) :total-time 5000 :ctype :rarm-controller :start-offset-time 0 :move-arm :rarm)
  (send *ri* :wait-interpolation)
  (send *ri* :stop-grasp :rarm :wait t)
  
  (send *arrow* :translate #f(-50 0 -100) :world)  
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  
  
  (send *ri* :start-grasp :rarm :wait t)
  (send (send *pr2* :rarm :end-coords) :assoc *knife*)
  
  ;; 手を上げる
  (send *arrow* :newcoords (send (send *pr2* :rarm :end-coords) :copy-worldcoords))
  (send *arrow* :translate #f(60 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )



(defun grasp-bowl-1-moveit ()
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *bowl-1* :handle-handle0) :copy-worldcoords))
    
  ;; ボウルの位置
  (send *arrow* :newcoords (send *target* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :angle-vector-motion-plan (send *pr2* :angle-vector) :total-time 5000 :ctype :rarm-controller :start-offset-time 0 :move-arm :rarm)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm :wait t)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :start-grasp :rarm :wait t)
  
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  


  )

(defun grasp-bowl-1 ()
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *bowl-1* :handle-handle0) :copy-worldcoords))
    
  ;; ボウルの位置
  (send *arrow* :newcoords (send *target* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  ;; (send *ri* :angle-vector-motion-plan (send *pr2* :angle-vector) :total-time 5000 :ctype :rarm-controller :start-offset-time 0 :move-arm :rarm)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm :wait t)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :start-grasp :rarm :wait t)
  
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)  


  )


(warn "please run (test-1) ~%")


(defun test-1 ()
  (set-pose)

  (send *arrow* :newcoords (make-coords :pos #f(807.411 8629.439 30567.735) :rpy #f(-2.248 0.433 -2.951)))
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (warn "please run (test-2) ~%")
  )

(defun test-2 ()
  (setq *target* (make-coords))
  (send *target* :newcoords (send (send *bowl-1* :handle-handle0) :copy-worldcoords))
    
  ;; ボウルの位置
  (send *arrow* :newcoords (send *target* :copy-worldcoords))
  (send *arrow* :translate (float-vector 0 0 200) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  ;; (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :angle-vector-motion-plan (send *pr2* :angle-vector) :total-time 5000 :ctype :rarm-controller :start-offset-time 0 :move-arm :rarm)
  (send *ri* :wait-interpolation)

  (send *ri* :stop-grasp :rarm :wait t)

  (warn "please run (test-3) ~%")
  )

(defun test-3 ()
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 -100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  
  (send *ri* :start-grasp :larm :wait t)

  (warn "please run (test-4) ~%")
  )

(defun test-4 ()
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  
  (send *arrow* :translate (float-vector 0 0 100) :world)
  (send *pr2* :rarm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 4000)
  (send *ri* :wait-interpolation)
  )

