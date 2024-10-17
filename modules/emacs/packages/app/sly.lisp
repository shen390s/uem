(defun sly-activate (args)
  `(progn
     (require 'sly-autoloads)
     (setq sly-contribs '())
     (push 'sly-fancy sly-contribs)))

(feat! sly
       :scopes (:app)
       :init
       (progn
         (straight-use-package 'sly))
       :activate #'sly-activate)
