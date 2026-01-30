(in-package :uem)

(defgeneric name (f)
	    (:documentation "name of feature"))

(defclass UEMFeature (UEMObject)
  ((description :initarg :description
                :initform nil)
   (scopes :initarg :scopes
           :initform nil)
   (entry :initarg :entry
          :initform nil)))

(defmethod gencode ((f UEMFeature) output action)
	   (format t "Generate ~a code for feature ~a ~%"
		   action  (name f))
	   (with-slots (entry) f
	     (let ((o (owner f)))
	       (format t "owner is ~a entry ~a~%"
		       o entry)
	       (when entry
		 (let ((*readtable* (copy-readtable nil)))
		   (setf (readtable-case *readtable*) :preserve)
		   (let ((code (get-value entry f action )))
		     (when (and code
				(stringp code))
		       (format  output "~a~%" code))))))))

(defun make-feature (name owner data)
  (make-instance (intern name)
                 :name name
                 :owner owner
                 :data data))
