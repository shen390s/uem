(in-package :uem)

;; uem-system

(defgeneric gencode (s output name)
  (:documentation "Generate the code of UEM system"))

(defgeneric children (o)
  (:documentation "Child of generated code"))

(defgeneric add-child (o child)
  (:documentation "Add child to system"))

(defgeneric child (o n)
  (:documentation "Get child"))

(defgeneric cmp-child (o s1 s2)
  (:documentation "Compare child s1 s2"))

(defgeneric owner (o)
	    (:documentation "Get owner of object"))

(defgeneric name (o)
	    (:documentation "Get name of object"))

(defgeneric parse-config (o)
	    (:documentation "Parse configuration of UEM object"))

(defgeneric data (o)
	    (:documentation "Get config data"))

(defclass UEMObject ()
  ((owner :initarg :owner
	  :initform nil)
   (name :initarg :name
	 :initform "unknown")
   (data :initarg :data
	 :initform nil)))

(defmethod owner ((o UEMObject))
	   (with-slots (owner) o
	     owner))

(defmethod name ((o UEMObject))
	   (with-slots (name) o
	     name))

(defmethod data ((o UEMObject))
	   (with-slots (data) o
	     data))

(defmethod initialize-instance :after ((o UEMObject) &key)
	   (parse-config o))

(defmethod parse-config ((o UEMObject))
	   t)

(defclass UEMContainerObject (UEMObject)
  ((children :initform (make-hash-table))))

(defmethod add-child ((s UEMContainerObject) (child UEMObject))
  (with-slots (children) s
    (setf (gethash (name child) children) child)))

(defmethod children ((s UEMContainerObject))
  (with-slots (children) s
    (loop for n being the hash-keys in children
          collect n)))

(defmethod cmp-child ((s UEMContainerObject) s1 s2)
  t)

(defmethod child ((s UEMContainerObject) n)
  (with-slots (children) s
    (gethash n children)))

(defclass UEMFeatureContainer (UEMContainerObject)
  ())

(defmethod parse-config ((o UEMFeatureContainer))
	   (with-slots (data children) o 
	     (format t "parse-config ~a data: ~a~%"
		     o data)
	     (loop for f in (normalize-feature-list data)
		   do (let* ((nf (car f))
			     (sf (getf f nf))
			     (feat (feat-get nf o f)))
			(if feat
			    (add-child o feat)
			  (format t "feature ~a can not be found~%"
				  nf))))))

(defmethod gencode ((o UEMFeatureContainer) output action)
	   (with-slots (children) o
	     (loop for n being the hash-keys in children
		   do (progn
			(format t "generate code for feature ~a in ~a~%"
				n (name o))
			(gencode (child o n) output action)))))

(defgeneric add-scope (s c)
	    (:documentation "add scope to sys"))

(defclass UEMSystem (UEMContainerObject)
  ((init :initarg :init
         :initform nil)))

(defmethod add-scope ((s UEMSystem) c)
	   (add-child s c))

(defmethod gencode ((s UEMSystem) output name)
  (let ((sorted-children (sort (children s) #'(lambda (s1 s2)
                                            (cmp-child s s1 s2)))))
    (loop for action in '(:init :pre-config :config :post-config :pre-call :call :post-call)
          do (loop for sc in sorted-children 
                   do (let ((c (child  s sc)))
			(format t "sc = ~a~%" sc)
                        (when c
			  (format t "generate code for ~a action ~a~%"
				  (name c) action)
                          (gencode c output action)))))))

(defclass UEMUnknown (UEMSystem)
  ())

