(in-package :uem)

(defclass EmacsInitScope (UEMScope)
  ())

(defmethod gencode :before ((s EmacsInitScope) output action)
           (format output ";;; Generate code for scope ~a action ~a ~%"
                   (name s) action))

(defmethod gencode ((s EmacsInitScope) output action)
  (case action
    ((:INIT)
     (with-slots (data) s
       (loop for it in data
	     do (format output "~a~%" (if (stringp it)
                                          it
                                          (eval it))))
       (format output "(setq *module-root-path* \"~a\")~%"
               *uem-module-root*)))
    (otherwise "")))

(defclass EmacsGenericScope (UEMFeatureScope)
  ())

(defmethod gencode :before ((s EmacsGenericScope) output action)
           (format output ";;; Generate code for scope ~a action ~a ~%"
                   (name s) action))


(defclass EmacsModeScope (UEMScope)
  ())

(defmethod add-mode ((s EmacsModeScope) m)
	   (add-child s m))

(defmethod modes ((s EmacsModeScope))
	   (children s))

(defmethod gencode :before ((s EmacsModeScope) output action)
           (format output ";;; Generate code for scope ~a action ~a ~%"
                   (name s) action))

(defmethod parse-config ((s EmacsModeScope))
           (with-slots (data children) s
             (format t "Init modes data: ~a ~%" data)
             (loop for m in data
                   do (let ((nm (car m))
                            (fs (cdr m)))
                        (progn
                          (format t "Adding mode  ~a ~a ~%" nm fs)
                          (add-mode s (make-emacs-mode nm  s fs)))))))

(defmethod gencode ((s EmacsModeScope) output action)
           (format t "gencode ~a action ~a ~%" s action)
           (loop for c in (modes s)
                 do (progn
		      (format t "gencode for mode ~a action ~a~%"
			      c action)
		      (gencode (child s c) output action)
		      (format t "end to gencode for mode ~a(~a)~%"
			      c (child s c)))))

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

(defmethod cmp-child ((s UEMEmacs) s1 s2)
           (let ((prio '(:init 0 :core 1 :editor 2 :ui 3 :complete 4 :modes 5 :app 6)))
             (<= (getf prio s1) (getf prio s2))))

(defmethod parse-config ((s UEMEmacs) )
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

