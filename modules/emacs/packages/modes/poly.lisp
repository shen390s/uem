(mode! poly-markdown
       "poly mode for markdown mode"
       (markdown-mode
	(poly-markdown :type git
			 :host github
			 :repo "emacsmirror/poly-markdown")
	(polymode :type git
		    :host github
		    :repo "emacsmirror/polymode")))

(mode! poly-org
       "Poly org mode"
       ((poly-org :type git
		  :host github
		  :repo "emacsmirror/poly-R")))

(mode! poly-ascii
       "Poly asciidoc mode"
       (asciidoc-mode
	(poly-asciidoc :type git
		      :host github
		      :repo "shen390s/poly-asciidoc")))


