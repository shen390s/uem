(in-package :uem)

(defclass EmacsScope (UEMScope)
  ((data :initarg :data
         :initform nil)))

(defmethod gencode :before ((s EmacsScope) output action) 
           (format output ";;; Generate code for ~a~%"
                   (name s)))

(defclass EmacsInitScope (EmacsScope)
  ())

(defmethod gencode ((s EmacsInitScope) output action)
           (with-slots (data) s
             (print data output)
             (format output "~%")))

(defclass EmacsGenericScope (EmacsScope)
  ((features :initarg :features
             :initform nil)))

(defmethod initialize-instance :after ((s EmacsGenericScope) &key)
  (with-slots (data features) s
    (setf features (normalize-feature-list data))
    (format t "features in scope ~a: ~a~%"
            (name s) features)))

(defmethod gencode ((s EmacsGenericScope) output action)
  (with-slots (features) s
    (format t "gencode features ~a~%" features)
    (loop for f in features
          do (let* ((nf (car f))
                    (sf (getf f nf)))
               (format t "nf ~a sf ~a ~%" nf sf)
               (let ((feat (feat-get nf)))
                 (when feat
                   (let ((ctx (list s)))
                     (let ((c (invoke-feature feat action ctx f)))
                       (when c
                         (format output "~a~%" c))))))))))

(defclass EmacsModeScope (EmacsScope UEMCompoundScope)
  ())

(defmethod initialize-instance :after ((s EmacsModeScope) &key)
  (with-slots (data scopes) s
    (format t "Init modes data: ~a ~%" data)
    (loop for m in data
          do (let ((nm (car m))
                   (fs (cdr m)))
               (progn
                 (format t "Adding scope ~a ~a ~%" nm fs)
                 (add-scope s
                            (make-instance 'EmacsMode
                                           :name nm
                                           :sys (sys s)
                                           :data fs)))))))

(defmethod gencode ((s EmacsModeScope) output action)
           (format t "gencode ~a action ~a ~%" s action)
           (with-slots (scopes) s
             (loop for c in scopes
                   do (gencode c output action))))

(defclass EmacsMode (EmacsGenericScope)
  ())

(defmethod gencode :before ((s EmacsMode) output action)
           (format output "add-hook '~a-mode-hook #'(lambda ()~%"
                   (string-downcase (name s))))

(defmethod gencode :after ((s EmacsMode) output action)
           (format output ")~%"))
;;(defmethod gencode ((s EmacsMode) output action)
;;  )

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
           (with-slots (init core ui modes complete app) s
             (add-scope s
                        (make-instance 'EmacsInitScope
                                       :name "Init"
                                       :sys s
                                       :data init))
             (add-scope s
                        (make-instance 'EmacsGenericScope
                                       :name "core"
                                       :sys s
                                       :data core))
             (add-scope s
                        (make-instance 'EmacsGenericScope
                                       :name "app"
                                       :sys s
                                       :data app))
             (add-scope s
                        (make-instance 'EmacsGenericScope
                                       :name "ui"
                                       :sys s
                                       :data ui))
             (add-scope s
                        (make-instance 'EmacsGenericScope
                                       :name "complete"
                                       :sys s
                                       :data core))
             (add-scope s
                        (make-instance 'EmacsModeScope
                                       :name "modes"
                                       :sys s
                                       :data modes))
             (format t "emacs scope initialized~%")))

