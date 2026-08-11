(defun straight-entry (self action)
  (case action
        ((:INIT)
         #/
      (defvar bootstrap-version)
      (defvar skip-pkginstall
	(let ((skip (getenv "UEM_SKIP_PKGINSTALL")))
	  (and skip
	       (or (string-equal-ignore-case skip "Y")
		   (string-equal-ignore-case skip "YES")))))
      
      (let ((bootstrap-file
              (expand-file-name
               "straight/repos/straight.el/bootstrap.el"
               (or (bound-and-true-p straight-base-dir)
                   user-emacs-directory)))
            (bootstrap-version 7))
        (unless (file-exists-p bootstrap-file)
          (with-current-buffer
              (url-retrieve-synchronously
               "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
               'silent 'inhibit-cookies)
            (goto-char (point-max))
            (eval-print-last-sexp)))
        (load bootstrap-file nil 'nomessage))
        
        (defun pkginstall (pkg)
           (unless skip-pkginstall
             (straight-use-package pkg)))   
	(unless skip-pkginstall
          (condition-case err
              (straight-pull-package "melpa")
            (error
             (message "straight-pull-package melpa failed: %s" (error-message-string err))
             (let ((melpa-dir (expand-file-name "straight/repos/melpa"
                                                (or (bound-and-true-p straight-base-dir)
                                                    user-emacs-directory))))
               (unless (file-directory-p melpa-dir)
                 (message "Falling back to direct clone of melpa from GitHub...")
                 (let ((exit-code (call-process "git" nil nil nil
                                                "clone"
                                                "https://github.com/melpa/melpa.git"
                                                melpa-dir)))
                   (if (zerop exit-code)
                       (message "Successfully cloned melpa to %s" melpa-dir)
                     (error "Failed to clone melpa from GitHub (exit code %d)" exit-code))))))))
/#
         )
        (otherwise "")))

(feat! straight
       "emacs editor server"
       (:core)
       straight-entry)
       

