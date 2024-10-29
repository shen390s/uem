(in-package :uem)

(defgeneric mode-name (s)
	    (:documentation "Get the name of mode"))

(defgeneric mode-hook-name (s)
	    (:documentation "hook name of mode activated"))

(defgeneric mode-activate-fun (s)
	    (:documentation "function name of mode"))

(defgeneric gen-mode-activate (m action args)
	    (:documentation "generate code for mode activate"))

(defclass EmacsMode (UEMFeature)
  ((options :initarg :options
	    :initform nil)))

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

(defun emacs-mode-entry (self action args)
  (format t "call mode entry self ~a(name ~a) action ~a args ~a~%"
	  self (name self) action args)
  (gen-mode-activate self action args))

(defmethod gen-mode-activate ((m EmacsMode) action args)
	   (with-slots (data options) m
	     (unless options 
	       (setf options (normalize-feature-list data)))
	     (format t "gen-mode-activate name ~a data ~a options ~a~%"
		     (name m) data options)
	     (with-output-to-string (output)
				    (loop for f in options
					  do (let* ((nf (car f))
						    (sf (getf f nf)))
					       (let ((feat (feat-get nf m)))
						 (format t "get fure =~a~%" feat)
						 (if feat
						     (progn
						       (gencode-action feat output action f))
						   (format output ";;; feature ~a can not be found~%"
							   nf))))))))

(defclass EmacsGenericMode (EmacsMode)
  ())

(defmethod gencode-action :before ((s EmacsGenericMode) output action args)
	   (case action
	     ((:CALL)
	      (format output "(defun ~a ()~%"
		      (mode-activate-fun s)))
	     (otherwise "")))

(defmethod gencode-action :after ((s EmacsGenericMode) output action args)
	   (case action
	     ((:CALL)
	      (progn
		(format output "t)~%")
		(format output "(add-hook '~a #'~a)~%"
			(mode-hook-name s)
			(mode-activate-fun s))))
	     (otherwise "")))

(defun make-emacs-mode (name owner data)
  (let ((c (read-from-string (symbol-name name))))
    (if (find-class c nil)
	(progn
	  (make-instance c
			 :name name
			 :owner owner
			 :scopes '(:modes)
			 :entry #'emacs-mode-entry
			 :data data))
      (progn
	(format t "mode ~a fallback to generic mode~%"
		name)
	(make-instance 'EmacsGenericMode
		       :name name
		       :owner owner
		       :scopes '(:modes)
		       :entry #'emacs-mode-entry
		       :data data)))))

(defclass EmacsExtMode (EmacsMode)
  ((description :initarg :description
		:initform "none")
   (pkgs :initargs :pkgs
	 :initform nil)
   (suffixes :initargs :suffixes
	     :initform nil)))

(defmethod gencode-action :before ((s EmacsExtMode) output action args)
	   (format t "gencode for ~a~%" (name s))
	   (case action
	     ((:INIT)
	      (with-slots (pkgs suffixes) s 
		(format output "(progn~%")
		(loop for pkg in pkgs
		      do (format output "(pkginstall '~a)~%" pkg))
		(loop for suffix in suffixes
		      do (format output "(add-to-list 'auto-mode-alist '(\"\\\\~a\\\\'\" . ~a-mode))~%"
				 (string-downcase (format nil "~a" suffix))
				 (string-downcase (name s))))
		(format output "t)~%")))
	     (otherwise "")))

(defmacro mode! (name descr pkgs1 suffixes1)
  (format t "create mode for (~a ~a ~a)~%"
	  name pkgs1 suffixes1)
  `(progn
     (defclass ,name (EmacsExtMode)
       ())

     (defmethod initialize-instance :after ((m ,name) &key)
		(with-slots (description pkgs suffixes) m
		  (setf description ,descr)
		  (setf pkgs ',pkgs1)
		  (setf suffixes ',suffixes1)))
     t))
