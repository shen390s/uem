(defun magit-entry (self action args)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall 'magit)
       (require 'magit))
     /#)
    (otherwise "")))

(feat! magit
       "A git porcelain inside Emacs"
       (:app)
       magit-entry)
