(defun ai-code-interface-entry (self action)
  (case action
    ((:INIT) #/(progn
                 (pkginstall 'ghostel)
                 (pkginstall '(ai-code-interface :type git
                                                 :host github
                                                 :repo "tninja/ai-code-interface.el"))
                 (setq ai-code-backends-infra-terminal-backend 'ghostel)
                 (with-eval-after-load 'ghostel
                   ;; Force <escape> to send a raw terminal ESC character inside semi-char mode
                   (define-key ghostel-semi-char-mode-map (kbd "<escape>") #'ghostel-send-escape)))
     /#
     )
    ((:CALL) #/(progn
                 (defvar claude-auto-resume-delay 60
                   "Seconds to wait before auto-resuming after usage limit exceeded.")

                 (defvar claude-auto-resume-limit-patterns
                   '("\\(?:hit\\|exceeded\\|reached\\).*\\(?:your\\|the\\)\\s-*\\(?:[0-9]+-hour\\s-+\\)?limit"
                     "[0-9]+-hour limit"
                     "limit reached"
                     "usage limit"
                     "out of.*usage"
                     "rate limit"
                     "try again in")
                   "Patterns to detect usage limit exceeded in terminal output.")

                 (defvar claude-auto-resume-reset-patterns
                   '("resets?\\s-+\\(?:at\\s-+\\)?[0-9]\\{1,2\\}\\(?::[0-9]\\{2\\}\\)?\\s-*\\(?:am\\|pm\\)?"
                     "resets?\\s-+in[: ]\\s-*[0-9]"
                     "try again in [0-9]+\\s-*\\(?:hours?\\|minutes?\\|h\\|m\\)")
                   "Patterns indicating when the limit resets.")

                 (defvar claude-auto-resume--timer nil
                   "Timer for auto-resuming claude after usage limit.")

                 (defvar claude-auto-resume-enabled t
                   "When non-nil, auto-resume claude on usage limit exceeded.")

                 (defvar claude-auto-resume--last-check-pos nil
                   "Last buffer position checked for usage limit pattern.")

                 (defun claude-auto-resume--do-resume (buffer)
                   "Send continue to claude session in BUFFER to resume work."
                   (setq claude-auto-resume--timer nil)
                   (when (buffer-live-p buffer)
                     (message "Auto-resuming claude session...")
                     (with-current-buffer buffer
                       (ai-code-backends-infra--terminal-send-string "continue")
                       (run-at-time 0.5 nil
                                    (lambda ()
                                      (when (buffer-live-p buffer)
                                        (with-current-buffer buffer
                                          (ai-code-backends-infra--terminal-send-return))))))))

                 (defun claude-auto-resume--match-limit-p (start end)
                   "Return non-nil if any limit pattern matches between START and END."
                   (cl-some (lambda (pat)
                              (save-excursion
                                (goto-char start)
                                (re-search-forward pat end t)))
                            claude-auto-resume-limit-patterns))

                 (defun claude-auto-resume--check-output (buffer)
                   "Check BUFFER for usage limit pattern in recent output."
                   (when (and claude-auto-resume-enabled
                              (buffer-live-p buffer)
                              (not claude-auto-resume--timer))
                     (with-current-buffer buffer
                       (let* ((end (point-max))
                              (start (max (point-min)
                                          (or claude-auto-resume--last-check-pos
                                              (- end 2000)))))
                         (setq claude-auto-resume--last-check-pos end)
                         (when (claude-auto-resume--match-limit-p start end)
                           (message "Claude usage limit detected. Auto-resuming in %d seconds..."
                                    claude-auto-resume-delay)
                           (setq claude-auto-resume--timer
                                 (run-at-time claude-auto-resume-delay nil
                                              #'claude-auto-resume--do-resume buffer)))))))

                 (defun claude-auto-resume--on-idle ()
                   "Check all claude session buffers for usage limit on idle."
                   (dolist (buf (buffer-list))
                     (when (string-match-p "\\*claude\\[" (buffer-name buf))
                       (claude-auto-resume--check-output buf))))

                 (run-with-idle-timer 5 t #'claude-auto-resume--on-idle)

                 (defun claude ()
                   "Run claude with subscription or 3rd-party backend."
                   (interactive)
                   (if (y-or-n-p "Use Claude subscription? ")
                       (let ((process-environment
                              (seq-remove (lambda (e)
                                            (string-prefix-p "ANTHROPIC_" e))
                                          process-environment))
                             (ai-code-backend 'claude-code))
                         (ai-code-claude-code))
                     (let ((ai-code-backend 'claude-code))
                       (ai-code-claude-code)))))
     /#
     )
    (otherwise "")))

(feat! ai-code-interface
       "ai code interface for emacs"
       (:app)
       ai-code-interface-entry)
