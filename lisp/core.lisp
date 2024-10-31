(in-package :uem)

(defvar *uem-sys* nil
  "All defined system goes here")

(defvar *uem-module-root* nil
  "The root directory of load module")

(defmacro feat! (fname fdescription fscopes fentry)
  (format t "feat! name: ~a scopes: ~a description: ~a entry: ~a~%"
          fname fscopes fdescription fentry)
  `(progn
     (defclass ,fname (UEMFeature)
       ())

     (defmethod parse-config ((f ,fname))
                (with-slots (name description scopes entry) f
                  (setf name (symbol-name ',fname))
                  (setf description ,fdescription)
                  (setf scopes ',fscopes)
                  (setf entry #',fentry)))))

(defun normalize-key-args (acc1 acc2 k args)
  (if args
      (let ((it1 (car args)))
	(if k
	    (if (keywordp it1)
		(progn
		  (setf (getf acc1 k) `',acc2)
		  (normalize-key-args acc1 nil it1 (cdr args)))
	      (normalize-key-args acc1 (append acc2 (list it1)) k (cdr args)))
	  (if (keywordp it1)
	      (normalize-key-args acc1 nil it1 (cdr args))
	    (normalize-key-args acc1 nil nil (cdr args)))))
    (progn
      (when (keywordp k)
	(setf (getf acc1 k) `',acc2))
      acc1)))

(defmacro sys! (name &rest args)
  (let* ((xargs (normalize-key-args nil nil nil args)))
    (format t "sys! args: ~a~%" xargs)
    `(let ((sn (cond
                 ((eql ',name 'emacs) 'UEMEmacs)
                 ((eql ',name 'fish) 'UEMFish)
                 (t 'UEMUnknown))))
         (setf *uem-sys* (make-instance sn
                                        ,@xargs)))))

(defun feat-get (name owner data)
  (handler-case
      (progn
        (format t "feat-get ~a owner ~a~%"
                name owner)
        (make-instance name
                       :name (symbol-name name)
                       :owner owner
		       :data data))
    (SB-PCL:CLASS-NOT-FOUND-ERROR () nil)))

