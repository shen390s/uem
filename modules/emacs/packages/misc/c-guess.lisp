(defun guess-c-style-entry (self action)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(google-c-style :type git
				    :host github
				    :repo "emacsmirror/google-c-style")))
     /#)
    ((:CALL)
     #/
     (progn
       (require 'cc-guess)
       (condition-case err
	   (c-guess)
	 (error (progn
		  (c-set-style "cc-mode")))))
     /#)
    (otherwise t)))

(feat! guess-c-style
       "guess-c-style"
       (:editor)
       guess-c-style-entry)
