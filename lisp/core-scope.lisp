(in-package :uem)

(defgeneric gencode (s output action)
            (:documentation "Generate code for scope"))

(defclass UEMScope (UEMObject)
  ())

(defmethod gencode((s UEMScope) output action)
           (format output ""))

(defgeneric add-scope (cs s)
            (:documentation "add scope to compound scope"))

(defclass UEMDataScope (UEMScope)
  ((data :initarg :data
         :initform nil)))

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
                        (let ((feat (feat-get nf s)))
                          (format t "get feature = ~a~%" feat)
                          (if feat
                              (let ((c (gencode-action feat action f)))
                                (when (and c (stringp c))
                                  (format output "~a~%" c)))
			      (format output ";;; feature ~a can not be found~%" nf)))))))

(defclass UEMCompoundScope (UEMDataScope)
  ((scopes :initarg :scopes
           :initform nil)))

(defmethod add-scope ((cs UEMCompoundScope) (s UEMScope))
           (with-slots (scopes) cs
             (setf scopes (append scopes (list s)))))

(defmethod scopes ((s UEMCompoundScope))
           (with-slots (scopes) s
             scopes))
