(defun telephone-line-entry (self action args)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(telephone-line :type git
		     :host github
		     :repo "dbordak/telephone-line")))
     /#)
    ((:CALL)
     #/
     (progn
       (telephone-line-mode 1))
     /#)))

(feat! telephone-line
       "telephone line a new implementation of powerline of Emacs"
       (:ui)
       telephone-line-entry)
