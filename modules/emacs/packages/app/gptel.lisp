(defun gptel-entry (self action )
  (case action
        ((:INIT) #/(progn
                     (pkginstall 'gptel)
		     (pkginstall 'markdown-mode))
/#
         )
        ((:CALL) #/(progn
                     (require 'gptel)
		     (when (boundp 'github_apikey)
		       (gptel-make-openai "Github Models" ;Any name you want
					  :host "models.inference.ai.azure.com"
					  :endpoint "/chat/completions"
					  :stream t
					  :key github_apikey
					  :models '(gpt-4o))))
/#
         )
        (otherwise "")))

(feat! gptel
       "Using emacs to talk to GPT LLM"
       (:app)
       gptel-entry)
