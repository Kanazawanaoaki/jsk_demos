#!/usr/bin/env roseus

(require :kanazawa-roseus-utils "package://jsk_2023_09_cook_from_recipe/euslisp/kanazawa-roseus-utils.l")

;; サンプル座標データ
(setq sample-points (list (make-coords :pos #f(1 2 3))
                          (make-coords :pos #f(2 3 4))
                          (make-coords :pos #f(10 10 10))
                          (make-coords :pos #f(2 2 2))
                          (make-coords :pos #f(3 3 3))))

;; 外れ値を除いた座標リスト
(setq filtered-points (exclude-outliers-coords sample-points 5.0))

;; 結果表示
(format t "Filtered Points: ~a~%" (mapcar #'(lambda (p) (send p :pos)) filtered-points))
