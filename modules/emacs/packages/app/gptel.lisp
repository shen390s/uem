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
		       (setq gptel-model 'gpt-4o
			     gptel-backend
			     (gptel-make-openai "Github Models" ;Any name you want
						:host "models.inference.ai.azure.com"
						:endpoint "/chat/completions"
						:stream t
						:key github_apikey
						:models '(gpt-4o gpt-4o-mini
							  Phi-3.5-MoE-instruct
							  Phi-3.5-mini-instruct
							  Meta-Llama-3-70B-Instruct)))))
/#
         )
        (otherwise "")))

(feat! gptel
       "Using emacs to talk to GPT LLM"
       (:app)
       gptel-entry)
