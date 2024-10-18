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
       (list (intern (subseq s 1 (length s))) 1))
      ((eql (aref s 0) #\-)
       (list (intern (subseq s 1 (length s)))  -1))
      (t (list feature-or-option  1)))))

(defun normalize-feature (feature)
  (cond
    ((listp feature)
     (let ((fname (car feature))
           (options (cdr feature)))
         `(,fname  1 ,@options)))
    (t (normalize-feature-or-option feature))))

(defun normalize-feature-list (features)
  ;;(format t "normalize feature list: ~a~%" features)
  (loop for f in features
        collect `,(normalize-feature f)))

(defun as-string (v)
  (with-output-to-string (output)
    (format output "~a" v)))

(defun get-value (val-or-func action args)
  (let ((v (cond
            ((functionp val-or-func) (funcall val-or-func
                                              action
                                              args))
             (t (as-string val-or-func)))))
    (format t "get-value ~a action ~a args: ~a = ~a~%"
            val-or-func action args v)
    v))

(defun copy-until-tag (si so tag)
  (format t "copying data...~%")
  (handler-case
      (let ((v (read-line si)))
        (when (not (string= v tag))
          (format so "~a~%" v)
          (copy-until-tag si so tag)))
    (end-of-file (c) t)))

(defun read-doc-here (stream ch1 ch2)
  (format t "read-doc-here~%")
  (let* ((tag (read-line stream stream nil "")))
    (with-output-to-string (out)
      (copy-until-tag stream out tag))))

(defun quote-non-string (x)
  (if (stringp x)
      x
      (quote x)))
