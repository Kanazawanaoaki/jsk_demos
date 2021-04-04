(defun teaching-init ()
  ;; init
  (load "package://jsk_2020_04_pr2_curry/euslisp/cook-with-pos-map/move-to-kitchen-with-map.l")

  ;; 揺するやつ
  (load "package://jsk_demo_common/euslisp/pr2-action.l")
  
  (move-to-kitchen-irt)
  (objects (list *pr2* *scene*))
  (update-view)
  )

(teaching-init)

(warn "~% there are teaching funcs  ~%")


;; add for remember
(defun list-init ()
  (setq *avs* (list))
  (setq *tms* (list))
  (setq *r-cds* (list))  
  (setq *l-cds* (list))  
  )



(defun remember-test ()
  (let (av)
    (list-init)
    (do-until-key
     (send *pr2* :angle-vector (send *ri* :state :potentio-vector))
     (setq av (send *pr2* :angle-vector))
     (setq *avs* (append *avs* (list av)))
     (setq *r-cds* (append *r-cds* (list (send *pr2* :rarm :end-coords))))
     (setq *l-cds* (append *l-cds* (list (send *pr2* :larm :end-coords))))
     (print av)
     (unix:usleep 100000) ;;10Hz?
     )
    ))


(defun replay-test ()
  (let ((l-len (length *avs*)))
    
    ;; tms のリストを作成
    (print l-len)
    (dotimes (i l-len)
      (setq *tms* (append *tms* (list 100)))
      )

    ;; 初期姿勢のセット
    (send *pr2* :angle-vector (elt *avs* 0))
    (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
    (send *ri* :wait-interpolation)  
    
    ;; 連続で動作させる
    (send *ri* :angle-vector-sequence *avs* *tms*)
    (send *ri* :wait-interpolation)  
    ))

(defun set-head-kanki ()
  (send *pr2* :head :neck-p :joint-angle 0)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)  
  )




(defun chukan-pose-1 ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 692.287 7989.295 31283.208) :rpy (float-vector 2.918 -0.857 -1.453)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  (warn "please run (chukan-pose-2) ~%")
  )

(defun chukan-pose-2 ()  
  (send *arrow* :newcoords (make-coords :pos (float-vector 764.174 7943.337 31679.313) :rpy (float-vector -2.699 -1.266 -1.978)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (warn "please run (on-kanki) ~%")
  )

(defun on-kanki ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 597.431 7984.14 31688.365) :rpy (float-vector -2.952 -0.903 -1.89)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (warn "please run (chukan-pose-2) ~%")
  )
  
(defun off-kanki ()
  (send *arrow* :newcoords (make-coords :pos (float-vector 598.489 7937.159 31691.522) :rpy (float-vector -2.832 -0.956 -1.827)))
  (send *pr2* :larm :inverse-kinematics
        (send *arrow* :copy-worldcoords)
        :rotation-axis t
        :debug-view *debug-flag*)
  (send *viewer* :draw-objects)
  (send *ri* :angle-vector (send *pr2* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  (warn "please run (chukan-pose-2) ~%")
  )
