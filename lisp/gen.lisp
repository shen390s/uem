(in-package :uem)

(defun gen (module-path verbose output)
  (format t "Generating configuration...~%")
  (format t "load system from ~A~%" module-path)
  (format t "Verbose: ~A~%" verbose)
  (in-package :uem)
  (progn ;; let ((*readtable* (copy-readtable nil)))
    (make-dispatch-macro-character #\> nil)
    (set-dispatch-macro-character #\> #\> #'read-doc-here)
    (format t "macro dispatch: ~a~%"
            (get-dispatch-macro-character #\> #\>))
    (load module-path :verbose t :print t)
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
                 *uem-sys*)))))
