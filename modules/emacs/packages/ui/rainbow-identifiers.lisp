(defun rainbow-identifiers-entry (action args)
  (case action
        ((:INIT)
         #/
         (progn
           (pkginstall 'rainbow-identifiers))
         /#)
        ((:CALL)
         #/
         (progn
           (require 'rainbow-identifiers)
           (rainbow-identifiers-mode 1))
         /#)
        (otherwise ""))
  )

(feat! rainbow-identifiers
       "Rainbow identifiers"
       (:ui)
       rainbow-identifiers-entry)
