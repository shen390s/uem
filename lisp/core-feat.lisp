(in-package :uem)

(defgeneric gencode-action (f action args)
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

(defmethod gencode-action ((f UEMFeature) action args)
  (format t "Generate action ~a code for feature args ~a~%"
          action args)
  (with-slots (entry) f
    (let ((o (owner f)))
      (format t "owner is ~a~%" o)
      (let ((*readtable* (copy-readtable nil)))
        (setf (readtable-case *readtable*) :preserve)
        (get-value entry f action args)))))

(defun make-feature (name owner data)
  (make-instance (intern name)
                 :name name
                 :owner owner
                 :data data))
