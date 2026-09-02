(defun devbox-entry (self action)
  (let ((args (data self)))
    (concatenate 'string
      (case action
        ((:CALL) #/(progn
                 ;; Shared devbox container infrastructure for ai-code-interface and agent-shell
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

                 (defvar devbox-container-docker-args nil
                   "Extra global options for the `docker' CLI.
Set this to target a remote Docker daemon, for example:
(setq devbox-container-docker-args '(\"--context\" \"my-remote\"))
or
(setq devbox-container-docker-args '(\"-H\" \"ssh://user@host\")).
These are inserted right after `docker' and before the subcommand.

`devbox-container--read-host' updates this so a whole command flow -
including the long-lived terminal it launches - targets the chosen host.")

                 (defvar devbox-container-host-history nil
                   "History for remote Docker host (user@host) prompts.")

                 (defvar devbox-container-last-host ""
                   "Last user@host targeted, offered as the default next time.
Empty string means the local Docker daemon.")

                 (defun devbox-container--read-host ()
                   "Prompt for a remote Docker host as user@host, or empty for localhost.
On non-empty input, point the docker CLI at that host over SSH by setting
`devbox-container-docker-args' to (\"-H\" \"ssh://user@host\").  Empty input
clears it, targeting the local daemon.  The choice is remembered in
`devbox-container-last-host' and applied for the rest of the command flow,
including the terminal session it launches."
                   (let ((host (string-trim
                                (read-string
                                 "Remote host user@host (empty = localhost): "
                                 devbox-container-last-host
                                 'devbox-container-host-history))))
                     (setq devbox-container-last-host host)
                     (setq devbox-container-docker-args
                           (unless (string-empty-p host)
                             (list "-H" (format "ssh://%s" host))))
                     host))

                 (defun devbox-container--docker-argv (&rest args)
                   "Return a docker command ARGV list prefixed with the docker program.
`devbox-container-docker-args' global options are spliced in before ARGS."
                   (append (cons "docker" devbox-container-docker-args) args))

                 (defun devbox-container--docker-string (&rest args)
                   "Return a shell-quoted docker command string for ARGS.
Global options from `devbox-container-docker-args' are included."
                   (mapconcat #'shell-quote-argument
                              (apply #'devbox-container--docker-argv args) " "))

                 (defun devbox-container--docker-call (&rest args)
                   "Run `docker' synchronously with ARGS, discarding output.
Returns the exit status.  Global options from
`devbox-container-docker-args' are included."
                   (let ((argv (apply #'devbox-container--docker-argv args)))
                     (apply #'call-process (car argv) nil nil nil (cdr argv))))

                 (defun devbox-container--ensure-helper (container user)
                   "Verify the devbox-agent helper is available in CONTAINER for USER.
The helper is baked into the container image at build time, so this only
checks that it is present and executable."
                   (eq 0 (devbox-container--docker-call
                          "exec" "--user" user container
                          "test" "-x" devbox-container-helper-path)))

                 (defun devbox-container--read-container ()
                   "Prompt for a remote host, then a running Docker container name.
The host prompt (see `devbox-container--read-host') selects the local or a
remote Docker daemon; the container list is then read from that daemon."
                   (devbox-container--read-host)
                   (let* ((containers
                           (split-string
                            (string-trim
                             (shell-command-to-string
                              (devbox-container--docker-string
                               "ps" "--format" "{{.Names}}")))
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
                             (format "%s 2>/dev/null"
                                     (devbox-container--docker-string
                                      "exec" "--user" user container
                                      devbox-container-helper-path
                                      "complete-dirs" dir depth-str))))))
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
                             (format "%s 2>/dev/null"
                                     (devbox-container--docker-string
                                      "exec" "--user" user container
                                      devbox-container-helper-path "list-session"))))))
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
                      base)))

                 (defconst devbox-container--new-session-item "+ New session"
                   "Sentinel completion item that means \"create a new session\".")

                 (defun devbox-container--select-session (container user &optional prompt)
                   "Select a living agent session in CONTAINER as USER, or choose to create one.
Living sessions are listed first, followed by a special
`devbox-container--new-session-item' entry.  Returns the chosen session
name string, or the symbol `new' when the user picked the new-session
item (or when there are no living sessions)."
                   (let ((sessions (devbox-container--list-sessions container user)))
                     (if (null sessions)
                         'new
                       (let* ((candidates
                               (append sessions
                                       (list devbox-container--new-session-item)))
                              (choice (completing-read
                                       (or prompt "Session: ")
                                       candidates nil t nil
                                       'devbox-container-session-history
                                       (car sessions))))
                         (if (string-equal choice devbox-container--new-session-item)
                             'new
                           choice)))))

                 (defun devbox-container--read-new-session (container user base &optional prompt)
                   "Read a fresh session name in CONTAINER as USER, defaulting from BASE.
BASE is a base name (e.g. \"claude-myproject\"); if it is already taken a
fresh BASE-N name is offered as the default.  PROMPT overrides the prompt."
                   (let* ((sessions (devbox-container--list-sessions container user))
                          (default (devbox-container--next-session-name sessions base)))
                     (completing-read
                      (or prompt "New session name: ")
                      nil nil nil nil 'devbox-container-session-history
                      default))))
         /#)
        (otherwise ""))
      (if (member '+ai-code-interface args)
          (ai-code-interface-entry self action)
        "")
      (if (member '+agent-shell args)
          (agent-shell-entry self action)
        ""))))

(feat! devbox
       "Devbox container agent sessions; enable integrations via +ai-code-interface and +agent-shell"
       (:app)
       devbox-entry)

