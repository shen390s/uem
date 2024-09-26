(in-package :uem)

(defun emacs/handler (cmd)
  "handler for uem/emacs command"
  (clingon:print-usage-and-exit cmd t))

(defun emacs/options ()
  nil)

(defun emacs-install (cmd)
  (let ((name (clingon:getopt cmd :name)))
    (let ((install-dir (or (clingon:getopt cmd :dir)
			   (format nil "~A/uem/emacs/~A"
				   (uiop:getenv "HOME")
				   name)))
	  (branch (clingon:getopt cmd :branch))
	  (install-script (merge-pathnames (format nil "emacs/scripts/~A-install.sh"
						   name)
					   (uem.data:get-data-directory))))
      (cond
       ((uiop/filesystem:file-exists-p install-script)
	(progn
	  (uiop:run-program
	   (if branch
	       (list install-script
		     (format nil "--branch=~A" branch)
		     install-dir)
	     (list install-script install-dir))
	   :output :interactive)))
       (t (format t "no installer for ~A" name))))))

(defun emacs/install-options ()
  "return the options for emacs/install"
  (list
   (clingon:make-option :string
			:description "distribution to install"
			:short-name #\n
			:long-name "name"
			:initial-value "easy"
			:key :name)
   (clingon:make-option :string
			:description "version/branch to be installed"
			:short-name #\b
			:long-name "branch"
			:initial-value nil
			:key :branch)
   (clingon:make-option :string
			:description "directory to be installed"
			:short-name #\d
			:long-name "directory"
			:initial-value nil
			:key :dir)))

(defun emacs/install ()
  (clingon:make-command :name "install"
                        :description "install emacs distribution"
                        :usage "install"
                        :options (emacs/install-options)
                        :handler #'emacs-install))

(defun emacs-init (cmd)
  (let* ((data-dir (uem.data:get-data-directory))
         (init-script (merge-pathnames "emacs/scripts/init.sh" data-dir))
         (force (clingon:getopt cmd :force)))
    (if (uiop:file-exists-p init-script)
        (progn
          (uiop:run-program
           (if force
               (list init-script
                     (format nil "--data-dir=~A" data-dir)
                     "--force")
               (list init-script
                     (format nil "--data-dir=~A" data-dir)))
           :output :interactive))
        (format t "uem/emacs init script ~A is not existed~%"
                init-script))))


(defun emacs/init-options ()
  "Return the option for emacs/init"
  (list
   (clingon:make-option :boolean/true
                        :description "force"
                        :short-name #\f
                        :long-name "force"
                        :key :force)))

(defun emacs/init ()
  (clingon:make-command :name "init"
                        :description "init emacs distribution"
                        :usage "[-f | --force]"
                        :options (emacs/init-options)
                        :handler #'emacs-init))

(defun emacs ()
  (clingon:make-command :name "emacs"
                      :description "emacs addon"
                      :usage "init | install "
                      :handler #'emacs/handler
                      :options (emacs/options)
                      :sub-commands (list (emacs/install)
                                          (emacs/init))))

(uem/register-addon #'emacs)
