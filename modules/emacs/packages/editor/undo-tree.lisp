(defun undo-tree-entry (self action args)
  (case action
        ((:INIT)
         #/
         (pkginstall 'undo-tree)
         /#)
        ((:CALL)
         #/
         (progn
           (require 'undo-tree)
           (global-undo-tree-mode 1))
         /#))
  )

(feat! undo-tree
       "smart parens mode"
       (:ui)
       undo-tree-entry)
