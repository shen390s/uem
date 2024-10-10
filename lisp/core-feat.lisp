(in-package :uem)

(defgeneric gencode-action (f action ctx)
  (:documentation "Generate code for action"))
(defclass UEMFeature ()
  ((feature-name :initarg :name
                 :initform "unknown")
   (sections :initarg :sections
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

(defmethod gencode-action ((f UEMFeature) action ctx)
  (format t "Generate action ~a code for feature ~%" action)
  (with-slots (init activate deactivate sections) f
    (let ((section (car ctx)))
      (cond
        ((member section '(:init :config))
         (cond
           ((eql section :init) init)
           (t config)))
        ((member section sections)
         (cond
           ((eql section :modes)
            (let ((mode (cadr ctx)))
              (cond
                ((eql action :activate)
                 (with-output-to-string (out)
                   (format out "add-hook ~a-mode-hook ~%(lambda () ~% ~a~%)"
                           mode activate)))
                ((eql action :deactivate)
                 (with-output-to-string (out)
                   (format out "add-hook ~a-mode-hook ~%(lambda () ~% ~a~%)"
                           mode deactivate)))
                (t ""))))
           (t (cond
                ((eql action :activate) activate)
                ((eql action :deactivate) deactivate)
                ( t "")))))
        (t "")))))
