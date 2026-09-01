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
          (setenv "ANTHROPIC_AUTH_TOKEN" "sk-2be8b344294aab78-629fbd-4958adf3")
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
          (with-eval-after-load 'ghostel
            (set-face-attribute 'ghostel-default nil
                                :family "Inconsolata"
                                :height 140) )  ; 
          (set-face-attribute 'fixed-pitch nil
                              :family "Inconsolata"
                              :height 140
                              :weight 'normal)
          (setq straight-vc-git-default-protocol 'ssh)

          ;; Shared devbox container infrastructure for ai-code-interface and agent-shell
          (with-eval-after-load 'ai-code-backends-infra
            (defvar devbox-container-name "devbox-xce"
              "Default Docker container name for running agents.")

            (defvar devbox-container-user "claude"
              "User to run as inside the container.")

            (defvar devbox-container-helper-path "/usr/local/bin/devbox-agent"
              "Absolute path to the devbox-agent helper inside the container.")

            (defvar devbox-container-default-workdir "/home/rshen/projects"
              "Default working directory inside the container.")

            (defvar devbox-container-history nil
              "History for container working directory prompts.")

            (defun devbox-container--ensure-helper (container user)
              "Verify the devbox-agent helper is available in CONTAINER for USER.
The helper is baked into the container image at build time, so this only
checks that it is present and executable."
              (eq 0 (call-process "docker" nil nil nil
                                  "exec" "--user" user container
                                  "test" "-x" devbox-container-helper-path)))

            (defun devbox-container--read-container ()
              "Prompt for a running Docker container name."
              (let* ((containers
                      (split-string
                       (string-trim
                        (shell-command-to-string
                         "docker ps --format '{{.Names}}'"))
                       "\n" t))
                     (default devbox-container-name))
                (completing-read
                 (format "Container [%s]: " default)
                 containers nil nil nil nil default)))

            (defun devbox-container--list-dirs (container user dir &optional depth)
              "List directories inside CONTAINER as USER under DIR up to DEPTH.
The devbox-agent `complete-dirs' command returns paths relative to DIR,
so each is expanded back into an absolute container path."
              (let* ((depth-str (number-to-string (or depth 1)))
                     (dirs-raw
                      (string-trim
                       (shell-command-to-string
                        (format "docker exec --user %s %s %s complete-dirs %s %s 2>/dev/null"
                                (shell-quote-argument user)
                                (shell-quote-argument container)
                                (shell-quote-argument devbox-container-helper-path)
                                (shell-quote-argument dir)
                                depth-str)))))
                (when (not (string-empty-p dirs-raw))
                  (mapcar (lambda (rel)
                            (file-name-as-directory (expand-file-name rel dir)))
                          (split-string dirs-raw "\n" t)))))

            (defun devbox-container--read-workdir (container user)
              "Prompt for working directory inside CONTAINER as USER.
Provides Tab-completion via devbox-agent helper with caching."
              (let ((cache (make-hash-table :test 'equal)))
                (cl-labels
                    ((list-dirs (dir)
                       (or (gethash dir cache)
                           (let ((dirs (devbox-container--list-dirs
                                        container user dir)))
                             (puthash dir dirs cache)
                             dirs))))
                  (completing-read "Container workdir: "
                                   (lambda (input pred action)
                                     (let* ((dir (if (string-suffix-p "/" input)
                                                    input
                                                  (or (file-name-directory input) "/")))
                                            (dirs (list-dirs dir)))
                                       (cond
                                        ((eq action 'metadata)
                                         '(metadata (category . file)))
                                        ((eq action 'lambda)
                                         (member input dirs))
                                        ((eq (car-safe action) 'boundaries)
                                         nil)
                                        (t
                                         (complete-with-action action dirs input pred)))))
                                   nil nil
                                   devbox-container-default-workdir
                                   'devbox-container-history))))

            (defvar devbox-container-session-history nil
              "History for agent session name prompts.")

            (defun devbox-container--list-sessions (container user)
              "List living agent tmux sessions inside CONTAINER as USER.
Returns a list of session names, or nil when there are none."
              (let* ((raw
                      (string-trim
                       (shell-command-to-string
                        (format "docker exec --user %s %s %s list-session 2>/dev/null"
                                (shell-quote-argument user)
                                (shell-quote-argument container)
                                (shell-quote-argument devbox-container-helper-path))))))
                (when (and (not (string-empty-p raw))
                           (not (string-match-p "no agent sessions" raw)))
                  (mapcar (lambda (line)
                            (string-trim (car (split-string line ":"))))
                          (split-string raw "\n" t)))))

            (defun devbox-container--project-name (workdir)
              "Return a short project name for WORKDIR (its basename)."
              (file-name-nondirectory (directory-file-name workdir)))

            (defun devbox-container--next-session-name (sessions base)
              "Return the next unused session name derived from BASE.
Given living SESSIONS, return BASE when unused, otherwise BASE-N for the
smallest N >= 2 that is also unused.  Supports multiple sessions per project."
              (let ((candidate base)
                    (n 2))
                (while (member candidate sessions)
                  (setq candidate (format "%s-%d" base n)
                        n (1+ n)))
                candidate))

            (defun devbox-container--read-session (container user &optional prompt default)
              "Prompt for an agent session name inside CONTAINER as USER.
PROMPT overrides the default prompt.  DEFAULT, when non-nil, is a base name
used as the default and, when already taken, a fresh BASE-N name is also
offered so multiple sessions per project are supported.  When DEFAULT is
nil, the living sessions are offered and the first is the default."
              (let* ((sessions (devbox-container--list-sessions container user))
                     (base (or default (car sessions) "agent"))
                     (candidates
                      (if default
                          (delete-dups
                           (append (list base
                                         (devbox-container--next-session-name
                                          sessions base))
                                   sessions))
                        sessions)))
                (completing-read
                 (or prompt "Session: ")
                 candidates nil nil nil 'devbox-container-session-history
                 base)))))
      /#
      
      :core 
      proxy  ;; put this before core that we can use proxy for straight installation
      straight
      treesit-auto
      
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
      (cjk-edit)
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
      (agent-shell)
      (sly))
