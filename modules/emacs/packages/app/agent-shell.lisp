(defun agent-shell-entry (self action)
  (case action
    ((:INIT) #/(progn
                 (pkginstall 'shell-maker)
                 (pkginstall 'acp)
                 (pkginstall 'agent-shell))
     /#
     )
    ((:CALL) #/(progn
                 (require 'acp)
                 (require 'agent-shell)
                 (setq agent-shell-anthropic-claude-environment
                       (agent-shell-make-environment-variables :inherit-env t))
                 (setq agent-shell-anthropic-authentication
                       (agent-shell-anthropic-make-authentication :login t))
                 (setq agent-shell-kiro-environment
                       (agent-shell-make-environment-variables :inherit-env t))
                 (setq agent-shell-show-session-id t)

                 ;; Give an agent-shell session the whole frame when displayed.
                 ;; agent-shell displays via `agent-shell--display-buffer', which
                 ;; passes `agent-shell-display-action' as the explicit ACTION to
                 ;; `display-buffer'.  The default is `display-buffer-same-window'
                 ;; (leaves other windows split), so set the action itself to a
                 ;; full-frame action rather than relying on `display-buffer-alist'
                 ;; (which an explicit ACTION overrides).
                 (setq agent-shell-display-action
                       '((display-buffer-full-frame)))

                 ;;; Container support for agent-shell via ACP
                 ;; Uses shared devbox-container--* infrastructure from the devbox feature

                 (defun devbox-container--acp-prefix (container user workdir env-pairs)
                   "Return an `agent-shell-command-prefix' to run ACP agents in CONTAINER.
The agent runs as USER with WORKDIR; ENV-PAIRS are passed through as
`-e KEY=VALUE' options to `docker exec'.  The login fish config is sourced
to set up the full environment (PATH, GOPROXY, CARGO_ROOT, ...), but its
stdout/stderr is discarded so the ACP stdio stream stays clean."
                   (append
                    (devbox-container--docker-argv
                     "exec" "-i" "--user" user "-w" workdir)
                    (mapcan (lambda (pair)
                              (list "-e" (format "%s=%s" (car pair) (cdr pair))))
                            env-pairs)
                    (list container "fish" "--no-config" "-c"
                          "source ~/.config/fish/config.fish >/dev/null 2>&1; exec $argv")))

                 (defun devbox/list-sessions ()
                   "List living agent tmux sessions in a container."
                   (interactive)
                   (let* ((container (devbox-container--read-container))
                          (user devbox-container-user)
                          (raw (shell-command-to-string
                                (format "%s 2>&1"
                                        (devbox-container--docker-string
                                         "exec" "--user" user container
                                         devbox-container-helper-path "list-session")))))
                     (with-current-buffer (get-buffer-create "*devbox-agent-sessions*")
                       (let ((inhibit-read-only t))
                         (erase-buffer)
                         (insert raw))
                       (special-mode)
                       (display-buffer (current-buffer)))))

                 (defun devbox/agent-shell-resume ()
                   "Resume an existing ACP agent session inside a container.
Prompts for container, working directory, and session ID, then reconnects
via `agent-shell-resume-session' using the container command prefix."
                   (interactive)
                   (let* ((container (devbox-container--read-container))
                          (user devbox-container-user)
                          (_ensure (devbox-container--ensure-helper container user))
                          (workdir (devbox-container--read-workdir container user))
                          (env-pairs
                           (let ((pairs nil))
                             (when (getenv "ANTHROPIC_AUTH_TOKEN")
                               (push (cons "ANTHROPIC_API_KEY" (getenv "ANTHROPIC_AUTH_TOKEN")) pairs)
                               (push (cons "ANTHROPIC_AUTH_TOKEN" (getenv "ANTHROPIC_AUTH_TOKEN")) pairs))
                             (when (getenv "ANTHROPIC_BASE_URL")
                               (push (cons "ANTHROPIC_BASE_URL" (getenv "ANTHROPIC_BASE_URL")) pairs))
                             (when (getenv "KIRO_API_KEY")
                               (push (cons "KIRO_API_KEY" (getenv "KIRO_API_KEY")) pairs))
                             pairs)))
                     (let ((agent-shell-command-prefix
                            (devbox-container--acp-prefix container user workdir env-pairs))
                           (default-directory workdir)
                           (agent-shell-cwd-function (lambda () workdir)))
                       (call-interactively #'agent-shell-resume-session))))

                 (defun agent-shell-container-claude ()
                   "Start Claude agent-shell session inside a container.
Prompts for auth method and working directory.  The ACP session is
persisted by Claude, so killing the buffer disconnects the client while
the session stays resumable via `devbox/agent-shell-resume'."
                   (interactive)
                   (require 'agent-shell-anthropic)
                   (let* ((container (devbox-container--read-container))
                          (user devbox-container-user)
                          (_ensure (devbox-container--ensure-helper container user))
                          (use-subscription (y-or-n-p "Use Claude subscription? "))
                          (workdir (devbox-container--read-workdir container user))
                          (env-pairs
                           (if use-subscription
                               '(("ANTHROPIC_API_KEY" . "")
                                 ("ANTHROPIC_BASE_URL" . "")
                                 ("ANTHROPIC_AUTH_TOKEN" . "")
                                 ("CLAUDE_CODE_EXECUTABLE" . "/home/claude/.nix-profile/bin/claude"))
                             (let ((pairs (list (cons "CLAUDE_CODE_EXECUTABLE"
                                                     "/home/claude/.nix-profile/bin/claude"))))
                               (when (getenv "ANTHROPIC_AUTH_TOKEN")
                                 (push (cons "ANTHROPIC_API_KEY" (getenv "ANTHROPIC_AUTH_TOKEN")) pairs)
                                 (push (cons "ANTHROPIC_AUTH_TOKEN" (getenv "ANTHROPIC_AUTH_TOKEN")) pairs))
                               (when (getenv "ANTHROPIC_BASE_URL")
                                 (push (cons "ANTHROPIC_BASE_URL" (getenv "ANTHROPIC_BASE_URL")) pairs))
                               pairs)))
                          (agent-shell-command-prefix
                           (devbox-container--acp-prefix container user workdir env-pairs))
                          (agent-shell-anthropic-authentication
                           (agent-shell-anthropic-make-authentication :login t))
                          (default-directory workdir)
                          (agent-shell-cwd-function (lambda () workdir)))
                     (agent-shell-anthropic-start-claude-code)))
                 (defalias 'devbox/agent-shell-claude #'agent-shell-container-claude)

                 (defun agent-shell-container-kiro ()
                   "Start Kiro agent-shell session inside a container.
Prompts for working directory.  The ACP session is persisted by Kiro,
so killing the buffer disconnects the client while the session stays
resumable via `devbox/agent-shell-resume'."
                   (interactive)
                   (require 'agent-shell-kiro)
                   (let* ((container (devbox-container--read-container))
                          (user devbox-container-user)
                          (_ensure (devbox-container--ensure-helper container user))
                          (workdir (devbox-container--read-workdir container user))
                          (env-pairs
                           (let ((pairs nil))
                             (when (getenv "KIRO_API_KEY")
                               (push (cons "KIRO_API_KEY" (getenv "KIRO_API_KEY")) pairs))
                             (when (getenv "ANTHROPIC_BASE_URL")
                               (push (cons "ANTHROPIC_BASE_URL" (getenv "ANTHROPIC_BASE_URL")) pairs))
                             (when (getenv "ANTHROPIC_AUTH_TOKEN")
                               (push (cons "ANTHROPIC_AUTH_TOKEN" (getenv "ANTHROPIC_AUTH_TOKEN")) pairs))
                             pairs))
                          (agent-shell-command-prefix
                           (devbox-container--acp-prefix container user workdir env-pairs))
                          (default-directory workdir)
                          (agent-shell-cwd-function (lambda () workdir)))
                     (agent-shell-kiro-start-agent)))
                 (defalias 'devbox/agent-shell-kiro #'agent-shell-container-kiro))
     /#
     )
    (otherwise "")))

(feat! agent-shell
       "A native Emacs shell to interact with LLM agents powered by ACP"
       (:app)
       agent-shell-entry)
