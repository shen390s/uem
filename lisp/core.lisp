(in-package :uem)

(defvar *uem-features* (make-hash-table)
  "All defined features go here")

(defvar *uem-sys* (make-hash-table)
  "All defined system goes here")

(defmacro feat! (name description scopes entry)
  (format t "feat! name ~a scopes ~a entry ~a ~%"
          name scopes entry)
  `(let ((feature (make-instance 'UEMFeature
                                 :name ',name
                                 :description ,description
                                 :scopes ',scopes
                                 :entry #',entry)))
       (setf (gethash ',name *uem-features*) feature)))

(defmacro sys! (name &rest args)
  (let* ((xargs (mapcar #'(lambda (x)
                            (if (keywordp x)
                                x
                              `(funcall #',x)))
                        args)))
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

(defun call-feature-by-name (name output action args)
  (let ((f (feat-get name)))
    (if f
        (gencode f output action args)
      (format t "feature: can not be found~%"))))
