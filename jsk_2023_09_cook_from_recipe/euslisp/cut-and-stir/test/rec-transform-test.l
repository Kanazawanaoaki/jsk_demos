#!/usr/bin/env roseus

(require :pr2-cook-utils "package://jsk_2023_09_cook_from_recipe/euslisp/pr2_cook_utils.l")

(reset-cook-pose)

(setq cook-from-now-file-name "../../av-files/cook-from-now-pour-green-bowl-from-pan-20250217-data-01.l")
(load-cook-from-now-file :file_name cook-from-now-file-name :larm nil)
;; (cook-from-now-replay-once :larm nil :initial-av nil :time 100) ;; default time is 150


(setq *cook-short-rec-list* (rav2rec *cook-short-rav-list*))

(setq orig-pan-coords (make-coords :pos #f(814.651 -94.265 878.52) :rpy #f(-0.753 -1.496 -2.78)))
(setq changed-pan-coords (make-coords :pos #f(914.651 -46.265 888.52) :rpy #f(-0.753 -1.496 -2.256)))

;; 変換を計算
(setq trans-coords (send orig-pan-coords :transformation changed-pan-coords :world))

(setq rec-0-orig (send (elt *cook-short-rec-list* 0) :copy-worldcoords))

;; ;;ここで実装パターン
;; (setq rec-0-changed (make-cascoords))
;; (send rec-0-changed :newcoords (send rec-0-orig :copy-worldcoords))
;; (setq tmp-rec-list (assoc-rec-list *cook-short-rec-list* rec-0-changed))
;; (send rec-0-changed :transform trans-coords :world)

;; pr2_cook_utils.lの関数を利用
(setq tmp-rec-list (trans-rec-list *cook-short-rec-list* trans-coords))
(setq rec-0-changed (send (elt tmp-rec-list 0) :copy-worldcoords))

(setq arrow1 (arrow))
(send arrow1 :newcoords (send orig-pan-coords :copy-worldcoords))
(setq arrow2 (arrow))
(send arrow2 :newcoords (send changed-pan-coords :copy-worldcoords))

(objects arrow1)
(objects arrow2)

(defun show-cds-rec ()
  (send rec-0-orig :draw-on :flush t)
  (send rec-0-changed :draw-on :flush t)
  )

;; (view-rec-list *cook-short-rec-list*)
;; (view-rec-list tmp-rec-list)
