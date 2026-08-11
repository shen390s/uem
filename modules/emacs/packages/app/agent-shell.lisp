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

                 ;;; Container support for agent-shell via ACP
                 ;; Uses shared devbox-container--* infrastructure from emacs.lisp

                 (defun agent-shell-container-claude ()
                   "Start Claude agent-shell session inside a container.
Prompts for auth method and working directory."
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
                           (append
                            (list "docker" "exec" "-i"
                                  "--user" user
                                  "-w" workdir)
                            (mapcan (lambda (pair)
                                      (list "-e" (format "%s=%s" (car pair) (cdr pair))))
                                    env-pairs)
                            (list container "fish" "-lc")))
                          (agent-shell-anthropic-authentication
                           (agent-shell-anthropic-make-authentication :login t))
                          (default-directory workdir)
                          (agent-shell-cwd-function (lambda () workdir)))
                     (agent-shell-anthropic-start-claude-code)))
                 (defalias 'devbox/agent-shell-claude #'agent-shell-container-claude)

                 (defun agent-shell-container-kiro ()
                   "Start Kiro agent-shell session inside a container.
Prompts for working directory."
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
                           (append
                            (list "docker" "exec" "-i"
                                  "--user" user
                                  "-w" workdir)
                            (mapcan (lambda (pair)
                                      (list "-e" (format "%s=%s" (car pair) (cdr pair))))
                                    env-pairs)
                            (list container "fish" "-lc")))
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
