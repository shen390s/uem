(defvar *eldoc-mode-pkg-map*
  '(:c ("c-eldoc") :go ("go-eldoc")))

(defun get-mode-eldoc-pkgs (m)
  (format t "Get eldoc pkg for mode ~a~%" m)
  ;; FIXME:
  (let ((pkgs (getf *eldoc-mode-pkg-map* (mk-keyword m))))
    (if pkgs
        pkgs
      `(,(format nil "~a-eldoc" (string-downcase m))))))

(defun eldoc-entry (self action args)
  (format t "eldoc self ~a action: ~a args ~a~%"
	  self action args)
  (let ((own (owner self)))
    (format t "owner is ~a~%" own)
    (case action
	  ((:INIT)
	   (if (typep own 'EmacsGenericMode)
               (progn
                 (format t "eldoc mode ~a~%"
                         (name own))
                 (with-output-to-string
                   (out)
                   (format out "(progn~%")
                   (loop for pkg in (get-mode-eldoc-pkgs (name own))
                         do (format out "(pkginstall '~a)~%" pkg))
                   (format out "t)~%")))
             ""))
          (otherwise ""))))

(feat! eldoc
       "eldoc"
       (:modes :ui)
       eldoc-entry)
