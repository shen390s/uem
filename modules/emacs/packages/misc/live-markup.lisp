(defun livemarkup-entry (self action)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(emacs-livemarkup :type git
				      :host github
				      :repo "shen390s/emacs-livemarkup")))
     /#)
    ((:config)
     #/
     (progn
       (require 'livemarkup)
       (setq livemarkup-output-directory nil
             livemarkup-close-buffer-delete-temp-files t
             livemarkup-refresh-interval 3))
     /#)
    ((:call)
     #/
     (progn
       (let ((file-name (buffer-file-name)))
	 (when file-name
	   (let ((ext-name (file-name-extension file-name)))
	     (cond
	      ((string= ext-name "org") (livemarkup-track-org))
	      ((string= ext-name "adoc") (livemarkup-track-asciidoc))
	      (t t))))))
     /#
     )))

(feat! livemarkup
       "live preview for org and asciidoc"
       (:modes)
       livemarkup-entry)
