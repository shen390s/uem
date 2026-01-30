(mode! typst-ts
       "Emacs mode to edit typst programming language file"
       ("(typst-ts-mode :type git
		      :host codeberg
		      :repo \"meow_king/typst-ts-mode\")"))


(defun call-typst-preview (self action)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(websocket :type git
		     :host github
		     :repo "ahyatt/emacs-websocket"))
       (require 'websocket)
       (pkginstall '(typst-preview :type git
				   :host github
				   :repo "havarddj/typst-preview.el"))
       (require 'typst-preview))
     /#)
    ((:CALL)
     #/
     (progn
       (setq typst-preview-browser "xwidget")
       (typst-preview-start))
     /#)))

(feat! typst-preview
       "typst preview"
       (:editor)
       call-typst-preview)
