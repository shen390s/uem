(in-package :uem)

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

(defmethod sections ((s UEMEmacs))
  '(:init :core :ui :modes :complete :app))

(defmethod gencode-section ((s UEMEmacs) section)
  (format t "Generate code for ~a system ~a~%" section s)
  (with-output-to-string (out)
    (with-slots (init app core ui modes complete) s
      (cond
        ((eql section :init)
         (progn
           (format out "~a~%" init)
           (maphash #'(lambda (k v)
                        (format out ";;; ~a for feature ~a~%" section k)
                        (let ((c (gencode-action v :ignore `(,section))))
                          (when c
                            (format out "~a~%" c))))
                    *uem-features*)))
        (t (maphash #'(lambda (k v)
                        (format out ";;; ~a for feature ~a~%" section k)
                        (let ((c (gencode-action v :ignore `(,section))))
                          (when c
                            (format out "~a~%" c))))
                    *uem-features*))))))

