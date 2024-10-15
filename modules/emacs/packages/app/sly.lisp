(feat! sly
       :scopes (:app)
       :init
       (progn
         (straight-use-package 'sly))
       :activate
       (progn
         (require 'sly-autoloads)
         (setq sly-contribs '())
         (push 'sly-fancy sly-contribs)
         (push 'sly-autodoc sly-contribs)))
