(in-package :uem)

;; uem-system

(defgeneric gencode (s output name)
            (:documentation "Generate the code of UEM system"))

(defgeneric load-modules (s path)
            (:documentation "Load modules from path"))

(defgeneric do-load (s path)
            (:documentation "Load module file"))

(defgeneric scopes (s)
            (:documentation "Scope of generated code"))

(defgeneric add-scope (s scope)
            (:documentation "Add scope to system"))

(defgeneric scope (s scope)
            (:documentation "Get scope"))

(defclass UEMSystem ()
  ((sysname :initarg :sysname
            :initform "Unknown")
   (scopes  :initform nil)
   (init :initarg :init
         :initform nil)))

(defmethod initialize-instance :before ((s UEMSystem) &key)
           (with-slots (scopes) s
             (setf scopes (make-hash-table))))

(defmethod add-scope ((s UEMSystem) (scope UEMScope))
           (with-slots (scopes) s
             (setf (gethash (name scope) scopes) scope)))

(defmethod load-modules ((s UEMSystem) dir)
           (cl-fad::walk-directory dir
                                   #'(lambda (filename)
                                       (do-load s filename))))

(defmethod scopes ((s UEMSystem))
           (with-slots (scopes) s
             (loop for n being the hash-keys in scopes
                   collect n)))

(defmethod scope ((s UEMSystem) scope)
           (with-slots (scopes) s
             (gethash scope scopes)))

(defmethod gencode ((s UEMSystem) output name)
           (format t "Generate code for ~a~%" s)
           (loop for sc in (scopes s)
                 do (let ((c (scope  s sc)))
                      (when c
                        (gencode c output 'call)))))

(defmethod do-load ((s UEMSystem) filename)
           (let ((ftype (pathname-type filename)))
             (if (string= ftype "lisp")
                 (progn
                   (format t "Loading file ~a...~%" filename)
                   (in-package :uem)
                   (let ((*readtable* (copy-readtable nil)))
                     (progn
                       ;;(setf (readtable-case *readtable*) :preserve)
                       (load filename))))
               (format t "Ignore file ~a~%" filename))))

(defclass UEMUnknown (UEMSystem)
  ())

