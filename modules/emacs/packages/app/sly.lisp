(defun sly-entry (action args)
  (case action
        ((:INIT) #/(progn
                     (pkginstall 'sly))
/#
         )
        ((:CALL) #/(progn
                    (require 'sly-autoloads)
                    (setq sly-contribs '())
                    (push 'sly-fancy sly-contribs))
/#
         )
        (otherwise "")))

(feat! sly
       "Interactive common lisp"
       (:app)
       sly-entry)
