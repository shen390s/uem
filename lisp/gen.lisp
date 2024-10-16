(in-package :uem)

(defun gen (module-path verbose output)
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
                     (with-open-file (out (ensure-directories-exist output) :direction :output
                                                                            :if-exists :overwrite
                                                                            :if-does-not-exist :create)
                       (gencode v out k))))
               *uem-sys*))))
