(defun claude-code-entry (self action )
  (case action
    ((:INIT) #/(progn
                 (pkginstall 'vterm)
                 (pkginstall '(claude-code-ide :type git
                                               :host github
                                               :repo "manzaltu/claude-code-ide.el")))
     /#
     )
    ((:CALL) #/(progn
                 (setq claude-code-ide-terminal-backend 'vterm)
                 (claude-code-ide-emacs-tools-setup))
     /#
     )
    (otherwise "")))

(feat! claude-code
       "run claude code inside emacs"
       (:app)
       claude-code-entry)
