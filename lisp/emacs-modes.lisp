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
                 (otherwise t)))

(defmethod gencode :after ((s EmacsGenericMode) output action)
           (case action
                 ((:CALL)
                  (progn
                    (format output "t)~%")
                    (format output "(add-hook '~a #'~a)~%"
                            (mode-hook-name s)
                            (mode-entry s))))
                 (otherwise t)))

;; (defmethod gencode ((s EmacsGenericMode) output action)
;;            (with-slots (features) s
;;              (case action
;;                    ((:CALL)
;;                     (progn
;;                       (format output ";;; mode features: ~a~%" features)
;;                       (loop for f in features
;;                             do (let ((fn (car f))
;;                                      (act (cadr f))
;;                                      (args (cddr f)))
;;                                  (call-feature-by-name fn output act args)))))
;;                    (otherwise t))))


(defun make-emacs-mode (name sys data)
  (handler-case
      (progn
        (make-instance (intern (format nil "EmacsMode/~a" name))
                       :name name
                       :sys sys
                       :data data))
    (SB-PCL:CLASS-NOT-FOUND-ERROR ()
                                  (make-instance 'EmacsGenericMode
                                                 :name name
                                                 :sys sys
                                                 :data data))))
