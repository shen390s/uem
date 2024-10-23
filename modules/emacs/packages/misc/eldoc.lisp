(defun eldoc-entry (action args)
  (format t "eldoc action: ~a args ~a~%"
	  action args)
  (case action
	((:INIT)
	 "")))

(feat! eldoc
       "eldoc"
       (:modes :ui)
       eldoc-entry)
