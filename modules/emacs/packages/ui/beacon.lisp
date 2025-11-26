(defun beacon-entry (self action)
  (case action
	((:INIT)
	 #/
	 (pkginstall '(beacon-mode :type git
                               :host github
                               :repo "Malabarba/beacon"))
	 /#)
	((:CALL)
	 #/
	 (progn
	   (beacon-mode 1))
	 /#)
	(otherwise "")))

(feat! beacon
       "highlight current line number"
       (:ui)
       beacon-entry)
