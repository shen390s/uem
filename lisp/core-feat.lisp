(in-package :uem)

(defgeneric gencode-action (f action ctx args)
  (:documentation "Generate code for action"))

(defgeneric name (f)
  (:documentation "name of feature"))

(defclass UEMFeature ()
  ((feature-name :initarg :name
                 :initform "unknown")
   (description :initarg :description
                :initform nil)
   (scopes :initarg :scopes
           :initform nil)
   (entry :initarg :entry
          :initform nil)))

(defmethod name ((f UEMFeature))
  (with-slots (feature-name) f
    feature-name))

(defmethod gencode-action ((f UEMFeature) action ctx args)
  (format t "Generate action ~a code for feature ctx ~a args ~a~%"
          action ctx args)
  (with-slots (entry) f
    (let ((scope (car ctx)))
      (format t "scope is ~a~%" scope)
      (let ((*readtable* (copy-readtable nil)))
        (setf (readtable-case *readtable*) :preserve)
        (get-value entry action args)))))
