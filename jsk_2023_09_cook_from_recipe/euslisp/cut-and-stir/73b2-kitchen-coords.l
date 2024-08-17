(defun 73b2-kitchen-coords-init (&key (type "curry"))
  ;; set global coords
  ;; (setq *knife-coords* (make-coords :pos (float-vector 600 8715 30857) :rpy (float-vector 3.14 0.073 1.498))) ;; original
  ;; (setq *knife-coords* (make-coords :pos (float-vector 510.0 -215.0 857.0) :rpy (float-vector -0.002 0.073 1.498))) ;; fix
  ;; (setq *knife-coords* (make-coords :pos (float-vector 630.0 -215.0 857.0) :rpy (float-vector -0.002 0.073 1.498))) ;; knife fix v2
  ;; (setq *knife-coords* (make-coords :pos (float-vector 630.0 -115.0 857.0) :rpy (float-vector -0.002 0.073 1.498))) ;; knife fix v2 upper
  (setq *knife-coords* (make-coords :pos (float-vector 608.887 -297.217 838.11) :rpy (float-vector 0.062 0.168 -1.546))) ;; knife fix v3 upper

  ;; (setq *peeler-coords* (make-coords :pos (float-vector 580 8815 30870) :rpy (float-vector 3.14 0.049 1.51))) ;; ピーラー original
  ;; (setq *peeler-coords* (make-coords :pos (float-vector 530.0 -315.0 870.0) :rpy (float-vector -0.002 0.049 1.51))) ;; ピーラー fix
  ;; (setq *peeler-coords* (make-coords :pos (float-vector 650.0 -315.0 870.0) :rpy (float-vector -0.002 0.049 1.51))) ;; ピーラー fix v2
  (setq *peeler-coords* (make-coords :pos (float-vector 650.0 -215.0 870.0) :rpy (float-vector -0.002 0.049 1.51))) ;; ピーラー fix v2 upper

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

  (setq *kitchen-plane-coords* (make-coords :pos #f(815 -15 835)))
  (setq *kitchen-plane-end-1* (make-coords :pos #f(1100 330 840)))
  (setq *kitchen-plane-end-2* (make-coords :pos #f(1100 -360 840)))
  (setq *kitchen-plane-end-3* (make-coords :pos #f(530 330 840)))
  (setq *kitchen-plane-end-4* (make-coords :pos #f(530 -360 840)))
  )
