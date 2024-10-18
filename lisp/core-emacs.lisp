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
       (format output "~a~%" data)))
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
           (case action
                 ((:CALL)
                  (format output "(add-hook '~a-mode-hook~% #'(lambda ()~%"
                          (string-downcase (name s))))
                 (otherwise t)))

(defmethod gencode :after ((s EmacsMode) output action)
           (case action
                 ((:CALL)
                  (format output "))~%"))
                 (otherwise t)))

;; (defmethod gencode ((s EmacsMode) output action)
;;            (with-slots (features) s
;;              (case action
;;                    ((:CALL)
;;                     (progn
;;                       (format output ";;; mode features: ~a~%" features)
;;                       (loop for f in features
;;                             do (let ((fn (car f))
;;                                      (act (cadr f))
;;                                      (args (cddr f)))
;;                                  (call-feature-by-name fn output act args)))))
;;                    (otherwise t))))

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
                                       :sys s
                                       :data init))
             (add-scope s
                        (make-instance 'EmacsGenericScope
                                       :name :core
                                       :sys s
                                       :data core))
             (add-scope s
                        (make-instance 'EmacsGenericScope
                                       :name :app
                                       :sys s
                                       :data app))
             (add-scope s
                        (make-instance 'EmacsGenericScope
                                       :name :editor
                                       :sys s
                                       :data editor))
             (add-scope s
                        (make-instance 'EmacsGenericScope
                                       :name :ui
                                       :sys s
                                       :data ui))
             (add-scope s
                        (make-instance 'EmacsGenericScope
                                       :name :complete
                                       :sys s
                                       :data core))
             (add-scope s
                        (make-instance 'EmacsModeScope
                                       :name :modes
                                       :sys s
                                       :data modes))
             (format t "emacs scope initialized~%")))

