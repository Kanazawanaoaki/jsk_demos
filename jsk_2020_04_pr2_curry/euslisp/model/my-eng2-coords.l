;; my spot
(setq *kitchen-spot* (make-coords :pos (float-vector 1200 8500 30000) :rpy (float-vector pi 0 0)))
(setq *sink-spot* (make-coords :pos (float-vector 1100 9100 30000) :rpy (float-vector pi 0 0)))
(setq *stove-spot* (make-coords :pos (float-vector 1400 8100 30000) :rpy (float-vector pi 0 0)))
(setq *microwave-spot* (make-coords :pos (float-vector 1600 9300 30000) :rpy (float-vector 0 0 0)))
(setq *seasoning-spot* (make-coords :pos (float-vector 1700 8900 30000) :rpy (float-vector 0 0 0)))

;; tools coords
(setq *knife-coords* (make-coords :pos (float-vector 580 8715 30857) :rpy (float-vector 3.14 0.073 1.498))) ;; 包丁
(setq *peeler-coords* (make-coords :pos (float-vector 580 8815 30870) :rpy (float-vector 3.14 0.049 1.51))) ;; ピーラー
(setq *potato-peeler-coords* (make-coords :pos (float-vector 580 8915 30865) :rpy (float-vector 3.14 0.013 1.545))) ;; じゃがいもピーラー
(setq *spatula-coords-0* (make-coords :pos (float-vector 340 8739 31433) :rpy (float-vector -3.14 -0.008 1.529))) ;; ヘラ，棚の中
(setq *spatula-coords-1* (make-coords :pos (float-vector 592 8549 30872) :rpy (float-vector 3.084 -0.042 1.542))) ;; ヘラ，平置き
(setq *ladle-coords-0* (make-coords :pos (float-vector 346 8637 31449) :rpy (float-vector -3.14 -0.008 1.529))) ;; おたま，棚の中
(setq *ladle-coords-1* (make-coords :pos (float-vector 599 8313 30877) :rpy (float-vector 3.128 -0.098 1.514))) ;; おたま，平置き


;; kitchenware coords
;; (setq *pot-coords* (make-coords :pos (float-vector 450 8100 30840) :rpy (float-vector 3.142 0 0)))
(setq *pot-coords* (make-coords :pos (float-vector 450 8050 30840) :rpy (float-vector 3.142 0 0)))

(setq *mcup-coords* (make-coords :pos (float-vector 555 7674 30850) :rpy (float-vector -0.948 0 0)))
;; (setq *cutting-board-coords* (make-coords :pos (float-vector 530 8420 30840) :rpy (float-vector 0 0 0)))
(setq *cutting-board-coords* (make-coords :pos (float-vector 560 8420 30840) :rpy (float-vector 0 0 0)))
(setq *bowl-1-coords* (make-coords :pos (float-vector 325 8460 30840) :rpy (float-vector -0.175 0 0)))
(setq *bowl-2-coords* (make-coords :pos (float-vector 295 8645 30840) :rpy (float-vector -0.349 0 0)))
(setq *bowl-2-set-coords* (make-coords :pos (float-vector 510 8430 30840) :rpy (float-vector 0 0 0)))
(setq *bowl-3-coords* (make-coords :pos (float-vector 635 7585 30840) :rpy (float-vector 1.048 0 0)))
(setq *bowl-4-coords* (make-coords :pos (float-vector 480 7845 30840) :rpy (float-vector -0.175 0 0)))
(setq *rcup-coords* (make-coords :pos (float-vector 320 8525 30840)))

(setq *solt-coords* (make-coords :pos (float-vector 2150 8800 30900) :rpy (float-vector 0 0 0)))
(setq *dispenser-coords* (make-coords :pos (float-vector 2150 8950 30900) :rpy (float-vector 0 0 0)))
(setq *oil-dispenser-coords* (make-coords :pos (float-vector 300 8280 30845) :rpy (float-vector 3.14 0.0 0.0)))


;; equipment coords
;; 棚
(setq *shelf-knob-closed-coords* (make-coords :pos (float-vector 425 8573 31445) :rpy (float-vector 3.105 0.012 3.092)))
(setq *shelf-knob-opened-coords* (make-coords :pos (float-vector 629 8859 31445) :rpy (float-vector -1.636 -0.095 -3.091)))

;; (setq *shelf-door-coords* (make-coords :pos (float-vector 420 8855 31445) :rpy (float-vector 3.14 0 0)))
(setq *shelf-door-coords* (make-coords :pos (float-vector 400 8845 31445) :rpy (float-vector 3.14 0 0)))

;; 水道
(setq *fauset-lever-rarm-coords* (make-coords :pos (float-vector 223 9157 31014) :rpy (float-vector -2.478 0.08 -1.623))) ;; 水道のレバーを掴む座標
(setq *fauset-coords* (make-coords :pos (float-vector 350 9157 30850) :rpy (float-vector 3.14 0 0)))

;; コンロ
(setq *ih-switch-on-coords* (make-coords :pos (float-vector 680 8171 30750) :rpy (float-vector -3.047 -0.011 1.512)))
(setq *ih-switch-off-coords* (make-coords :pos (float-vector 680 8161 30750) :rpy (float-vector -3.047 -0.011 1.512)))
(setq *ih-knob-coords* (make-coords :pos (float-vector 680 8154 30715) :rpy (float-vector -3.047 -0.011 1.512)))
