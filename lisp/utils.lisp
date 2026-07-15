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
;; Supports #.expr expansion inside the here-doc:
;;   #.*variable*  - expands a variable value
;;   #.(expr)      - expands a function call or expression
;; When no #. is present, returns a plain string (backward-compatible).
;; When #. is present, returns a (concatenate 'string ...) form.

(defun symbol-terminator-p (ch)
  "Return T if CH would terminate a symbol in here-doc context."
  (member ch '(#\Space #\Tab #\Newline #\Return
               #\/ #\" #\' #\( #\) #\, #\; #\#)))

(defun read-heredoc-expr (stream)
  "Read an expression after #. in a here-doc.
   If starts with (, use CL reader for the full form.
   Otherwise, read a symbol name until a terminator."
  (let ((next (peek-char nil stream)))
    (if (char= #\( next)
        ;; Parenthesized form: use standard CL reader
        (read stream t nil t)
        ;; Bare symbol: read chars until terminator
        (let ((sym-str (with-output-to-string (s)
                         (loop :for c := (peek-char nil stream)
                               :while (not (symbol-terminator-p c))
                               :do (write-char (read-char stream) s)))))
          (read-from-string sym-str)))))

(defun read-doc-here (stream char arg)
  (declare (ignore char arg))
  (let ((parts '())
        (current (make-string-output-stream)))
    (loop :for ch := (read-char stream) :do
      (cond
        ((and (char= #\/ ch)
              (char= #\# (peek-char nil stream)))
         ;; Could be end delimiter /# or start of expansion /#.
         (read-char stream) ;; consume #
         (cond
           ((char= #\. (peek-char nil stream))
            ;; It's /#. — / is literal, #. is expansion
            (write-char #\/ current)
            (read-char stream) ;; consume .
            (push (get-output-stream-string current) parts)
            (push (read-heredoc-expr stream) parts)
            (setf current (make-string-output-stream)))
           (t
            ;; End delimiter /#
            (push (get-output-stream-string current) parts)
            (loop-finish))))
        ;; Expansion: #. not preceded by /
        ((and (char= #\# ch)
              (char= #\. (peek-char nil stream)))
         (read-char stream)
         (push (get-output-stream-string current) parts)
         (push (read-heredoc-expr stream) parts)
         (setf current (make-string-output-stream)))
        ;; Regular character
        (t (write-char ch current))))
    (let ((collected (nreverse parts)))
      (if (every #'stringp collected)
          ;; No expansion: plain string
          (apply #'concatenate 'string collected)
          ;; Has expansion: build concatenate form
          `(concatenate 'string
                        ,@(mapcar (lambda (p)
                                    (if (stringp p)
                                        p
                                        `(princ-to-string ,p)))
                                  collected))))))

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

(defun get-hostname ()
  "Get the machine hostname, equivalent to $(uname -n)."
  (string-trim '(#\Newline #\Return #\Space)
               (machine-instance)))


