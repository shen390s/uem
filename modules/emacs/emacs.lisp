(sys! emacs
      :init
      `(progn
         (setq a 10)
         (setq b 20)
         (setq c-eldoc-includes
               "-I/usr/include -I/usr/local/include -I. -I..")
         (setq cg-initial-max-depth 2)
         ;; disable confirm of loading theme
         (setq custom-safe-themes t)
         (setq debug-on-quit t)
         (setq task-schedule-interval 1)
         (add-to-list 'exec-path
                      (expand-file-name "~/tools/clangd_16.0.2/bin")))
      
      :core
      ((pkg-mirrors  ;; :mirrors (github . "hub.fastgit.org")
                    ;;:mirrors (github . "github.com.cnpmjs.org")
		    :local-repo user "Emacs/pkg.mirrors"))

      :modes
      ((c +eldoc +guess-c-style +call-graph +which-func)
       (go +eldoc +which-func)
       (emacs-lisp features -parinfer -lsp)
       (lisp -parinfer)
       (poly-markdown +vmd)
       (poly-org +livemarkup)
       (poly-asciidoc +livemarkup)
       (tex +auctex +magic-latex)
       (basic +hlinum +ruler +smartparens) 
       (prog -flymake))
      
      :ui
      ((evil)
       (smart-mode-line)
       (load-custom :theme rshen)
       (smex)
       (icicles)
       (powerline +airline-themes :theme airline-light)
       (adjust-display))
      
      :complete
      ;;(ivy)
      ;;(company +elisp +math +auctex +lsp)
      (vertico)

      :editor
      ((undo-tree +delay-activate)
       (yasnippet +delay-activate)
       (evil-surround +delay-activate)
       (iedit +delay-activate))
      ;;(-eldoc)

      :app
      ((emacs-server)
       (which-key +delay-activate)
       (origami +delay-activate)
       (treemacs +evil +magit)
       (noccur +delay-activate)
       (emacs-quilt)
       (magit +delay-activate) 
       (sly +fancy)
       ))


(format t "Hello from loading file~%")
