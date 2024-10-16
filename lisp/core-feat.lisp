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
            (cond
             ((eql action 'init) (gencode-action f 'init ctx args))
             ((eql action 'config) (gencode-action f 'config ctx args))
             ((eql action 'call)
              (if (= (getf args (name f)) 1)
                  (gencode-action f 'activate ctx args)
                  (gencode-action f 'deactivate ctx args)))
             (t t)))

(defmethod gencode-action ((f UEMFeature) action ctx args)
           (format t "Generate action ~a code for feature ~%" action)
           (with-slots (init activate deactivate scopes) f
             (let ((scope (car ctx)))
               (format t "scope is ~a~%" scope)
               (cond
                 ((member action '(init config))
                  (if (eql action 'init)
                      (get-value init args)
                      (get-value config args)))
                 ((eql action 'activate)
                  (get-value activate args))
                 (t (get-value deactivate args))))))



