(in-package :uem)

(defgeneric gencode-action (f output action args)
	    (:documentation "Generate code for action"))

(defgeneric name (f)
	    (:documentation "name of feature"))

(defclass UEMFeature (UEMObject)
  ((description :initarg :description
                :initform nil)
   (scopes :initarg :scopes
           :initform nil)
   (entry :initarg :entry
          :initform nil)
   (data :initarg :data
	 :initform nil)))

(defmethod gencode-action ((f UEMFeature) output action args)
	   (format t "Generate action ~a code for feature ~a args ~a~%"
		   action  (name f) args )
	   (with-slots (entry) f
	     (let ((o (owner f)))
	       (format t "owner is ~a entry ~a~%"
		       o entry)
	       (when entry
		 (let ((*readtable* (copy-readtable nil)))
		   (setf (readtable-case *readtable*) :preserve)
		   (let ((code (get-value entry f action args)))
		     (when (and code
				(stringp code))
		       (format  output "~a~%" code))))))))

(defun make-feature (name owner data)
  (make-instance (intern name)
                 :name name
                 :owner owner
                 :data data))
