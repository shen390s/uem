(in-package :uem)

;; uem-system
;; emacs
;;   scopes:
;;     init, core, modes,ui, app, completion, editor
;; shell
;;   scopes:
;;     init, ...

(defgeneric gencode (s name)
            (:documentation "Generate the code of UEM system"))

(defgeneric load-modules (s path)
            (:documentation "Load modules from path"))

(defgeneric do-load (s path)
            (:documentation "Load module file"))

(defgeneric scopes (s)
            (:documentation "Scope of generated code"))

(defgeneric gencode-scope (s scope)
            (:documentation "Generate scope code for system"))

(defclass UEMSystem ()
  ((sysname :initarg :sysname
            :initform "Unknown")
   (init :initarg :init
         :initform nil)))

(defmethod load-modules ((s UEMSystem) dir)
           (cl-fad::walk-directory dir
                                   #'(lambda (filename)
                                       (do-load s filename))))

(defmethod scopes ((s UEMSystem))
           nil)

(defmethod gencode-scope ((s UEMSystem) scope)
           (format t  "Generate code for scope ~a~%" scope)
           "")

(defmethod gencode ((s UEMSystem) name)
           (with-output-to-string (out)
                                  (loop for scope in (scopes s)
                                        do (format out (gencode-scope s scope)))))

(defmethod do-load ((s UEMSystem) filename)
           (let ((ftype (pathname-type filename)))
             (if (string= ftype "lisp")
                 (progn
                   (format t "Loading file ~a...~%" filename)
                   (in-package :uem)
                   (load filename))
               (format t "Ignore file ~a~%" filename))))

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

(defmethod initialize-instance :after ((s UEMEmacs) &key)
           (with-slots (core ui modes complete app) s
             (setf core (normalize-feature-list core))
             (setf app (normalize-feature-list app))
             (setf ui (normalize-feature-list ui))
             (setf complete (normalize-feature-list complete))
             ;; FIXME: add process of modes here
             (format t "core: ~a~%" core)
             (format t "app: ~a~%" app)))

(defmethod scopes ((s UEMEmacs))
           '(:init :core :ui :modes :complete :app))

(defmethod gencode-scope ((s UEMEmacs) scope)
           (format t "Generate code for ~a system ~a~%" scope s)
           (with-output-to-string (out)
                                  (with-slots (init app core ui modes complete) s
                                    (cond
                                     ((eql scope :init)
                                      (progn
                                        (format out "~a~%" init)
                                        (maphash #'(lambda (k v)
                                                     (format out ";;; ~a for feature ~a~%" scope k)
                                                     (let ((c (gencode-action v :ignore `(,scope))))
                                                       (when c
                                                         (format out "~a~%" c))))
                                                 *uem-features*)))
                                     (t (maphash #'(lambda (k v)
                                                     (format out ";;; ~a for feature ~a~%" scope k)
                                                     (let ((c (gencode-action v :ignore `(,scope))))
                                                       (when c
                                                         (format out "~a~%" c))))
                                                 *uem-features*))))))

(defclass UEMShell (UEMSystem)
  ())

(defclass UEMFish (UEMShell)
  ())
