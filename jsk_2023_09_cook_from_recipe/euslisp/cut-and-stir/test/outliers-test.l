;; ;; ヘルパー関数: range の代わり
;; (defun range (n)
;;   "Generate a list of integers from 0 to n-1 using list and append."
;;   (let ((result '()))
;;     (dotimes (i n)
;;       (setq result (append result (list i))))
;;     result))

;; (defun calculate-mean-point (points dims)
;;   "Calculate the mean point for the given points."
;;   (mapcar
;;    #'(lambda (i)
;;        (/ (reduce #'+ (mapcar #'(lambda (p) (elt p i)) points))
;;           (length points)))
;;    (range dims)))

;; (defun detect-outliers-simple (points threshold)
;;   "Detect outliers in a list of points based on distance from the mean point."
;;   (let* ((dims (length (car points)))
;;          (mean-point (calculate-mean-point points dims))
;;          (outliers (remove-if-not
;;                     #'(lambda (p)
;;                         (> (sqrt (reduce #'+ (mapcar #'(lambda (i)
;;                                                          (expt (- (elt p i) (elt mean-point i)) 2))
;;                                                    (range dims))))
;;                            threshold))
;;                     points)))
;;     outliers))

;; ;; サンプルの座標データ
;; (setq sample-points '((1 2 3) (2 3 4) (10 10 10) (2 2 2) (3 3 3)))

;; ;; 外れ値を検出（閾値を設定）
;; (setq outliers (detect-outliers-simple sample-points 5.0))

;; (format t "Outliers: ~a~%" outliers)


;;; ↑  works




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

;; ;; 外れ値検出
;; (defun detect-outliers-coords (points threshold)
;;   "Detect outliers in a list of coordinates based on distance from the mean."
;;   (let* ((mean-point (calculate-mean-coords points))
;;          (dims (length (send mean-point :pos)))
;;          (outliers (remove-if-not
;;                     #'(lambda (p)
;;                         (> (sqrt (reduce #'+ (mapcar #'(lambda (i)
;;                                                          (expt (- (elt (send p :pos) i)
;;                                                                   (elt (send mean-point :pos) i))
;;                                                                2))
;;                                                    (range dims))))
;;                            threshold))
;;                     points)))
;;     outliers))

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

;; ;; 外れ値を検出（閾値を設定）
;; (setq outliers (detect-outliers-coords sample-points 5.0))

;; ;; 結果表示
;; (format t "Outliers: ~a~%" (mapcar #'(lambda (p) (send p :pos)) outliers))

;; 外れ値を除いた座標リスト
(setq filtered-points (exclude-outliers-coords sample-points 5.0))

;; 結果表示
(format t "Filtered Points: ~a~%" (mapcar #'(lambda (p) (send p :pos)) filtered-points))
