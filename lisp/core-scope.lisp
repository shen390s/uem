(in-package :uem)

(defgeneric gencode (s output action)
            (:documentation "Generate code for scope"))

(defgeneric name (s)
            (:documentation "Get name of scope"))

(defgeneric sys (s)
  (:documentation "Get sys of scope"))

(defclass UEMScope ()
  ((scope-name :initarg :name
               :initform "unknown")
   (system :initarg :sys
           :initform nil)))

(defmethod name ((s UEMScope))
           (with-slots (scope-name) s
             scope-name))

(defmethod gencode((s UEMScope) output action)
           (format output ""))

(defgeneric add-scope (cs s)
            (:documentation "add scope to compound scope"))

(defmethod sys ((s UEMScope))
  (with-slots (system) s
    system))

(defclass UEMCompoundScope (UEMScope)
  ((scopes :initarg :scopes
           :initform nil)))

(defmethod add-scope ((cs UEMCompoundScope) (s UEMScope))
           (with-slots (scopes) cs
             (setf scopes (append scopes (list s)))))

(defmethod scopes ((s UEMCompoundScope))
           (with-slots (scopes) s
             scopes))
