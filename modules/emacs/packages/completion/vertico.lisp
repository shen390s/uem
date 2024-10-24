(defun vertico-entry (self action args)
  (case action
	((:INIT)
	 #/
	 (progn
	   (pkginstall 'vertico)
	   ;;(pkginstall 'orderless)
	   (defun crm-indicator (args)
	     (cons (format "[CRM%s] %s"
			   (replace-regexp-in-string
			    "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
			    crm-separator)
			   (car args))
		   (cdr args)))
	   )
	 /#)
	((:CONFIG)
	 #/
	 (progn
	   (setq enable-recursive-minibuffers t)
	   (setq read-extended-command-predicte #'command-completion-default-include-p)
	   ;; Do not allow the cursor in the minibuffer prompt
	   (setq minibuffer-prompt-properties
		 '(read-only t cursor-intangible t face minibuffer-prompt)))
	/#)
  ((:CALL)
   #/
   (progn
     (advice-add #'completing-read-multiple :filter-args #'crm-indicator)
     (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)
     (vertico-mode 1)
     )
   
   /#)
  (otherwise "")))

(feat! vertico
       "Vertico completion"
       (:complete)
       vertico-entry)
