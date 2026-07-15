(sys! emacs
      :init 
      #/(progn
          (defun get-chinese-font-size ()
            (let ((width (display-pixel-width)))
              (if (>= width 3840)
                  20
                16)))

          (defun my/set-fonts ()
            (dolist (charset '(kana han cjk-misc bopomofo))
              (set-fontset-font t charset (font-spec :family "LXGW WenKai Mono" :size (get-chinese-font-size)))))

          (add-hook 'after-make-frame-functions
                    (lambda (frame)
                      (with-selected-frame frame
                        (when (display-graphic-p)
                          (my/set-fonts)))))
          (add-hook 'after-init-hook
                    (lambda ()
                      (when (display-graphic-p)
                        (my/set-fonts))))
          
	      (setq emacs-config-dir "~/.config/emacs/uem")
          (setenv "ANTHROPIC_BASE_URL" "http://omniroute.#.(get-hostname).overlay:20128")
          (setenv "ANTHROPIC_AUTH_TOKEN" "sk-b068da137c424285-4056f0-962bdecb")
          (with-eval-after-load 'treesit
            (add-to-list 'treesit-language-source-alist
                         '(tlaplus "https://github.com/tlaplus-community/tree-sitter-tlaplus"))
            (add-to-list 'treesit-language-source-alist
                         '(peg "https://github.com/shen390s/tree-sitter-peg"))
            (add-to-list 'treesit-extra-load-path
                         (expand-file-name "straight/build/tree-sitter-langs/bin" user-emacs-directory))
            (setq treesit-load-name-override-list
                  '((cpp "cpp.so" "tree_sitter_cpp")
                    (c "c.so" "tree_sitter_c")
                    (python "python.so" "tree_sitter_python")
                    (bash "bash.so" "tree_sitter_bash")
                    (cmake "cmake.so" "tree_sitter_cmake"))))
          (with-eval-after-load 'tree-sitter-langs
            (tree-sitter-langs--init-load-path))
	      (unless (file-exists-p emacs-config-dir)
	        (make-directory emacs-config-dir t))
	      (setq custom-file (concat emacs-config-dir "/custom.el"))
	      (setq custom-safe-themes t)
	      (setq-default indent-tabs-mode nil)
	      (setq-default tab-width 4)
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
                 ("c-ts-mode" ".c" ".cpp" ".cc" ".h" ".hpp" ".cxx")
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
                 ("tlaplus-ts-mode" ".tla" ".tla+")
                 ("peg-ts-mode" ".peg" ".leg")
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
      (tlaplus-ts +hlinum +ruler +smartparens +rainbow-delimiters)
      (peg-ts)
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
      ;;(claude-code)
      (ai-code-interface)
      (sly))
