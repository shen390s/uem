(mode! peg-ts
       "Tree-sitter based Emacs mode to edit peg file"
       ("(peg-ts-mode :type git
		      :host github
		      :repo \"shen390s/peg-mode\")"))

;; Register the peg tree-sitter grammar source and build it automatically
;; when it is not yet available.  Kept here (instead of in emacs.lisp) so the
;; grammar setup lives with the mode that needs it.  The upstream repo ships
;; the generated parser.c/headers, so a fresh clone compiles without the
;; tree-sitter CLI.  Emitted in the :CALL (activate) path so it only runs
;; when a peg buffer is actually opened.
(defmethod gencode :after ((s peg-ts) output action)
	   (case action
	     ((:CALL)
	      (format output "~a"
		      #/
	      (with-eval-after-load 'treesit
		(add-to-list 'treesit-language-source-alist
			     '(peg "https://github.com/shen390s/tree-sitter-peg"))
		(unless (treesit-language-available-p 'peg)
		  (treesit-install-language-grammar 'peg)))
		      /#))
	     (otherwise "")))
