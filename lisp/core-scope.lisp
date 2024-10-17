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

(defclass UEMDataScope (UEMScope)
  ((data :initarg :data
         :initform nil)))

(defmethod gencode ((s UEMDataScope) output action)
           (format t "Generate init code action ~a~%" action)
  (case action
    ((:INIT)
     (with-slots (data) s
       (print data output)
       (format output "~%")))
    (otherwise t)))

(defclass UEMFeatureScope (UEMDataScope)
  ((features :initarg :features
             :initform nil)))

(defmethod initialize-instance :after ((s UEMFeatureScope) &key)
  (with-slots (data features) s
    (setf features (normalize-feature-list data))
    (format t "features in scope ~a: ~a~%"
            (name s) features)))

(defmethod gencode ((s UEMFeatureScope) output action)
  (with-slots (features) s
    (format t "gencode features ~a~%" features)
    (loop for f in features
          do (let* ((nf (car f))
                    (sf (getf f nf)))
               (format t "nf ~a sf ~a ~%" nf sf)
               (let ((feat (feat-get nf)))
                 (when feat
                   (let ((ctx (list s)))
                     (let ((c (invoke-feature feat action ctx f)))
                       (when c
                         (format output "~a~%" c))))))))))

(defclass UEMCompoundScope (UEMDataScope)
  ((scopes :initarg :scopes
           :initform nil)))

(defmethod add-scope ((cs UEMCompoundScope) (s UEMScope))
           (with-slots (scopes) cs
             (setf scopes (append scopes (list s)))))

(defmethod scopes ((s UEMCompoundScope))
           (with-slots (scopes) s
             scopes))
