(in-package :uem)

(defun run-program-ex (args &key output)
  (if (ignore-errors #1=(read-from-string "uiop/run-program:run-program"))
      (funcall #1# (format nil "~{~A~^ ~}" args)
               :output output
               #+(and sbcl win32) :force-shell #+(and sbcl win32) nil
               :error-output :interactive)
      (with-output-to-string (out)
        #+sbcl(funcall (read-from-string "sb-ext:run-program")
                       (first args) (mapcar #'princ-to-string (rest args))
                       :output out)
        #+clisp(if (eql output :string)
                   (format nil "~{~A~%~}"
                           (loop with i = (ext:run-shell-command (format nil "~{~A~^ ~}" args) :output :stream)
                                 for line = (read-line i nil nil)
                                 while line
                                 collect line))
                   (ext:run-shell-command (format nil "~{~A~^ ~}" args))))))

(defun normalize-feature-or-option (feature-or-option)
  (let ((s (symbol-name feature-or-option)))
    (cond
      ((eql (aref s 0) #\+)
       (list (intern (subseq s 1 (length s))) :activate))
      ((eql (aref s 0) #\-)
       (list (intern (subseq s 1 (length s)))  :deactivate))
      (t (list feature-or-option  :activate)))))

(defun normalize-feature (feature)
  (cond
    ((listp feature)
     (let ((fname (car feature))
           (options (cdr feature)))
         `(,fname  :activate ,@options)))
    (t (normalize-feature-or-option feature))))

(defun normalize-feature-list (features)
  ;;(format t "normalize feature list: ~a~%" features)
  (loop for f in features
        collect `,(normalize-feature f)))

(defun as-string (v)
  (with-output-to-string (output)
    (format output "~a" v)))

(defun get-value (val-or-func self action )
  (let ((v (cond
            ((functionp val-or-func) (funcall val-or-func
                                              self
                                              action))
             (t (as-string val-or-func)))))
    (format t "get-value ~a self ~a action ~a  = ~a~%"
            val-or-func self action v)
    v))

;; here reader for #/ .... /#
(defun read-doc-here (stream char arg)
  (declare (ignore char arg))
  (with-output-to-string (str)
    (loop :for char := (read-char stream) :do
      (if (and (char= #\/ char)
               (char= #\# (peek-char nil stream)))
          (progn
            (read-char stream)
            (loop-finish))
          (write-char char str)))))

(defun quote-non-string (x)
  (if (stringp x)
      x
      (quote x)))

(defun mk-keyword (k)
  (read-from-string (format nil ":~a" k)))

(defun get-executable-path ()
  (uiop/filesystem:truename*
   #+sbcl
   (car sb-ext:*posix-argv*)
   #+ccl
   (ccl:argv 0)
   #+clisp
   (car ext:*args*)
   #+ecl
   (car (si:command-args))
   #-(or sbcl ccl clisp ecl)
   (error "Current lisp  implementation not supported by GET-EXECUTABLE_PATH")))

(defun get-directory-part (file-path)
  (let ((full-path (pathname file-path)))
    (let* ((pn (uiop:ensure-directory-pathname full-path))
           (dir-list (pathname-directory pn))
           (parent-list (butlast dir-list)))
      (make-pathname :directory parent-list
                     :defaults pn
                     :name nil
                     :type nil))))
