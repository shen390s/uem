(in-package :uem)

(defgeneric gencode-action (f action ctx)
            (:documentation "Generate code for action"))
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

(defmethod gencode-action ((f UEMFeature) action ctx)
           (format t "Generate action ~a code for feature ~%" action)
           (with-slots (init activate deactivate scopes) f
             (let ((scope (car ctx)))
               (cond
                ((member scope '(:init :config))
                 (cond
                  ((eql scope :init) (get-value init))
                  (t (get-value config))))
                ((member scope scopes)
                 (cond
                  ((eql scope :modes)
                   (let ((mode (cadr ctx)))
                     (cond
                      ((eql action :activate)
                       (with-output-to-string (out)
                                              (format out "add-hook ~a-mode-hook ~%(lambda () ~% ~a~%)"
                                                      mode (get-value activate))))
                      ((eql action :deactivate)
                       (with-output-to-string (out)
                                              (format out "add-hook ~a-mode-hook ~%(lambda () ~% ~a~%)"
                                                      mode (get-value deactivate))))
                      (t ""))))
                  (t (cond
                      ((eql action :activate) (get-value activate))
                      ((eql action :deactivate) (get-value deactivate))
                      ( t "")))))
                (t "")))))

