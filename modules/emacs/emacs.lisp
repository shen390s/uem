(sys! emacs
      :init 
      #/(progn
	  (setq emacs-config-dir "~/.config/emacs/uem")
	  (unless (file-exists-p emacs-config-dir)
	    (make-directory emacs-config-dir t))
	  (setq custom-file (concat emacs-config-dir "/custom.el"))
	  (setq custom-safe-themes t)
	  (setq-default indent-tabs-mode nil)
	  (setq-default tab-width 4)
	  ;;(setq tsc-dyn-get-from '(:compilation))
	  ;;(setenv "HTTPS_PROXY" "http://localhost:8118")
	  ;;(setenv "HTTP_PROXY" "http://localhost:8118")
	  (setq proxies (getenv "UEM_PROXYIES"))
	  (setq github_apikey "add your github api key here")
	  (setq c-eldoc-includes
		"-I/usr/include -I/usr/local/include -I. -I..")
      (setq cursory-default-preset 'underscore-thick)
      (setq straight-vc-git-default-protocol 'ssh))
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
		 ("typst-ts-mode" ".typ")
		 ("yaml-ts-mode" ".yml" ".yaml")
		 ("poly-quarto-mode" ".qmd" ".Rmd")
		 ("meson-mode" "meson.build")
         ("lua-mode" ".lua")
         ("tlaplus-mode" ".tla" ".tla+")
         ("cmake-mode" "CMakeLists.txt" ".cmake"))
      (undo-tree)
      (yasnippet )
      (evil-surround)
      (iedit )
      (clang-format)
      (unfill)
      (beacon)
      (cursory)

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
      (poly-markdown +vmd +virtual-auto-fill +hlinum)
      (poly-org +livemarkup +virtual-auto-fill +hlinum)
      (poly-asciidoc +livemarkup +virtual-auto-fill +hlinum)
      (tex +eldoc +auctex +magic-latex +virtual-auto-fill +hlinum)
      (fundamental +hlinum +ruler +smartparens) 
      (simplex +hlinum)
      (capnp)
      (prog  +hlinum +ruler +smartparens +rainbow-delimiters +rainbow-identifiers -flymake)
      (nix)
      (zig)
      (lua)
      (quarto +virtual-auto-fill +hlinum)
      (typst-ts +typst-preview +virtual-auto-fill +hlinum)
      (yaml-ts +yaml-pro +hlinum)
      (meson +hlinum +ruler +smartparens +rainbow-delimiters)
      (cmake +hlinum +ruler +smartparens +rainbow-delimiters)
      (tlaplus +hlinum +ruler +smartparens +rainbow-delimiters)
      ;;(typst)

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
