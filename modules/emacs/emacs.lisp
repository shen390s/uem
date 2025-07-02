(sys! emacs
      :init 
      #/(progn
	  (setq emacs-config-dir "~/.config/emacs/uem")
	  (unless (file-exists-p emacs-config-dir)
	    (make-directory emacs-config-dir t))
	  (setq custom-file (concat emacs-config-dir "/custom.el"))
	  (setq custom-safe-themes t)
	  ;;(setq tsc-dyn-get-from '(:compilation))
	  ;;(setenv "HTTPS_PROXY" "http://localhost:8118")
	  ;;(setenv "HTTP_PROXY" "http://localhost:8118")
	  (setq proxies (getenv "UEM_PROXYIES"))
	  (setq github_apikey "add your github api key here")
	  (setq c-eldoc-includes
		"-I/usr/include -I/usr/local/include -I. -I.."))
      /#
      
      :core 
      proxy  ;; put this before core that we can use proxy for straight installation
      straight
      
      :editor 
      (bind-mode ("poly-markdown-mode" ".md" ".markdown" ".mkd" ".mdown" ".mkdn" ".mdwn")
		 ("poly-ascii-mode" ".adoc")
		 ("simplex-mode" ".sex" ".simplex" ".sx")
		 ("capnp-mode" ".capnp")
		 ("emacs-lisp-mode" ".el" "Cask")
		 ("zig-mode" ".zig" ".zon")
		 ("nix-mode" ".nix")
		 ("poly-quarto-mode" ".qmd" ".Rmd"))
      (undo-tree)
      (yasnippet )
      (evil-surround)
      (iedit )
      (clang-format)

      :ui
      (evil)
      (smart-mode-line)
      (load-custom :theme "rshen")
      (smex)
      (icicles)
      ;;(powerline +airline-themes :theme airline-light)
      (telephone-line)

      :modes
      (c +eldoc +xce-c-style +call-graph +which-func +tree-sitter)
      (go +eldoc +which-func)
      (emacs-lisp -parinfer -lsp)
      (lisp +eldoc -parinfer)
      (poly-markdown +vmd)
      (poly-org +livemarkup)
      (poly-asciidoc +livemarkup)
      (tex +eldoc +auctex +magic-latex)
      (fundamental +hlinum +ruler +smartparens) 
      (simplex)
      (capnp)
      (prog  +hlinum +ruler +smartparens +rainbow-delimiters +rainbow-identifiers -flymake)
      (nix)
      (zig)
      (quarto)

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
      (gptel)
      (sly))
