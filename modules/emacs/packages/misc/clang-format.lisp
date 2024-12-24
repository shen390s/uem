(defun clang-format-entry (self action)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(clang-format :type git
				  :host github
				  :repo "shen390s/clang-format")))
     /#)
    ((:CALL)
     #/
     (progn
       (require 'clang-format))
     /#)
    (otherwise t)))

(feat! clang-format
       "using clang-format to format emacs buffer"
       (:editor)
       clang-format-entry)
