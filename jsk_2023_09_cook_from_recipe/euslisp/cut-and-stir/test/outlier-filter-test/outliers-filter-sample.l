;; ヘルパー関数: range の代わり
(defun range (n)
  "Generate a list of integers from 0 to n-1 using list and append."
  (let ((result '()))
    (dotimes (i n)
      (setq result (append result (list i))))
    result))

;; 平均座標を計算する関数
(defun calculate-mean-pos (points)
  "Calculate the mean coordinates for a list of points."
  (let* ((dims (length (send (car points) :pos)))
         (mean-pos (make-list dims :initial-element 0.0)))
    ;; 各次元ごとに平均を計算
    (dotimes (i dims)
      (setf (nth i mean-pos)
            (/ (reduce #'+ (mapcar #'(lambda (p) (elt (send p :pos) i)) points))
               (length points))))
    (make-coords :pos (apply #'vector mean-pos)))) ;; 平均座標を返す

;; 外れ値検出と除外
(defun exclude-outliers-coords (points threshold)
  "Print outliers and return a list of points without outliers."
  (let ((mean-point (calculate-mean-pos points))
        (dims (length (send (car points) :pos)))
        (outliers '())
        (filtered-points '()))
    ;; 各座標を処理
    (dolist (p points)
      (let ((distance
             (sqrt (reduce #'+ (mapcar #'(lambda (i)
                                           (expt (- (elt (send p :pos) i)
                                                    (elt (send mean-point :pos) i)) 2))
                                      (range dims))))))
        (if (> distance threshold)
            ;; 外れ値に追加
            (setq outliers (append outliers (list p)))
          ;; 外れ値でなければフィルタ済みリストに追加
          (setq filtered-points (append filtered-points (list p))))))
    (format t "mean-point: ~a~%" mean-point)
    ;; 外れ値を出力
    (format t "Outliers: ~a~%" (mapcar #'(lambda (p) (send p :pos)) outliers))
    ;; 外れ値を除いたリストを返す
    filtered-points))

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
