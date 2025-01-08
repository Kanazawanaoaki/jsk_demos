;; ヘルパー関数: range の代わり
(defun range (n)
  "Generate a list of integers from 0 to n-1 using list and append."
  (let ((result '()))
    (dotimes (i n)
      (setq result (append result (list i))))
    result))

(defun calculate-mean-point (points dims)
  "Calculate the mean point for the given points."
  (mapcar
   #'(lambda (i)
       (/ (reduce #'+ (mapcar #'(lambda (p) (elt p i)) points))
          (length points)))
   (range dims)))

(defun detect-outliers-simple (points threshold)
  "Detect outliers in a list of points based on distance from the mean point."
  (let* ((dims (length (car points)))
         (mean-point (calculate-mean-point points dims))
         (outliers (remove-if-not
                    #'(lambda (p)
                        (> (sqrt (reduce #'+ (mapcar #'(lambda (i)
                                                         (expt (- (elt p i) (elt mean-point i)) 2))
                                                   (range dims))))
                           threshold))
                    points)))
    outliers))

;; サンプルの座標データ
(setq sample-points '((1 2 3) (2 3 4) (10 10 10) (2 2 2) (3 3 3)))

;; 外れ値を検出（閾値を設定）
(setq outliers (detect-outliers-simple sample-points 5.0))

(format t "Outliers: ~a~%" outliers)

