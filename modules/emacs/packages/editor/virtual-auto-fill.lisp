(defun virtual-auto-fill-entry (self action)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(virtual-auto-fill :type git
			    :host github
			    :repo "luisgerhorst/virtual-auto-fill"))
       (require 'virtual-auto-fill))
     /#)
    ((:CALL)
     #/
     (progn
       (virtual-auto-fill-mode 1))
     /#
     )))

(feat! virtual-auto-fill
       "Generate call graph for c/c++"
       (:mode)
       virtual-auto-fill-entry)
