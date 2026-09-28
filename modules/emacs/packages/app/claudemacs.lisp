(defun claudemacs-entry (self action)
  (case action
    ((:INIT) #/(progn
                 (pkginstall 'ghostel)
                 (pkginstall '(claudemacs :type git
                                          :host github
                                          :repo "cpoile/claudemacs")))
     /#
     )
    ((:CALL) #/(progn
                 (require 'claudemacs)
                 ;; Ghostel is installed above and auto-selected when available.
                 (setq claudemacs-terminal-backend 'ghostel)

                 ;; Transient menu on C-c C-e in the common editing maps.
                 (with-eval-after-load 'prog-mode
                   (define-key prog-mode-map (kbd "C-c C-e")
                               #'claudemacs-transient-menu))
                 (define-key emacs-lisp-mode-map (kbd "C-c C-e")
                             #'claudemacs-transient-menu)
                 (with-eval-after-load 'text-mode
                   (define-key text-mode-map (kbd "C-c C-e")
                               #'claudemacs-transient-menu))

                 ;; Claude edits and saves files on disk; keep buffers in sync.
                 (global-auto-revert-mode t)

                 ;;; Container support for claudemacs (local/remote host)
                 ;; Runs Claude Code inside a Docker container as a persistent
                 ;; tmux session, driving Claudemacs' own terminal backend
                 ;; (ghostel/eat) so all of its session/action commands keep
                 ;; working.  Reuses the shared devbox-container--* infrastructure
                 ;; provided by the `devbox' feature (host/container/workdir/session
                 ;; prompts, tmux session lifecycle via the in-container
                 ;; devbox-agent helper).

                 (defun claudemacs-container--env-argv (env-pairs)
                   "Return `-e KEY=VALUE' docker options for ENV-PAIRS."
                   (mapcan (lambda (pair)
                             (list "-e" (format "%s=%s" (car pair) (cdr pair))))
                           env-pairs))

                 (defun claudemacs-container--start (container user argv label)
                   "Start a Claudemacs session running docker ARGV in CONTAINER as USER.
LABEL is unused display sugar kept for symmetry with the other agent
launchers.  The whole `docker ...' command line is handed to Claudemacs as a
one-off `claude-container' tool so Claudemacs spawns it in its own terminal
backend and every session/action command continues to work.  A real local
directory is used as the working directory because Claudemacs `cd's into it
for the local `docker' process; the container-side working directory is set
with `-w' inside ARGV."
                   (ignore label)
                   (let* ((docker-argv
                           (append (cdr (devbox-container--docker-argv)) argv))
                          ;; One-off registry entry: program is `docker', and the
                          ;; full `exec ...' argv are the switches.  Using a tool
                          ;; name other than `claude' avoids Claudemacs' automatic
                          ;; `--session-id' injection (the tmux session provides
                          ;; persistence instead).
                          (claudemacs-tool-registry
                           (cons (list 'claude-container
                                       :program "docker"
                                       :switches docker-argv)
                                 claudemacs-tool-registry))
                          (claudemacs-program-switches nil)
                          (default-directory (expand-file-name "~/")))
                     (claudemacs--start default-directory 'claude-container)))

                 (defun claudemacs/list-sessions ()
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

                 (defun claudemacs/agent-detach ()
                   "Detach an agent tmux session in a container, leaving it running."
                   (interactive)
                   (let* ((container (devbox-container--read-container))
                          (user devbox-container-user)
                          (session (devbox-container--read-session
                                    container user "Detach session: ")))
                     (ignore-errors
                       (devbox-container--docker-call
                        "exec" "--user" user container
                        devbox-container-helper-path "detach" session))))

                 (defun claudemacs-container ()
                   "Run Claude Code inside a Docker container as a Claudemacs session.
Prompts for a remote host (empty for local), a running container, and a tmux
session.  Offers the living sessions plus a \"new session\" item; only a brand
new session prompts for working directory, auth method, and permission flags.
Existing sessions are reattached directly.  The session is displayed and
driven through Claudemacs' terminal backend, so all Claudemacs session and
action commands work against it."
                   (interactive)
                   (let* ((container (devbox-container--read-container))
                          (user devbox-container-user)
                          (_ensure (devbox-container--ensure-helper container user))
                          (selection (devbox-container--select-session
                                      container user "Claude session: "))
                          (new-session (eq selection 'new))
                          (workdir (when new-session
                                     (devbox-container--read-workdir container user)))
                          (session (if new-session
                                       (devbox-container--read-new-session
                                        container user
                                        (format "claude-%s"
                                                (devbox-container--project-name workdir))
                                        "New Claude session name: ")
                                     selection))
                          ;; Only a brand-new session launches the CLI, so only
                          ;; then do the auth method and permission flags matter.
                          (use-subscription
                           (and new-session (y-or-n-p "Use Claude subscription? ")))
                          (skip-perms
                           (and new-session
                                (y-or-n-p "Enable --dangerously-skip-permissions? ")))
                          (env-pairs
                           (when new-session
                             (if use-subscription
                                 '(("ANTHROPIC_API_KEY" . "")
                                   ("ANTHROPIC_BASE_URL" . "")
                                   ("ANTHROPIC_AUTH_TOKEN" . ""))
                               (let ((pairs nil))
                                 (when (getenv "ANTHROPIC_AUTH_TOKEN")
                                   (push (cons "ANTHROPIC_AUTH_TOKEN" (getenv "ANTHROPIC_AUTH_TOKEN")) pairs))
                                 (when (getenv "ANTHROPIC_BASE_URL")
                                   (push (cons "ANTHROPIC_BASE_URL" (getenv "ANTHROPIC_BASE_URL")) pairs))
                                 pairs))))
                          (args (when skip-perms '("--dangerously-skip-permissions")))
                          (argv
                           (append
                            (list "exec" "-it" "--user" user)
                            (when new-session (list "-w" workdir))
                            (claudemacs-container--env-argv env-pairs)
                            (list container devbox-container-helper-path "run"
                                  "-s" session "-c" "claude" "--")
                            args)))
                     (claudemacs-container--start container user argv "Claude Code")))
                 (defalias 'devbox/claudemacs #'claudemacs-container)

                 ;; Quick keybinding for a containerized session in the common
                 ;; editing maps, alongside the C-c C-e transient menu.
                 (with-eval-after-load 'prog-mode
                   (define-key prog-mode-map (kbd "C-c C-a")
                               #'claudemacs-container))
                 (define-key emacs-lisp-mode-map (kbd "C-c C-a")
                             #'claudemacs-container)
                 (with-eval-after-load 'text-mode
                   (define-key text-mode-map (kbd "C-c C-a")
                               #'claudemacs-container))

                 ;; Add a "Container" group to the Claudemacs transient menu.
                 ;; Appending at top-level coordinate (0) makes it a sibling
                 ;; group after the main title/columns block (groups and suffixes
                 ;; cannot be siblings, so it must be inserted at the group level).
                 (with-eval-after-load 'transient
                   (transient-append-suffix 'claudemacs-transient-menu
                     '(0)
                     ["Container (local/remote host)"
                      ("C" "Start/Attach Container Session" claudemacs-container)
                      ("L" "List Container Sessions" claudemacs/list-sessions)
                      ("D" "Detach Container Session" claudemacs/agent-detach)])))
     /#
     )
    (otherwise "")))

(feat! claudemacs
       "AI pair programming with Claude Code/Codex in Emacs"
       (:app)
       claudemacs-entry)
