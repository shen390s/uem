(in-package :uem)


;; uem-system
;; emacs
;;   sections:
;;     init, core, modes,ui, app, completion, editor
;; shell
;;   sections:
;;     init, ...

(defclass UEMSystem ()
  ((sysname :initarg :sysname
            :initform "Unknown")
   (init :initarg :init
         :initform nil)))

(defgeneric gencode (s name)
            (:documentation "Generate the code of UEM system"))

(defgeneric load-modules (s path)
            (:documentation "Load modules from path"))

(defclass UEMUnknown (UEMSystem)
  ())

(defclass UEMEmacs (UEMSystem)
  ((app :initarg :app
        :initform nil)
   (core :initarg :core
         :initform nil)
   (ui :initarg :ui
       :initform nil)
   (modes :initarg :modes
          :initform nil)
   (complete :initarg :complete
             :initform nil)))

(defmethod gencode ((s UEMEmacs) name)
           (format t "Generate code for ~a(UEMEmacs) ~A" name s))

(defmethod load-modules ((s UEMEmacs) path)
           (format t "Loading modules from ~a...~%" path))

(defclass UEMShell (UEMSystem)
  ())

(defclass UEMFish (UEMShell)
  ())

(defmacro uemsys (name &rest args)
  (let ((xargs (quote-keyword-args args)))
    `(cond
      ((eql ',name 'emacs) (make-instance 'UEMEmacs ,@xargs))
      ((eql ',name 'fish) (make-instance 'UEMFish ,@xargs))
      (t (make-instance 'UEMUnknown ,@xargs)))))
