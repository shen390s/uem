(defun claude-code-entry (self action )
  (case action
    ((:INIT) #/(progn
                 (pkginstall '(inheritenv :type git :host github
                                     :repo "purcell/inheritenv"))
                 (pkginstall '(emacs-eat :type git
                                     :host codeberg
                                     :repo "akib/emacs-eat"
                                     :files ("*.el" ("term" "term/*.el") "*.texi"
                                             "*.ti" ("terminfo/e" "terminfo/e/*")
                                             ("terminfo/65" "terminfo/65/*")
                                             ("integration" "integration/*")
                                             (:exclude ".dir-locals.el" "*-tests.el"))))
                 (pkginstall 'vterm)
                 (pkginstall '(claude-code :type git :host github
                                     :repo "stevemolitor/claude-code.el"
                                     :branch "main"
                                     :depth 1
                                     :files ("*.el" (:exclude "images/*"))))
                 (pkginstall '(monet :type git :host github
                                     :repo "stevemolitor/monet"))
                 (add-hook 'claude-code-process-environment-functions #'monet-start-server-function))
     /#
     )
    ((:CALL) #/(progn
                 (monet-mode 1)
                 (claude-code-mode))
     /#
     )
    (otherwise "")))

(feat! claude-code
       "run claude code inside emacs"
       (:app)
       claude-code-entry)
