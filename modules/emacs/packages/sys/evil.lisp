(defun evil-entry (self action args)
  (case action
        ((:INIT)
         #/
         (progn
           (pkginstall 'evil)
           (pkginstall 'evil-collection)
           (pkginstall 'evil-leader))
         /#)
        ((:CALL)
         #/
         (progn
           (require 'evil)
           (require 'evil-leader)
           (global-evil-leader-mode)
           (evil-mode 1))
         /#)
        (otherwise "")))

(feat! evil
       "Evil "
       (:ui)
       evil-entry)
