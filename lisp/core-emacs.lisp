(in-package :uem)

(defclass EmacsInitScope (UEMDataScope)
  ())

(defmethod gencode :before ((s EmacsInitScope) output action)
           (format output ";;; Generate code for scope ~a action ~a ~%"
                   (name s) action))

(defmethod gencode ((s EmacsInitScope) output action)
  (case action
    ((:INIT)
     (with-slots (data) s
       (format output "~a~%" data)
       (format output "(setq *module-root-path* \"~a\")~%"
               *uem-module-root*)))
    (otherwise "")))

(defclass EmacsGenericScope (UEMFeatureScope)
  ())

(defmethod gencode :before ((s EmacsGenericScope) output action)
           (format output ";;; Generate code for scope ~a action ~a ~%"
                   (name s) action))


(defclass EmacsModeScope (UEMCompoundScope)
  ())

(defmethod gencode :before ((s EmacsModeScope) output action)
           (format output ";;; Generate code for scope ~a action ~a ~%"
                   (name s) action))

(defmethod initialize-instance :after ((s EmacsModeScope) &key)
           (with-slots (data scopes) s
             (format t "Init modes data: ~a ~%" data)
             (loop for m in data
                   do (let ((nm (car m))
                            (fs (cdr m)))
                        (progn
                          (format t "Adding scope ~a ~a ~%" nm fs)
                          (add-scope s (make-emacs-mode nm  s fs)))))))

(defmethod gencode ((s EmacsModeScope) output action)
           (format t "gencode ~a action ~a ~%" s action)
           (with-slots (scopes) s
             (loop for c in scopes
                   do (gencode c output action))))

(defclass UEMEmacs (UEMSystem)
  ((app :initarg :app
        :initform nil)
   (core :initarg :core
         :initform nil)
   (editor :initarg :editor
           :initform nil)
   (ui :initarg :ui
       :initform nil)
   (modes :initarg :modes
          :initform nil)
   (complete :initarg :complete
             :initform nil)))

(defmethod cmp-scope ((s UEMEmacs) s1 s2)
           (let ((prio '(:init 0 :core 1 :editor 2 :ui 3 :complete 4 :modes 5 :app 6)))
             (<= (getf prio s1) (getf prio s2))))

(defmethod initialize-instance :after ((s UEMEmacs) &key)
           (with-slots (init core ui modes complete app editor) s
             (add-scope s
                        (make-instance 'EmacsInitScope
                                       :name :init
                                       :owner s
                                       :data init))
             (add-scope s
                        (make-instance 'EmacsGenericScope
                                       :name :core
                                       :owner s
                                       :data core))
             (add-scope s
                        (make-instance 'EmacsGenericScope
                                       :name :app
                                       :owner s
                                       :data app))
             (add-scope s
                        (make-instance 'EmacsGenericScope
                                       :name :editor
                                       :owner s
                                       :data editor))
             (add-scope s
                        (make-instance 'EmacsGenericScope
                                       :name :ui
                                       :owner s
                                       :data ui))
             (add-scope s
                        (make-instance 'EmacsGenericScope
                                       :name :complete
                                       :owner s
                                       :data complete))
             (add-scope s
                        (make-instance 'EmacsModeScope
                                       :name :modes
                                       :owner s
                                       :data modes))
             (format t "emacs scope initialized~%")))

