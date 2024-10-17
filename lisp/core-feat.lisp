(in-package :uem)

(defgeneric gencode-action (f action ctx args)
  (:documentation "Generate code for action"))

(defgeneric invoke-feature (f action ctx args)
  (:documentation "invoke feature functions"))

(defgeneric name (f)
  (:documentation "name of feature"))

(defclass UEMFeature ()
  ((feature-name :initarg :name
                 :initform "unknown")
   (scopes :initarg :scopes
           :initform nil)
   (depends :initarg :deps
            :initform nil)
   (init :initarg :init
         :initform nil)
   (config :initarg :config
           :initform nil)
   (activate :initarg :activate
             :initform nil)
   (detactive :initarg :deactivate
              :initform nil)))

(defmethod name ((f UEMFeature))
  (with-slots (feature-name) f
    feature-name))

(defmethod invoke-feature ((f UEMFeature) action ctx args)
  (format t "invoking feature ~a action ~a args ~a ~%"
          (name f) action args)
  (case action
    ((:INIT :CONFIG)
     (gencode-action f action ctx args))
    ((:CALL)
     (if (= (getf args (name f)) 1)
         (gencode-action f :activate ctx args)
         (gencode-action f :deactivate ctx args)))
    (otherwise "")))

(defmethod gencode-action ((f UEMFeature) action ctx args)
  (format t "Generate action ~a code for feature ctx ~a args ~a~%"
          action ctx args)
  (with-slots (init activate deactivate config) f
    (let ((scope (car ctx)))
      (format t "scope is ~a~%" scope)
      (case action
        ((:INIT) (get-value init args))
        ((:CONFIG) (get-value config args))
        ((:ACTIVATE) (get-value activate args))
        ((:DEACTIVATE) (get-value deactivate args))
        (otherwise "")))))
