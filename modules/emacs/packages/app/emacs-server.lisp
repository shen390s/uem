(defun emacs-server-entry (self action args)
  (case action
        ((:ACTIVATE) "(server-start)")
        (otherwise "")))

(feat! emacs-server
       "emacs editor server"
       (:app)
       emacs-server-entry)
       

