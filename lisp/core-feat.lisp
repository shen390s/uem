(in-package :uem)

(defgeneric gencode-action (f action ctx args)
  (:documentation "Generate code for action"))

(defgeneric name (f)
  (:documentation "name of feature"))

(defclass UEMFeature (UEMObject)
  ((description :initarg :description
                :initform nil)
   (scopes :initarg :scopes
           :initform nil)
   (entry :initarg :entry
          :initform nil)))

(defmethod gencode-action ((f UEMFeature) action ctx args)
  (format t "Generate action ~a code for feature ctx ~a args ~a~%"
          action ctx args)
  (with-slots (entry) f
    (let ((scope (car ctx)))
      (format t "scope is ~a~%" scope)
      (let ((*readtable* (copy-readtable nil)))
        (setf (readtable-case *readtable*) :preserve)
        (get-value entry f action args)))))

(defun make-feature (name owner data)
  (make-instance (intern name)
                 :name name
                 :owner owner
                 :data data))
