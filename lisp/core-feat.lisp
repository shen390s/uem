(in-package :uem)

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

(defmethod gencode-section ((f UEMFeature) section)
  (format t "Generate section ~a code for feature ~%" section)
  (with-slots (init activate deactivate) f
    (cond
      ((eql section 'INIT) init)
      ((eql section 'ACTIVATE) activate)
      ((eql section 'DEACTIVATE) deactivate)
      (t activate))))
