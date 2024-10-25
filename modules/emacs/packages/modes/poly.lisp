(mode! poly-markdown
       "poly mode for markdown mode"
       (#/(poly-markdown :type git
			 :host github
			 :repo "emacsmirror/poly-markdown")
	/#
	#/(polymode :type git
		    :host github
		    :repo "emacsmirror/polymode")
	/#)
       (.md))
