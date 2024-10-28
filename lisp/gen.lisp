(in-package :uem)

(defmethod do-load (filename)
  (let ((ftype (pathname-type filename)))
    (if (string= ftype "lisp")
        (progn
          (format t "Loading file ~a...~%" filename)
          (in-package :uem)
          (progn
            (load filename)))
        (format t "Ignore file ~a~%" filename))))

(defmethod load-modules (dir)
  (cl-fad::walk-directory dir
                          #'(lambda (filename)
                              (do-load filename))))

(defun gen (module-path verbose output)
  (format t "Generating configuration...~%")
  (format t "load system from ~A~%" module-path)
  (format t "Verbose: ~A~%" verbose)
  (in-package :uem)
  (let ((*readtable* (copy-readtable nil)))
    (set-dispatch-macro-character #\# #\/ #'read-doc-here)
    (format t "macro dispatch: ~a~%"
            (get-dispatch-macro-character #\# #\/))
    (setf module-path (uiop/filesystem:truename* module-path))
    (setf *uem-module-root*
          (make-pathname :name nil
                         :type nil
                         :defaults module-path))
    (let ((pkg-path (make-pathname :name "packages"
                                   :type nil
                                   :defaults module-path)))
      (progn
        (format t "Loading packages from ~a...~%" pkg-path)
	(load-modules pkg-path)
	(load module-path :verbose t :print t)
        (let ((v *uem-sys*))
          (with-open-file (out (ensure-directories-exist output) :direction :output
								 :if-exists :supersede
								 :if-does-not-exist :create)
	    (gencode v out (name v))))))))
