(defun emacs-server-entry (self action )
  (case action
    ((:CALL) #/(progn
                 (server-start))
/#
     )
    (otherwise "")))

(feat! emacs-server
       "emacs editor server"
       (:app)
       emacs-server-entry)


