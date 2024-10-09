(in-package :uem)

;; uem-system
;; emacs
;;   sections:
;;     init, core, modes,ui, app, completion, editor
;; shell
;;   sections:
;;     init, ...

(defgeneric gencode (s name)
  (:documentation "Generate the code of UEM system"))

(defgeneric load-modules (s path)
  (:documentation "Load modules from path"))

(defgeneric do-load (s path)
  (:documentation "Load module file"))

(defgeneric sections (s)
  (:documentation "Section of generated code"))

(defgeneric gencode-section (s section)
  (:documentation "Generate section code for system"))

(defclass UEMSystem ()
  ((sysname :initarg :sysname
            :initform "Unknown")
   (init :initarg :init
         :initform nil)))

(defmethod load-modules ((s UEMSystem) dir)
  (cl-fad::walk-directory dir
                          #'(lambda (filename)
                              (do-load s filename))))

(defmethod sections ((s UEMSystem))
  nil)

(defmethod gencode-section ((s UEMSystem) section)
  (format t "Generate code for section ~a~%" section))

(defmethod gencode ((s UEMSystem) name)
  (loop for section in (sections s)
        do (gencode-section s section)))

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

(defmethod sections ((s UEMEmacs))
  '(:init :core :ui :modes :complete :app))

(defmethod gencode-section ((s UEMEmacs) section)
  (format t "Generate code for ~a system ~a~%" section s)
  (progn
    (maphash #'(lambda (k v)
                 (format t ";;; ~a for feature ~a~%" section k)
                 (let ((c (gencode-section v section)))
                   (when c
                     (format t "~a~%" c))))
             *uem-features*)))

(defclass UEMShell (UEMSystem)
  ())

(defclass UEMFish (UEMShell)
  ())
