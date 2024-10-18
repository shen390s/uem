(defun emacs-server-entry (action args)
  (case action
        ((:START) "(server-start)")
        (otherwise "")))

(feat! emacs-server
       "emacs editor server"
       (:app)
       emacs-server-entry)
       

