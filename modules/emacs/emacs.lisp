(defun emacs-init ()
  #/(progn
      (setq custom-safe-themes t)
      (setenv "HTTPS_PROXY" "sock5://localhost:8118")
      (setenv "HTTP_PROXY" "socks5://localhost:8118")
      (defvar bootstrap-version)
      (let ((bootstrap-file
              (expand-file-name
               "straight/repos/straight.el/bootstrap.el"
               (or (bound-and-true-p straight-base-dir)
                   user-emacs-directory)))
            (bootstrap-version 7))
        (unless (file-exists-p bootstrap-file)
          (with-current-buffer
              (url-retrieve-synchronously
               "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
               'silent 'inhibit-cookies)
            (goto-char (point-max))
            (eval-print-last-sexp)))
        (load bootstrap-file nil 'nomessage)))
/#
      )

  (defun emacs-core ()
    '((pkg-mirrors  ;; :mirrors (github . "hub.fastgit.org")
       ;;:mirrors (github . "github.com.cnpmjs.org")
       :local-repo user "Emacs/pkg.mirrors")))

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
      (prog -flymake)))

  (defun emacs-ui ()
    '((evil)
      (smart-mode-line)
      (load-custom :theme rshen)
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
