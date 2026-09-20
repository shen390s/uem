(defun treemacs-entry (self action)
  (let ((args (data self)))
    (concatenate 'string
      (case action
        ((:INIT)
         #/
         (progn
           (pkginstall '(treemacs :type git
                                  :host github
                                  :repo "Alexander-Miller/treemacs"))
           (pkginstall 'hydra)
           (pkginstall 'ace-window)
           (pkginstall 'cfrs)
           (pkginstall 'pfuture)
           (pkginstall 'posframe))
         /#)
        ((:CALL)
         #/
         (progn
           (require 'treemacs)
           (with-eval-after-load 'treemacs
             (setq treemacs-follow-after-init t
                   treemacs-width 35
                   treemacs-indentation 2
                   treemacs-collapse-dirs 3
                   treemacs-silent-refresh t
                   treemacs-silent-filewatch t
                   treemacs-sorting 'alphabetic-asc
                   treemacs-show-hidden-files t
                   treemacs-is-never-other-window t)
             (treemacs-follow-mode t)
             (treemacs-filewatch-mode t)
             (treemacs-fringe-indicator-mode 'always)
             (when (executable-find "git")
               (if treemacs-python-executable
                   (treemacs-git-mode 'deferred)
                 (treemacs-git-mode 'simple))))
           (global-set-key (kbd "M-0")       'treemacs-select-window)
           (global-set-key (kbd "C-x t 1")   'treemacs-delete-other-windows)
           (global-set-key (kbd "C-x t t")   'treemacs)
           (global-set-key (kbd "C-x t d")   'treemacs-select-directory)
           (global-set-key (kbd "C-x t B")   'treemacs-bookmark)
           (global-set-key (kbd "C-x t C-t") 'treemacs-find-file)
           (global-set-key (kbd "C-x t M-t") 'treemacs-find-tag))
         /#)
        (otherwise ""))
      ;; treemacs-evil: evil integration for treemacs
      (if (member '+evil args)
          (case action
            ((:INIT)
             #/
             (progn
               (pkginstall '(treemacs-evil :type git
                                           :host github
                                           :repo "Alexander-Miller/treemacs"
                                           :files ("src/extra/treemacs-evil.el"))))
             /#)
            ((:CALL)
             #/
             (progn
               (require 'treemacs-evil))
             /#)
            (otherwise ""))
        "")
      ;; treemacs-magit: magit integration for treemacs
      (if (member '+magit args)
          (case action
            ((:INIT)
             #/
             (progn
               (pkginstall '(treemacs-magit :type git
                                            :host github
                                            :repo "Alexander-Miller/treemacs"
                                            :files ("src/extra/treemacs-magit.el"))))
             /#)
            ((:CALL)
             #/
             (progn
               (with-eval-after-load 'magit
                 (require 'treemacs-magit)))
             /#)
            (otherwise ""))
        ""))))

(feat! treemacs
       "A tree layout file explorer for Emacs; enable integrations via +evil and +magit"
       (:app)
       treemacs-entry)
