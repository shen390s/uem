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
                 (require 'ghostel)
                 (require 'ai-code-backends-infra-ghostel)
                 (require 'ai-code-claude-code)
                 (defvar claude-auto-resume-delay 60
                   "Fallback seconds to wait when reset time cannot be parsed from output.")

                 (defvar claude-auto-resume-max-delay (* 6 60 60)
                   "Maximum seconds to wait before giving up on auto-resume (default 6 hours).
If parsed delay exceeds this, fall back to `claude-auto-resume-delay'.")

                 (defvar claude-auto-resume-margin-seconds 60
                   "Extra seconds to add past the parsed reset time before resuming.")

                 (defvar claude-auto-resume-limit-patterns
                   '("\\(?:hit\\|exceeded\\|reached\\).*\\(?:your\\|the\\)\\s-*\\(?:[0-9]+-hour\\s-+\\)?limit"
                     "[0-9]+-hour limit"
                     "limit reached"
                     "usage limit"
                     "out of.*usage"
                     "rate limit"
                     "try again in")
                   "Patterns to detect usage limit exceeded in terminal output.")

                 (defvar claude-auto-resume-time-patterns
                   '(;; "Your limit will reset at 2pm (America/New_York)"
                     ;; "Your limit will reset at 2:30pm"
                     "reset\\(?:s\\)?\\s-+at\\s-+\\([0-9]\\{1,2\\}\\)\\(?::\\([0-9]\\{2\\}\\)\\)?\\s-*\\([ap]m\\)"
                     ;; "resets 2pm (UTC)"
                     "resets\\s-+\\([0-9]\\{1,2\\}\\)\\(?::\\([0-9]\\{2\\}\\)\\)?\\s-*\\([ap]m\\)")
                   "Patterns that capture absolute reset times.
Group 1 = hour, group 2 = minute (optional), group 3 = am/pm.")

                 (defvar claude-auto-resume-relative-time-patterns
                   '(;; "try again in 3 hours" / "resets in 42 minutes" / "resets in 3h 42m"
                     "\\(?:try again\\|resets?\\)\\s-+in\\s-+\\([0-9]+\\)\\s-*\\(hours?\\|h\\)\\(?:\\s-+\\([0-9]+\\)\\s-*\\(minutes?\\|m\\)\\)?"
                     "\\(?:try again\\|resets?\\)\\s-+in\\s-+\\([0-9]+\\)\\s-*\\(minutes?\\|m\\)")
                   "Patterns that capture relative reset durations.
First pattern: hours (+ optional minutes). Second pattern: minutes only.")

                 (defvar claude-auto-resume--timer nil
                   "Timer for auto-resuming claude after usage limit.")

                 (defvar claude-auto-resume-enabled t
                   "When non-nil, auto-resume claude on usage limit exceeded.")

                 (defvar claude-auto-resume--last-check-pos nil
                   "Last buffer position checked for usage limit pattern.")

                 (defun claude-auto-resume--parse-absolute-time (start end)
                   "Try to parse an absolute reset time from region START to END.
Returns seconds-from-now, or nil if no time pattern found."
                   (catch 'found
                     (dolist (pat claude-auto-resume-time-patterns)
                       (save-excursion
                         (goto-char start)
                         (when (re-search-forward pat end t)
                           (let* ((hour (string-to-number (match-string 1)))
                                  (minute (if (match-string 2)
                                              (string-to-number (match-string 2))
                                            0))
                                  (ampm (match-string 3))
                                  (h (cond
                                      ((and ampm (string-equal (downcase ampm) "pm")
                                            (< hour 12))
                                       (+ hour 12))
                                      ((and ampm (string-equal (downcase ampm) "am")
                                            (= hour 12))
                                       0)
                                      (t hour)))
                                  (now (decode-time))
                                  (target (encode-time 0 minute h
                                                       (decoded-time-day now)
                                                       (decoded-time-month now)
                                                       (decoded-time-year now)
                                                       (decoded-time-zone now))))
                             ;; If it already passed today, assume tomorrow
                             (when (time-less-p target (current-time))
                               (setq target (time-add target (* 24 60 60))))
                             (throw 'found
                                    (round (float-time
                                            (time-subtract target (current-time)))))))))
                     nil))

                 (defun claude-auto-resume--parse-relative-time (start end)
                   "Try to parse a relative reset duration from region START to END.
Returns seconds-from-now, or nil if no relative time pattern found."
                   (catch 'found
                     (dolist (pat claude-auto-resume-relative-time-patterns)
                       (save-excursion
                         (goto-char start)
                         (when (re-search-forward pat end t)
                           (let ((n1 (string-to-number (match-string 1)))
                                 (unit1 (match-string 2))
                                 (n2 (and (match-string 3)
                                          (string-to-number (match-string 3)))))
                             (throw 'found
                                    (+ (if (string-match-p "\\`[hH]" unit1)
                                           (* n1 3600)
                                         (* n1 60))
                                       (if n2 (* n2 60) 0)))))))
                     nil))

                 (defun claude-auto-resume--compute-delay (start end)
                   "Compute wait seconds from parsed reset time in region START to END.
Tries absolute time first, then relative duration, then falls back
to `claude-auto-resume-delay'.  Adds `claude-auto-resume-margin-seconds'
margin and caps at `claude-auto-resume-max-delay'."
                   (let ((parsed (or (claude-auto-resume--parse-absolute-time start end)
                                     (claude-auto-resume--parse-relative-time start end))))
                     (if (and parsed (> parsed 0) (<= parsed claude-auto-resume-max-delay))
                         (+ parsed claude-auto-resume-margin-seconds)
                       claude-auto-resume-delay)))

                 (defun claude-auto-resume--do-resume (buf)
                   "Send continue to claude session in BUF to resume work."
                   (setq claude-auto-resume--timer nil)
                   (when (buffer-live-p buf)
                     (message "Auto-resuming claude session...")
                     (with-current-buffer buf
                       (ai-code-backends-infra--terminal-send-string "continue")
                       (let ((b buf))
                         (run-at-time 0.5 nil
                                      `(lambda ()
                                         (when (buffer-live-p ,b)
                                           (with-current-buffer ,b
                                             (ai-code-backends-infra--terminal-send-return)))))))))

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
                              (start (max (point-min) (- end 2000))))
                         (when (claude-auto-resume--match-limit-p start end)
                           (let* ((delay (claude-auto-resume--compute-delay start end))
                                  (resume-time (time-add (current-time) delay)))
                             (message "[claude-auto-resume] Limit detected. Resuming at %s (in %dm %ds)"
                                      (format-time-string "%H:%M:%S" resume-time)
                                      (/ delay 60) (mod delay 60))
                             (setq claude-auto-resume--timer
                                   (run-at-time delay nil
                                                #'claude-auto-resume--do-resume buffer))))))))

                 (defun claude-auto-resume--on-idle ()
                   "Check all claude session buffers for usage limit on idle."
                   (dolist (buf (buffer-list))
                     (when (string-match-p "\\*claude\\[" (buffer-name buf))
                       (claude-auto-resume--check-output buf))))

                 (run-with-idle-timer 5 t #'claude-auto-resume--on-idle)

                 (defun claude ()
                   "Run claude with subscription or 3rd-party backend."
                   (interactive)
                   (let ((ai-code-backend 'claude-code)
                         (ai-code-claude-code-program-switches
                          (if (y-or-n-p "Enable --dangerously-skip-permissions? ")
                              (append ai-code-claude-code-program-switches
                                      '("--dangerously-skip-permissions"))
                            ai-code-claude-code-program-switches)))
                     (if (y-or-n-p "Use Claude subscription? ")
                         (let ((process-environment
                                (seq-remove (lambda (e)
                                              (string-prefix-p "ANTHROPIC_" e))
                                            process-environment)))
                           (ai-code-claude-code))
                       (ai-code-claude-code)))))
     /#
     )
    (otherwise "")))

(feat! ai-code-interface
       "ai code interface for emacs"
       (:app)
       ai-code-interface-entry)
