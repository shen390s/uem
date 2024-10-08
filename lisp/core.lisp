(in-package :uem)

(defmacro feat! (name &rest args)
  `(make-instance 'UEMFeature
                  :name ',name
                  ,@args))

(defmacro sys! (name &rest args)
  (let ((xargs (quote-keyword-args args)))
    `(cond
      ((eql ',name 'emacs) (make-instance 'UEMEmacs ,@xargs))
      ((eql ',name 'fish) (make-instance 'UEMFish ,@xargs))
      (t (make-instance 'UEMUnknown ,@xargs)))))
