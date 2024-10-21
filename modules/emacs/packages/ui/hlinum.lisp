(defun hlinum-entry (action args)
  (case action
	((:INIT)
	 #/
	 (pkginstall '(hlinum-mode :type git
                       :host github
                       :repo "tom-tan/hlinum-mode"))
	 /#)
	((:CALL)
	 #/
	 (progn
           (display-line-numbers-mode 1)
	   (hlinum-activate))
	 /#)
	(otherwise "")))

(feat! hlinum
       "highlight current line number"
       (:ui)
       hlinum-entry)
