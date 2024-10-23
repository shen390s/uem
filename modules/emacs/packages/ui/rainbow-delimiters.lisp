(defun rainbow-delimiters-entry (self action args)
  (case action
        ((:INIT)
         #/
         (progn
           (pkginstall 'rainbow-delimiters))
         /#)
        ((:CALL)
         #/
         (progn
           (require 'rainbow-delimiters)
           (rainbow-delimiters-mode 1))
         /#)
        (otherwise ""))
  )

(feat! rainbow-delimiters
       "Rainbow delimiters"
       (:ui)
       rainbow-delimiters-entry)
