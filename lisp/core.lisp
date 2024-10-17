(in-package :uem)

(defvar *uem-features* (make-hash-table)
  "All defined features go here")

(defvar *uem-sys* (make-hash-table)
  "All defined system goes here")

(defun normalize-args (args)
  (mapcar #'(lambda (x)
              (if (consp x)
                  `',x
                  x))
          args))

(defmacro feat! (name &rest args)
  (let* ((xargs (normalize-args args)))
    `(let ((feature (make-instance 'UEMFeature
                                   :name ',name
                                   ,@xargs)))
       (setf (gethash ',name *uem-features*) feature))))

(defmacro sys! (name &rest args)
  (let* ((xargs (normalize-args args)))
    (format t "sys! args: ~a~%" xargs)
    `(let ((sn (cond
                 ((eql ',name 'emacs) 'UEMEmacs)
                 ((eql ',name 'fish) 'UEMFish)
                 (t 'UEMUnknown))))
         (let ((s (make-instance sn
                                 ,@xargs)))
           (setf (gethash ',name *uem-sys*) s)))))

(defun feat-get (name)
  (gethash name *uem-features*))
