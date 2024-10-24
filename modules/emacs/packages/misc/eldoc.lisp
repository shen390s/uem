(defvar *eldoc-mode-pkg-map*
  '(:c ("c-eldoc") :go ("go-eldoc") :css ("css-eldoc")
    :irony ("irony-eldoc") :php ("php-eldoc") :cmake ("eldoc-cmake")))

(defun get-mode-eldoc-pkgs (m)
  (format t "Get eldoc pkg for mode ~a~%" m)
  (let ((pkgs (getf *eldoc-mode-pkg-map* (mk-keyword m))))
    pkgs))

(defun eldoc-entry (self action args)
  (format t "eldoc self ~a action ~a args ~a~%"
	  self action args)
  (let ((own (owner self)))
    (format t "Owner is ~a~%" own)
    (case action
      ((:INIT)
       (if (typep own 'EmacsGenericMode)
	   (progn
	     (format t "eldoc mode ~a~%"
		     (name own))
	     (with-output-to-string (out)
	       (format out "(progn~%")
	       (loop for pkg in (get-mode-eldoc-pkgs (name own))
		     do (progn
			  (format out "(pkginstall '~a)~%" pkg)
			  (format out "(require '~a)~%" pkg)))
	       (format out "t)~%")))
	   ""))
      ((:CALL)
       #/
       (progn
	 (eldoc-mode 1))
       /#)
      (otherwise ""))))

(feat! eldoc
       "eldoc"
       (:modes :ui)
       eldoc-entry)
