(in-package :uem)

(defvar *uem-sys* nil
  "All defined system goes here")

(defvar *uem-module-root* nil
  "The root directory of load module")

(defmacro feat! (fname fdescription fscopes fentry)
  (format t "feat! name ~a scopes ~a entry ~a~%"
          fname fdescription fscopes fentry)
  `(progn
     (defclass ,fname (UEMFeature)
       ())

     (defmethod initialize-instance :after ((f ,fname) &key)
                (with-slots (name description scopes entry) f
                  (setf name (symbol-name ',fname))
                  (setf description ,fdescription)
                  (setf scopes ',fscopes)
                  (setf entry #',fentry)))))

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
         (setf *uem-sys* (make-instance sn
                                        ,@xargs)))))

(defun feat-get (name owner)
  (handler-case
      (progn
        (format t "feat-get ~a ~a~%"
                name owner)
        (make-instance name
                       :name (symbol-name name)
                       :owner owner))
    (SB-PCL:CLASS-NOT-FOUND-ERROR () nil)))

