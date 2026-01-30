(defun bind-mode-entry (self action)
  (format t "bind-mode data: ~a~%"
	  (data self))
  (case action
    ((:POST-CALL)
     (with-output-to-string (out)
			    (format out "(progn~%")
			    (loop for it in (cddr (data self))
				  do (progn
				       (let ((m (car it))
					     (suffixes (cdr it)))
					 (loop for s in suffixes
					       do (progn
						    (format out
							    "(add-to-list 'auto-mode-alist '(\"\\\\~a\\\\'\" . ~a))~%"
							    s m))))))
			    (format out ")~%")))
    (otherwise t)))

(feat! bind-mode
       "bind mode to file suffixes"
       (:editor)
       bind-mode-entry)
