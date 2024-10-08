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
