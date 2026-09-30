(defun eca-emacs-entry (self action )
  (case action
    ((:INIT) #/(progn
                 (pkginstall '(eca :type git
                                   :host github
                                   :repo "editor-code-assistant/eca-emacs"
                                   :files ("*.el"))))
     /#
     )
    ((:CALL) #/(progn
                 (require 'eca)
                 ;; The eca server binary is auto-downloaded/cached unless
                 ;; `eca-custom-command' is set or `eca' is found on $PATH.
                 (setq eca-chat-window-side 'right))
     /#
     )
    (otherwise "")))

(feat! eca-emacs
       "Editor Code Assistant (ECA) integration for Emacs"
       (:app)
       eca-emacs-entry)
