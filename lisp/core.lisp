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

(defclass UEMUnknown (UEMSystem)
  ())

(defclass UEMEmacs (UEMSystem)
  ((app :initarg :app
        :initform nil)))

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
