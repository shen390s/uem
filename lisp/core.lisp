(in-package :uem)

(defvar *uem-features* (make-hash-table)
  "All defined features go here")

(defvar *uem-sys* (make-hash-table)
  "All defined system goes here")

(defmacro feat! (name &rest args)
  `(let ((feature (make-instance 'UEMFeature
                                 :name ',name
                                 ,@args)))
     (setf (gethash ',name *uem-features*) feature)))

(defmacro sys! (name &rest args)
  (let ((xargs (quote-keyword-args args)))
    `(let ((s (cond
               ((eql ',name 'emacs) (make-instance 'UEMEmacs ,@xargs))
               ((eql ',name 'fish) (make-instance 'UEMFish ,@xargs))
               (t (make-instance 'UEMUnknown ,@xargs)))))
       (setf (gethash ',name *uem-sys*) s))))
