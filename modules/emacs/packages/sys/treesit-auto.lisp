(defun treesit-auto-entry (self action)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(treesit-auto :type git
                                  :host github
                                  :repo "renzmann/treesit-auto"))
       (require 'treesit-auto))
     /#)
    ((:CALL)
     #/
     (progn
       (setq treesit-auto-install 'prompt)
       (treesit-auto-add-to-auto-mode-alist 'all)
       (global-treesit-auto-mode))
     /#)))

(feat! treesit-auto
       "Automatic tree-sitter grammar installation"
       (:core)
       treesit-auto-entry)
