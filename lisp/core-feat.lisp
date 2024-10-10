(in-package :uem)

(defgeneric gencode-action (f section action)
  (:documentation "Generate code for action"))
(defclass UEMFeature ()
  ((feature-name :initarg :name
                 :initform "unknown")
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

(defmethod gencode-action ((f UEMFeature) section action)
  (format t "Generate action ~a code for feature ~%" action)
  (with-slots (init activate deactivate) f
    (cond
      ((eql section :init) init)
      (t (cond
           ((eql action :activate) activate)
           ((eql action :deactivate) deactivate)
           ( t ""))))))
