(in-package :uem)

(defgeneric mode-name (s)
  (:documentation "Get the name of mode"))

(defgeneric mode-hook-name (s)
  (:documentation "hook name of mode activated"))

(defgeneric mode-entry (s)
  (:documentation "function name of mode"))

(defclass EmacsMode (EmacsGenericScope)
  ((modes :initarg :modes
	  :initform nil)))

(defmethod mode-name ((m EmacsMode))
  (string-downcase
   (format nil "~a-mode"
	   (name m))))

(defmethod mode-hook-name ((m EmacsMode))
  (format nil "~a-hook"
	  (mode-name m)))

(defmethod mode-entry ((m EmacsMode))
  (string-downcase
   (format nil "~a-entry"
	   (name m))))

(defclass EmacsGenericMode (EmacsMode)
  ())

(defmethod initialize-instance :after ((m EmacsGenericMode) &key)
  (with-slots (modes) m
    (setf modes `(',(intern (mode-name m))))))

(defmethod gencode :before ((s EmacsGenericMode) output action)
  (case action
    ((:CALL)
     (format output "(defun ~a ()~%"
	     (mode-entry s)))
    (otherwise "")))

(defmethod gencode :after ((s EmacsGenericMode) output action)
  (case action
    ((:CALL)
     (progn
       (format output "t)~%")
       (format output "(add-hook '~a #'~a)~%"
	       (mode-hook-name s)
	       (mode-entry s))))
    (otherwise "")))

(defun make-emacs-mode (name owner data)
  (let ((c (read-from-string (symbol-name name))))
    (if (find-class c nil)
	(progn
	  (make-instance c
			 :name name
			 :owner owner
			 :data data))
	(progn
	  (format t "mode ~a fallback to generic mode~%"
		  name)
	  (make-instance 'EmacsGenericMode
			 :name name
			 :owner owner
			 :data data)))))

(defclass EmacsExtMode (EmacsMode)
  ((description :initarg :description
		:initform "none")
   (pkgs :initargs :pkgs
	 :initform nil)
   (suffixes :initargs :suffixes
	     :initform nil)))

(defmethod gencode :before ((s EmacsExtMode) output action)
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
