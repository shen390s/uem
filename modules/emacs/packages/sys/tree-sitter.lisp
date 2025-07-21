(defun tree-sitter-entry (self action)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(tree-sitter :repo "emacs-tree-sitter/elisp-tree-sitter"
                                 :fetcher github
                                 :branch "master"
                                 :files (:defaults (:exclude "lisp/tree-sitter-tests.el"))))
       ;;(pkginstall 'tree-sitter-indent)
       (pkginstall '(ts-fold :type git
			     :host github
			     :repo "emacs-tree-sitter/ts-fold"))
       (pkginstall '(tree-sitter-langs :type git
				       :host github
				       :repo "shen390s/tree-sitter-langs"))
       (pkginstall '(tree-sitter-yaml :type git
				      :host github
				      :repo "tree-sitter-grammars/tree-sitter-yaml"))
       (pkginstall '(tree-sitter-markdown :type git
					  :host github
					  :repo "tree-sitter-grammars/tree-sitter-markdown"))
       (pkginstall 'el-patch)
       ;;(require 'tree-sitter-indent)
       (require 'ts-fold)
       (require 'tree-sitter)
       (when (memq system-type '(berkeley-unix))
	 (el-patch-feature tree-sitter-langs-build)
	 (with-eval-after-load 'tree-sitter-langs-build
	   (el-patch-defun tree-sitter-langs--bundle-url (&optional version os)
			   "Return the URL to download the grammar bundle.
If VERSION and OS are not specified, use the defaults of
`tree-sitter-langs--bundle-version' and `tree-sitter-langs--os'."
			   (format
			    (el-patch-swap
			     "https://github.com/tree-sitter/tree-sitter-langs/releases/download/%s/%s"
			     "https://github.com/shen390s/tree-sitter-langs/releases/download/%s/%s")
			    version
			    (tree-sitter-langs--bundle-file ".gz" version os)))))
       (require 'tree-sitter-langs))
     /#)
    ((:CALL)
     #/
     (progn
       (tree-sitter-mode 1)
       (tree-sitter-hl-mode 1))
     /#)))

(feat! tree-sitter
       "Emacs binding of tree-sitter"
       (:modes)
       tree-sitter-entry)
