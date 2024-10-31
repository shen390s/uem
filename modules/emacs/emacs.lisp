(sys! emacs
      :init 
      #/(progn
	  (setq emacs-config-dir "~/.config/emacs/uem")
	  (unless (file-exists-p emacs-config-dir)
	    (make-directory emacs-config-dir))
	  (setq custom-file (concat emacs-config-dir "/custom.el"))
	  (setq custom-safe-themes t)
	  ;;(setq tsc-dyn-get-from '(:compilation))
	  (setenv "HTTPS_PROXY" "sock5://localhost:8118")
	  (setenv "HTTP_PROXY" "socks5://localhost:8118"))
      /#
      
      :core 
      straight
      
      :editor 
      (bind-mode ("poly-markdown-mode" ".md" ".markdown" ".mkd" ".mdown" ".mkdn" ".mdwn")
		 ("poly-ascii-mode" ".adoc")
		 ("simplex-mode" ".sex" ".simplex"))
      (undo-tree)
      (yasnippet )
      (evil-surround)
      (iedit )

      :ui
      (evil)
      (smart-mode-line)
      (load-custom :theme "rshen")
      (smex)
      (icicles)
      ;;(powerline +airline-themes :theme airline-light)
      (telephone-line)

      :modes
      (c +eldoc +guess-c-style +call-graph +which-func)
      (go +eldoc +which-func)
      (emacs-lisp -parinfer -lsp)
      (lisp +eldoc -parinfer)
      (poly-markdown +vmd)
      (poly-org +livemarkup)
      (poly-asciidoc +livemarkup)
      (tex +eldoc +auctex +magic-latex)
      (fundamental +hlinum +ruler +smartparens) 
      (simplex)
      (prog  +hlinum +ruler +smartparens +rainbow-delimiters +rainbow-identifiers -flymake)

      :complete
      vertico
      
      :app
      (emacs-server)
      (which-key )
      (origami )
      (treemacs +evil +magit)
      (noccur )
      (emacs-quilt)
      (magit ) 
      (sly))
