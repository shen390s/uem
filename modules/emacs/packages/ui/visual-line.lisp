(defun visual-line-entry (self action)
  (case action
	((:INIT)
	 #/
	 (progn t)
	 /#)
	((:CALL)
	 #/
	 (progn
           (visual-line-mode 1))
	 /#)
	(otherwise "")))

(feat! visual-line
       "highlight current line number"
       (:ui)
       visual-line-entry)
