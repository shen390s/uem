(defun smartparens-entry (self action args)
  (case action
        ((:INIT)
         #/
         (pkginstall '(smartparens :type git
                                   :repo "Fuco1/smartparens"))
         /#)
        ((:CALL)
         #/
         (progn
           (require 'smartparens)
           (require 'smartparens-config)
           (smartparens-mode 1)
           (turn-on-show-smartparens-mode))
         /#))
  )

(feat! smartparens
       "smart parens mode"
       (:ui)
       smartparens-entry)
