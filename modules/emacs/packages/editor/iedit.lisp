(defun iedit-entry (self action)
  (case action
    ((:init)
     #/
     (progn
       (pkginstall '(iedit :type git
			   :host github
			   :repo "victorhge/iedit")))
     /#
     )
    ((:call)
     #/
     (progn
       (require 'iedit))
     /#)))

(feat! iedit
       "Edit multiple regions in the same way simultaneously"
       (:editor)
       iedit-entry)
