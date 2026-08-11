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
          (with-eval-after-load 'ghostel
            (set-face-attribute 'ghostel-default nil
                                :family "Inconsolata"
                                :height 140) )  ; 
          (setq straight-vc-git-default-protocol 'ssh)

          ;; Shared devbox container infrastructure for ai-code-interface and agent-shell
          (with-eval-after-load 'ai-code-backends-infra
            (defvar devbox-container-name "devbox-xce"
              "Default Docker container name for running agents.")

            (defvar devbox-container-user "claude"
              "User to run as inside the container.")

            (defvar devbox-container-helper-path "/home/claude/.local/bin/devbox-agent"
              "Absolute path to the helper inside the container.")

            (defvar devbox-container-default-workdir "/home/claude/works"
              "Default working directory inside the container.")

            (defvar devbox-container-history nil
              "History for container working directory prompts.")

            (defvar devbox-container--helper-script
              "#!/usr/bin/env bash
set -euo pipefail
cmd=\"${1:-help}\"
shift || true
case \"$cmd\" in
  run)
    program=\"${1:-claude}\"
    shift || true
    export PATH=\"$HOME/.nix-profile/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH\"
    case \"$program\" in
      claude) exec claude \"$@\" ;;
      kiro) exec kiro-cli chat \"$@\" ;;
      *) echo \"Unknown: $program\" >&2; exit 1 ;;
    esac
    ;;
  complete-dirs)
    dir=\"${1:-/}\"
    depth=\"${2:-1}\"
    find \"$dir\" -maxdepth \"$depth\" -type d 2>/dev/null | while IFS= read -r d; do
      printf '%s/\\n' \"${d%/}\"
    done
    ;;
  info)
    export PATH=\"$HOME/.nix-profile/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH\"
    echo \"devbox-agent\"
    echo \"user: $(whoami)\"
    echo \"claude: $(which claude 2>/dev/null || echo 'not found')\"
    echo \"kiro-cli: $(which kiro-cli 2>/dev/null || echo 'not found')\"
    ;;
  *) echo \"Usage: devbox-agent run claude|kiro | complete-dirs DIR [DEPTH] | info\" >&2 ;;
esac
"
              "Content of the devbox-agent helper script.")

            (defvar devbox-container--helper-injected (make-hash-table :test 'equal)
              "Track which containers already have the helper injected this session.")

            (defun devbox-container--ensure-helper (container user)
              "Ensure devbox-agent helper is installed in CONTAINER for USER."
              (unless (gethash container devbox-container--helper-injected)
                (let ((helper-dir (file-name-directory devbox-container-helper-path)))
                  (call-process "docker" nil nil nil
                                "exec" "--user" user container
                                "mkdir" "-p" helper-dir)
                  (let ((proc (start-process "devbox-agent-inject" nil
                                             "docker" "exec" "-i"
                                             "--user" user container
                                             "tee" devbox-container-helper-path)))
                    (process-send-string proc devbox-container--helper-script)
                    (process-send-eof proc)
                    (while (process-live-p proc)
                      (sleep-for 0.05)))
                  (call-process "docker" nil nil nil
                                "exec" "--user" user container
                                "chmod" "+x" devbox-container-helper-path)
                  (puthash container t devbox-container--helper-injected))))

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
              "List directories inside CONTAINER as USER under DIR up to DEPTH."
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
                  (split-string dirs-raw "\n" t))))

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
                                   'devbox-container-history))))))
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
