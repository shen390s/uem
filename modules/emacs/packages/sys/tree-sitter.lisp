(defun tree-sitter-entry (self action args)
  (case action
        ((:INIT)
         #/
         (progn
           (pkginstall '(tree-sitter :repo "emacs-tree-sitter/elisp-tree-sitter"
                                     :fetcher github
                                     :branch "master"
                                     :files (:defaults (:exclude "lisp/tree-sitter-tests.el"))))
           (pkginstall 'tree-sitter-langs)
           (require 'tree-sitter)
           (require 'tree-sitter-langs))
         /#)
        ((:CALL)
         #/
         (progn
           (tree-sitter-mode 1)
           (tree-sitter-hl-mode 1))
         /#)))

(feat! tree-sitter
       "Emacs binding of tree-sitter"
       (:modes)
       tree-sitter-entry)
