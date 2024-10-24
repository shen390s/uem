(defun smart-mode-line-entry (self action args)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(smart-mode-line
		     :type git
		     :host github
		     :repo "Malabarba/smart-mode-line")))
     /#)
    ((:CALL)
     #/
     (progn
       (require 'smart-mode-line)
       (sml/setup))
     /#)))

(feat! smart-mode-line
       "smart mode line"
       (:ui)
       smart-mode-line-entry)
