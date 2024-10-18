(defun sly-activate (args)
  `(progn
     (require 'sly-autoloads)
     (setq sly-contribs '())
     (push 'sly-fancy sly-contribs)))

(defun sly-entry (action args)
  (case action
        ((:INIT) `(progn
                    (straight-use-package 'sly)))
        ((:CALL) `(progn
                    (require 'sly-autoloads)
                    (setq sly-contribs '())
                    (push 'sly-fancy sly-contribs)))
        (otherwise "")))

(feat! sly
       "Interactive common lisp"
       (:app)
       sly-entry)
