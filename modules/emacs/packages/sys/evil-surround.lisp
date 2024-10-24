(defun evil-surround-entry (self action args)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(evil-surround :type git
		     :host github
		     :repo "emacs-evil/evil-surround")))
     /#)
    ((:CALL)
     #/
     (progn
       (global-evil-surround-mode 1))
     /#)
    (otherwise "")))

(feat! evil-surround
       "emulates surround vim"
       (:editor)
       evil-surround-entry)
