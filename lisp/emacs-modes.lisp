(in-package :uem)

(defgeneric mode-name (s)
	    (:documentation "Get the name of mode"))

(defgeneric mode-hook-name (s)
	    (:documentation "hook name of mode activated"))

(defgeneric mode-activate-fun (s)
	    (:documentation "function name of mode"))

(defgeneric gen-mode-activate (m action args)
	    (:documentation "generate code for mode activate"))

(defclass EmacsMode (UEMFeatureContainer)
  ())

(defmethod mode-name ((m EmacsMode))
	   (string-downcase
	    (format nil "~a-mode"
		    (name m))))

(defmethod mode-hook-name ((m EmacsMode))
	   (format nil "~a-hook"
		   (mode-name m)))

(defmethod mode-activate-fun ((m EmacsMode))
	   (string-downcase
	    (format nil "~a-activate"
		    (name m))))

(defmethod parse-config ((m EmacsMode))
	   (with-slots (data) m
	     (format t "parse-config mode ~a data: ~a~%"
		     (name m) data)
	     (call-next-method)))

(defmethod gencode ((m EmacsMode) output action)
	   (call-next-method))

(defclass EmacsGenericMode (EmacsMode)
  ())

(defmethod gencode :before ((s EmacsGenericMode) output action)
	   (case action
	     ((:CALL)
	      (format output "(defun ~a ()~%"
		      (mode-activate-fun s)))
	     (otherwise "")))

(defmethod gencode :after ((s EmacsGenericMode) output action)
	   (case action
	     ((:CALL)
	      (progn
		(format output " t)~%")
		(format output "(add-hook '~a #'~a)~%"
			(mode-hook-name s)
			(mode-activate-fun s))))
	     (otherwise "")))

(defun make-emacs-mode (name owner data)
  (let ((c (read-from-string (symbol-name name))))
    (let ((mode-cls (if (find-class c nil)
			c
		      'EmacsGenericMode)))
      (progn
	(format t "mode ~a using class ~a~%"
		name mode-cls)
	(make-instance mode-cls
		       :name name
		       :owner owner
		       :data data)))))

(defclass EmacsExtMode (EmacsMode)
  ((description :initarg :description
		:initform "none")
   (pkgs :initargs :pkgs
	 :initform nil)))

(defmethod gencode :before ((s EmacsExtMode) output action)
	   (format t "gencode for ~a~%" (name s))
	   (case action
	     ((:INIT)
	      (with-slots (pkgs suffixes) s 
		(format output "(progn~%")
		(loop for pkg in pkgs
		      do (format output "(pkginstall '~a)~%" pkg))
		(format output "t)~%")))
	     (otherwise "")))

(defmacro mode! (name descr pkgs1 )
  (format t "create mode for (~a ~a )~%"
	  name pkgs1 )
  `(progn
     (defclass ,name (EmacsExtMode)
       ())

     (defmethod parse-config ((m ,name) )
		(with-slots (description pkgs ) m
		  (setf description ,descr)
		  (setf pkgs ',pkgs1))
		(call-next-method))
     t))
