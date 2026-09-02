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
                   (define-key ghostel-semi-char-mode-map (kbd "<escape>") #'ghostel-send-escape))
                 ;; Fix ai-code-backends-infra-ghostel advice for ghostel v0.49+ API
                 ;; ghostel--schedule-link-detection no longer takes (begin end) args;
                 ;; it reads ghostel--repainted-region internally.
                 (with-eval-after-load 'ai-code-backends-infra-ghostel
                   (defun ai-code-backends-infra-ghostel--around-schedule-link-detection
                       (orig-fn &rest _args)
                     "Call ORIG-FN after restoring links before a redraw scan."
                     (let ((region (and (boundp 'ghostel--repainted-region)
                                        ghostel--repainted-region)))
                       (when region
                         (ai-code-backends-infra-ghostel--restore-preserved-link-spans
                          (car region) (cdr region))))
                     (funcall orig-fn))
                   (defun ai-code-backends-infra-ghostel--around-run-queued-link-detection
                       (orig-fn buffer)
                     "Call ORIG-FN for BUFFER and cache Ghostel link spans afterward."
                     (condition-case nil
                         (let (begin end)
                           (when (buffer-live-p buffer)
                             (with-current-buffer buffer
                               (when (ai-code-backends-infra-ghostel--ai-session-buffer-p)
                                 (setq begin ghostel--plain-link-detection-begin
                                       end ghostel--plain-link-detection-end))))
                           (prog1 (funcall orig-fn buffer)
                             (when (and (buffer-live-p buffer)
                                        (markerp begin) (markerp end)
                                        (marker-buffer begin) (marker-buffer end)
                                        (marker-position begin) (marker-position end))
                               (with-current-buffer buffer
                                 (ai-code-backends-infra-ghostel--cache-preserved-link-spans
                                  begin end)))))
                       (error (funcall orig-fn buffer))))))
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
                       (ai-code-claude-code))))

                 ;;; Container support for claude code / kiro-cli
                 ;; Uses shared devbox-container--* infrastructure from the devbox feature

                 (defvar devbox-container-session-name nil
                   "Buffer-local tmux session name for the current agent session.")
                 (defvar devbox-container-session-container nil
                   "Buffer-local container for the current agent session.")
                 (defvar devbox-container-session-user nil
                   "Buffer-local container user for the current agent session.")
                 (make-variable-buffer-local 'devbox-container-session-name)
                 (make-variable-buffer-local 'devbox-container-session-container)
                 (make-variable-buffer-local 'devbox-container-session-user)

                 (defun devbox-container--detach-session (container user session)
                   "Detach tmux SESSION in CONTAINER as USER, leaving it running."
                   (ignore-errors
                     (devbox-container--docker-call
                      "exec" "--user" user container
                      devbox-container-helper-path "detach" session)))

                 (defun devbox-container--detach-current-session ()
                   "Detach the tmux session recorded on the current buffer."
                   (when (and devbox-container-session-name
                              devbox-container-session-container
                              devbox-container-session-user)
                     (devbox-container--detach-session
                      devbox-container-session-container
                      devbox-container-session-user
                      devbox-container-session-name)))

                 (defun devbox-container--prepare-session-buffer (container user session)
                   "Configure the current buffer for a devbox tmux SESSION.
The session lives in CONTAINER as USER.  Sets buffer-local session metadata
and installs a kill-buffer-hook that detaches (leaving the session running)
rather than killing it when the buffer is closed."
                   (if (eq ai-code-backends-infra-terminal-backend 'vterm)
                       (setq-local ai-code-backends-infra-strip-alternate-screen t)
                     (setq-local ai-code-backends-infra-strip-alternate-screen nil))
                   (when (eq ai-code-backends-infra-terminal-backend 'ghostel)
                     (setq-local ghostel-full-redraw t))
                   (setq-local devbox-container-session-name session)
                   (setq-local devbox-container-session-container container)
                   (setq-local devbox-container-session-user user)
                   (add-hook 'kill-buffer-hook
                             #'devbox-container--detach-current-session nil t))

                 (defun devbox-container--start-terminal (container user argv session label)
                   "Start a terminal for CONTAINER/USER running ARGV, attaching tmux SESSION.
LABEL is the user-facing session label."
                   (let ((post-start-fn
                          (lambda (buffer _process _instance)
                            (with-current-buffer buffer
                              (devbox-container--prepare-session-buffer
                               container user session)))))
                     (ai-code-backends-infra--start-cli-session
                      (list :program "docker"
                            :switches (append devbox-container-docker-args argv)
                            :label label
                            :process-table ai-code-claude-code--processes
                            :session-prefix ai-code-claude-code--session-prefix
                            :escape-function #'ai-code-claude-code-send-escape
                            :env-vars (list "TERM_PROGRAM=emacs"
                                            "FORCE_CODE_TERMINAL=true")
                            :multiline-input-sequence
                            ai-code-claude-code-multiline-input-sequence
                            :prepare-launch
                            (lambda (_wd _argv)
                              (list :post-start-fn post-start-fn)))
                      nil)))

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

                 (defun devbox/agent-attach ()
                   "Attach to a living agent tmux session in a container."
                   (interactive)
                   (let* ((container (devbox-container--read-container))
                          (user devbox-container-user)
                          (_ensure (devbox-container--ensure-helper container user))
                          (session (devbox-container--read-session
                                    container user "Attach session: "))
                          (argv (list "exec" "-it" "--user" user container
                                      devbox-container-helper-path "attach" session)))
                     (devbox-container--start-terminal
                      container user argv session "Agent")))

                 (defun devbox/agent-detach ()
                   "Detach an agent tmux session in a container, leaving it running."
                   (interactive)
                   (let* ((container (devbox-container--read-container))
                          (user devbox-container-user)
                          (session (devbox-container--read-session
                                    container user "Detach session: ")))
                     (devbox-container--detach-session container user session)))

                 (defun claude-container ()
                   "Run Claude Code inside a Docker container as a tmux session.
Prompts for container, auth method, working directory, and permissions."
                   (interactive)
                   (let* ((container (devbox-container--read-container))
                          (user devbox-container-user)
                          (_ensure (devbox-container--ensure-helper container user))
                          (use-subscription (y-or-n-p "Use Claude subscription? "))
                          (skip-perms (y-or-n-p "Enable --dangerously-skip-permissions? "))
                          (workdir (devbox-container--read-workdir container user))
                          (session (devbox-container--read-session
                                    container user "Claude session: "
                                    (format "claude-%s"
                                            (devbox-container--project-name workdir))))
                          (env-pairs
                           (if use-subscription
                               '(("ANTHROPIC_API_KEY" . "")
                                 ("ANTHROPIC_BASE_URL" . "")
                                 ("ANTHROPIC_AUTH_TOKEN" . ""))
                             (let ((pairs nil))
                               (when (getenv "ANTHROPIC_AUTH_TOKEN")
                                 (push (cons "ANTHROPIC_AUTH_TOKEN" (getenv "ANTHROPIC_AUTH_TOKEN")) pairs))
                               (when (getenv "ANTHROPIC_BASE_URL")
                                 (push (cons "ANTHROPIC_BASE_URL" (getenv "ANTHROPIC_BASE_URL")) pairs))
                               pairs)))
                          (args (when skip-perms '("--dangerously-skip-permissions")))
                          (argv
                           (append
                            (list "exec" "-it"
                                  "--user" user
                                  "-w" workdir)
                            (mapcan (lambda (pair)
                                      (list "-e" (format "%s=%s" (car pair) (cdr pair))))
                                    env-pairs)
                            (list container devbox-container-helper-path "run"
                                  "-s" session "-c" "claude" "--")
                            args)))
                     (devbox-container--start-terminal
                      container user argv session "Claude Code")))
                 (defalias 'devbox/claude #'claude-container)

                 (defun kiro-container ()
                   "Run kiro-cli inside a Docker container as a tmux session.
Prompts for container and working directory."
                   (interactive)
                   (let* ((container (devbox-container--read-container))
                          (user devbox-container-user)
                          (_ensure (devbox-container--ensure-helper container user))
                          (workdir (devbox-container--read-workdir container user))
                          (session (devbox-container--read-session
                                    container user "Kiro session: "
                                    (format "kiro-%s"
                                            (devbox-container--project-name workdir))))
                          (env-pairs
                           (let ((pairs nil))
                             (when (getenv "KIRO_API_KEY")
                               (push (cons "KIRO_API_KEY" (getenv "KIRO_API_KEY")) pairs))
                             (when (getenv "ANTHROPIC_BASE_URL")
                               (push (cons "ANTHROPIC_BASE_URL" (getenv "ANTHROPIC_BASE_URL")) pairs))
                             (when (getenv "ANTHROPIC_AUTH_TOKEN")
                               (push (cons "ANTHROPIC_AUTH_TOKEN" (getenv "ANTHROPIC_AUTH_TOKEN")) pairs))
                             pairs))
                          (argv
                           (append
                            (list "exec" "-it"
                                  "--user" user
                                  "-w" workdir)
                            (mapcan (lambda (pair)
                                      (list "-e" (format "%s=%s" (car pair) (cdr pair))))
                                    env-pairs)
                            (list container devbox-container-helper-path "run"
                                  "-s" session "-c" "kiro-cli" "--" "chat"))))
                     (devbox-container--start-terminal
                      container user argv session "Kiro")))
                 (defalias 'devbox/kiro #'kiro-container))
     /#
     )
    (otherwise "")))

(feat! ai-code-interface
       "ai code interface for emacs"
       (:app)
       ai-code-interface-entry)
