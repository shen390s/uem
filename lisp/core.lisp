(in-package :uem)

(defvar *uem-features* (make-hash-table)
  "All defined features go here")

(defvar *uem-sys* (make-hash-table)
  "All defined system goes here")

(defmacro feat! (name &rest args)
  (let* ((keywords (remove-if-not #'keywordp args))
         (xargs (apply #'append
                       (loop for k in keywords
                             collect `(,k (getf ',args ,k))))))
    `(let ((feature (make-instance 'UEMFeature
                                   :name ',name
                                   ,@xargs)))
       (setf (gethash ',name *uem-features*) feature))))

(defmacro sys! (name &rest args)
  (let* ((keywords (remove-if-not #'keywordp args))
         (xargs (apply #'append
                       (loop for k in keywords
                             collect `(,k (getf ',args ,k))))))
    (format t "sys! args: ~a~%" args)
    `(let ((sn (cond
                 ((eql ',name 'emacs) 'UEMEmacs)
                 ((eql ',name 'fish) 'UEMFish)
                 (t 'UEMUnknown))))
         (let ((s (make-instance sn
                                 ,@xargs)))
           (setf (gethash ',name *uem-sys*) s)))))

(defun feat-get (name)
  (gethash name *uem-features*))
