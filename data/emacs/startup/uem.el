;; uem.el --- -*- lexical-binding: t; -*-

(defun uem-handle-command-line-args-acc (acc args)
  "process command line args"
  (if (null args)
      acc
    (let* ((args-processed (plist-get acc :args))
           (arg (car args))
           (s (split-string arg "=")))
      (cond
       ((equal arg "--profile")
        (let ((args-remained (cdr args)))
          (if (null args-remained)
              acc
            (uem-handle-command-line-args-acc (plist-put acc :profile (car args-remained))
                                              (cdr args-remained)))))
       ((equal (car s) "--profile")
        (uem-handle-command-line-args-acc (plist-put acc :profile (mapconcat 'identity (cdr s) "="))
                                          (cdr args)))
       (t (uem-handle-command-line-args-acc (plist-put acc :args (push arg args-processed))
                                            (cdr args)))))))

(defun uem-handle-command-line-args (args)
  (let ((res (uem-handle-command-line-args-acc nil args)))
    (cons (plist-get res :profile)
          (reverse (plist-get res :args)))))

(defun uem-read-file (filename)
  "read content of a file"
  (with-temp-buffer
    (insert-file-contents filename)
    (buffer-string)))

(defun uem-read-profile (profilename)
  "load setting of profile"
  (when (file-exists-p profilename)
    (read (uem-read-file profilename))))

(defun uem-profile-name (profile)
  (if (listp profile)
      (plist-get profile :name)
    nil))

(defun uem-profile-directory (profile)
  (if (listp profile)
      (let ((dir (plist-get profile :directory)))
	(if dir
	    (expand-file-name dir)
	  nil))
    nil))

(defun uem-profile-config-directory (profile)
  (if (listp profile)
      (let ((config-dir (plist-get profile :config-directory)))
	(if config-dir
	    (expand-file-name config-dir)
	  (uem-profile-directory profile)))
    nil))

(defun uem-profile-setup-fn (profile)
  (if (listp profile)
      (plist-get profile :setup-fn)
    nil))

(defun uem-default-setup (profile)
  "default setup function"
  (progn
    (let ((plugin (plist-get profile :load)))
      (when plugin
        (when (file-exists-p plugin)
          (load plugin))))
    (mapcar (lambda (env)
              (setenv (car env)
                      (cdr env)))
            (plist-get profile :environ))
    (let ((name (plist-get profile :server-name)))
      (if name
          (setq server-name name)
        (setq server-name (plist-get profile :name))))))

(defun uem-apply-profile (profile)
  (let ((setup-fn (uem-profile-setup-fn profile))
	(dir (uem-profile-config-directory profile)))
    (when dir
      (setq user-emacs-directory dir)
      (if setup-fn
          (funcall setup-fn profile)
        (uem-default-setup profile)))))

(defvar uem-profile nil
  "The profile will be used")

(defvar uem-profile-path "~/.config/uem/emacs/profiles"
  "The location of uem emacs profiles")

(let ((data (uem-handle-command-line-args command-line-args)))
  (let ((profile-name (car data)))
    (when profile-name
      (setq command-line-args (cdr data))
      (let ((profile-filename (expand-file-name profile-name
                                                uem-profile-path)))
        (let ((profile (uem-read-profile profile-filename)))
          (when profile
	    (setq uem-profile profile)
            (uem-apply-profile profile)))))))

(defun uem-load-user-init (filename)
  (let ((init-dir (or (when uem-profile
			(uem-profile-directory uem-profile))
		      user-emacs-directory)))
    (let ((init-file (file-truename
		      (expand-file-name filename init-dir)))
	  (my-truename (file-truename load-file-name)))
      (unless (string= init-file my-truename)
	;; avoid recursive load myself
	(load init-file t t)))))

(provide 'uem)
