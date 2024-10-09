(in-package :uem)

(defun gen (module-path verbose)
  (format t "Generating configuration...~%")
  (format t "load system from ~A~%" module-path)
  (format t "Verbose: ~A~%" verbose)
  (in-package :uem)
  (load module-path)
  (let ((pkg-path (make-pathname :name "packages"
                                 :type nil
                                 :defaults module-path)))
    (progn
      (format t "Loading packages from ~a...~%" pkg-path)
      (maphash #'(lambda (k v)
                   (progn
                     (load-modules v pkg-path)
                     (gencode v k)))
               *uem-sys*))))
