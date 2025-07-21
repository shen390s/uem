(defun unfill-entry (self action)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(unfill :type git
			    :host github
			    :repo "purcell/unfill"))
       (require 'unfill))
     /#)
    ((:CALL)
     #/
     (progn
       t)
     /#
     )))

(feat! unfill
       "Generate call graph for c/c++"
       (:editor)
       unfill-entry)
