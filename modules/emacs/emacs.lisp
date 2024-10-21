(defun emacs-init ()
  #/(progn
      (setq emacs-config-dir "~/.config/emacs/uem")
      (unless (file-exists-p emacs-config-dir)
        (make-directory emacs-config-dir))
      (setq custom-file (concat emacs-config-dir "/custom.el"))
      (setq custom-safe-themes t)
      (setenv "HTTPS_PROXY" "sock5://localhost:8118")
      (setenv "HTTP_PROXY" "socks5://localhost:8118"))
/#
      )

  (defun emacs-core ()
    '(straight))

  (defun emacs-modes ()
    '((c +eldoc +guess-c-style +call-graph +which-func)
      (go +eldoc +which-func)
      (emacs-lisp -parinfer -lsp)
      (lisp -parinfer)
      (poly-markdown +vmd)
      (poly-org +livemarkup)
      (poly-asciidoc +livemarkup)
      (tex +auctex +magic-latex)
      (fundamental +hlinum +ruler +smartparens) 
      (prog +hlinum +ruler +smartparens +rainbow-delimiters +rainbow-identifiers -flymake)))

  (defun emacs-ui ()
    '((evil)
      (smart-mode-line)
      (load-custom :theme "rshen")
      (smex)
      (icicles)
      (powerline +airline-themes :theme airline-light)
      (adjust-display)) )

  (defun emacs-complete ()
    ;;(ivy)
    ;;(company +elisp +math +auctex +lsp)
    '(vertico))

  (defun emacs-editor ()
    '((undo-tree )
      (yasnippet )
      (evil-surround)
      (iedit )))
  ;;(-eldoc)

  (defun emacs-app ()
    '((emacs-server)
      (which-key )
      (origami )
      (treemacs +evil +magit)
      (noccur )
      (emacs-quilt)
      (magit ) 
      (sly)))

  (sys! emacs
        :init emacs-init
        :core emacs-core
        :editor emacs-editor
        :ui emacs-ui
        :modes emacs-modes
        :complete emacs-complete
        :app emacs-app)
