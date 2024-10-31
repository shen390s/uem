(defun auctex-entry (self action)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall 'auctex))
     /#)
    ((:config)
     #/
     (progn
       (setq TeX-auto-save t)
       (setq TeX-parse-self t)
       (setq-default TeX-master nil))
      /#)
    ((:post-config)
     #/
     (progn
       (load "auctex.el" nil t t)
       ;;(load "auctex-preview.el" nil t t)
       )
     /#)))

(feat! auctex
       "auctex"
       (:editor)
       auctex-entry)

(defun magic-latex-entry (self action)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(magic-latex-buffer :type git
					:host github
					:repo
					"zk-phi/magic-latex-buffer")))
     /#)
    ((:config)
     #/
     (progn
       (require 'magic-latex-buffer))
     /#)
    (otherwise t)))

(feat! magic-latex
       "magic-latex"
       (:editor)
       magic-latex-entry)
