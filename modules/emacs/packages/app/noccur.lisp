(defun noccur-entry (self action)
  (case action
    ((:init)
     #/
     (progn
       (pkginstall '(noccur :type git
			    :host github
			    :repo "NicolasPetton/noccur.el")))
     /#)
    ((:call)
     #/
     (progn
       (require 'noccur))
     /#)))

(feat! noccur
       "Run multi-occur on project/dired files"
       (:app)
       noccur-entry)
