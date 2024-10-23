(defun straight-entry (self action args)
  (case action
        ((:INIT)
         #/
      (defvar bootstrap-version)
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
           (progn
             (straight-use-package pkg)))   
        (straight-pull-package "melpa")
/#
         )
        (otherwise "")))

(feat! straight
       "emacs editor server"
       (:core)
       straight-entry)
       

