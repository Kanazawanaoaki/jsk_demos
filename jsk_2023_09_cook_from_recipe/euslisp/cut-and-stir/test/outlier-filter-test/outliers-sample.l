;; ヘルパー関数: range の代わり
(defun range (n)
  "Generate a list of integers from 0 to n-1 using list and append."
  (let ((result '()))
    (dotimes (i n)
      (setq result (append result (list i))))
    result))

;; 平均座標を計算する関数
(defun calculate-mean-coords (points)
  "Calculate the mean coordinates for a list of points."
  (let* ((dims (length (send (car points) :pos)))
         (mean-pos (make-list dims :initial-element 0.0)))
    ;; 各次元ごとに平均を計算
    (dotimes (i dims)
      (setf (nth i mean-pos)
            (/ (reduce #'+ (mapcar #'(lambda (p) (elt (send p :pos) i)) points))
               (length points))))
    (make-coords :pos (apply #'vector mean-pos)))) ;; 平均座標を返す

;; 外れ値検出
(defun detect-outliers-coords (points threshold)
  "Detect outliers in a list of coordinates based on distance from the mean."
  (let* ((mean-point (calculate-mean-coords points))
         (dims (length (send mean-point :pos)))
         (outliers (remove-if-not
                    #'(lambda (p)
                        (> (sqrt (reduce #'+ (mapcar #'(lambda (i)
                                                         (expt (- (elt (send p :pos) i)
                                                                  (elt (send mean-point :pos) i))
                                                               2))
                                                   (range dims))))
                           threshold))
                    points)))
    outliers))


;; サンプル座標データ
(setq sample-points (list (make-coords :pos #f(1 2 3))
                          (make-coords :pos #f(2 3 4))
                          (make-coords :pos #f(10 10 10))
                          (make-coords :pos #f(2 2 2))
                          (make-coords :pos #f(3 3 3))))

;; 外れ値を検出（閾値を設定）
(setq outliers (detect-outliers-coords sample-points 5.0))

;; 結果表示
(format t "Outliers: ~a~%" (mapcar #'(lambda (p) (send p :pos)) outliers))
