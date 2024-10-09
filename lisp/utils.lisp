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

(defun collect-lists (acc lists)
  (if lists
      (collect-lists (append acc (car lists))
                     (cdr lists))
    acc))
  
(defun quote-keyword-args (args)
  (let ((keywords (remove-if-not #'keywordp args)))
    (let ((xargs (collect-lists nil
                                (loop for k in keywords
                                      collect `(,k ',(getf args k))))))
      (format t "xargs: ~A ~%" xargs)
      xargs))))


(defun walk-directory (dirname fn))
(defun load-files (name directory)
  )
