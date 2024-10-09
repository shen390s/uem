(in-package :uem)

(defun gen (module-path verbose)
  (format t "Generating configuration...~%")
  (format t "load module from ~A~%" module-path)
  (format t "Verbose: ~A~%" verbose)
  (in-package :uem)
  (load module-path)
  (maphash #'(lambda (k v)
               (progn
                 (load-modules v module-path)
                 (gencode v k)))
           *uem-sys*))
