(defun init ()
  (warn "init! ~%")

(defun curry-0 ()
  (unix:sleep 1)
  (warn "調理の準備 ~%")
  )

(defun curry-1 ()
  (unix:sleep 1)
  (warn "人参の下ごしらえ ~%")
  )

(defun curry-2 ()
  (unix:sleep 1)
  (warn "じゃがいもの下ごしらえ ~%")
  )

(defun curry-3 ()
  (unix:sleep 1)
  (warn "たまねぎの下ごしらえ ~%")
  )

(defun curry-4 ()
  (unix:sleep 1)
  (warn "炒める調理の準備 ~%")
  )

(defun curry-5 ()
  (unix:sleep 1)
  (warn "たまねぎを炒める調理 ~%")
  )

(defun curry-6 ()
  (unix:sleep 1)
  (warn "肉を炒める調理 ~%")
  )

(defun curry-7 ()
  (unix:sleep 1)
  (warn "煮込む調理の準備 ~%")
  )

(defun curry-8 ()
  (unix:sleep 1)
  (warn "煮込む調理 ~%")
  )

(defun curry-9 ()
  (unix:sleep 1)
  (warn "仕上げ ~%")
  )


;; recovery
(defun curry-0-recovery ()
  (unix:sleep 1)
  (warn "調理の準備 からの復帰  ~%")
  )

(defun curry-1-recovery ()
  (unix:sleep 1)
  (warn "人参の下ごしらえ からの復帰 ~%")
  )

(defun curry-2-recovery ()
  (unix:sleep 1)
  (warn "じゃがいもの下ごしらえ からの復帰 ~%")
  )

(defun curry-3-recovery ()
  (unix:sleep 1)
  (warn "たまねぎの下ごしらえ からの復帰 ~%")
  )

(defun curry-4-recovery ()
  (unix:sleep 1)
  (warn "炒める調理の準備 からの復帰 ~%")
  )

(defun curry-5-recovery ()
  (unix:sleep 1)
  (warn "たまねぎを炒める調理 からの復帰 ~%")
  )

(defun curry-6-recovery ()
  (unix:sleep 1)
  (warn "肉を炒める調理 からの復帰 ~%")
  )

(defun curry-7-recovery ()
  (unix:sleep 1)
  (warn "煮込む調理の準備 からの復帰 ~%")
  )

(defun curry-8-recovery ()
  (unix:sleep 1)
  (warn "煮込む調理 からの復帰 ~%")
  )

(defun curry-9-recovery ()
  (unix:sleep 1)
  (warn "仕上げ からの復帰 ~%")
  )

