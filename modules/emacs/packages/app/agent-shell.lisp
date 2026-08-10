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
                       (agent-shell-make-environment-variables :inherit-env t)))
     /#
     )
    (otherwise "")))

(feat! agent-shell
       "A native Emacs shell to interact with LLM agents powered by ACP"
       (:app)
       agent-shell-entry)
