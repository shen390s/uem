(defun origami-call (self )
  (let ((own (owner self)))
    (cond
      ((typep own 'EmacsGenericMode)
       #/
       (progn
	 (origami-mode 1))
       /#)
      (t
       #/
       (progn
	 (global-origami-mode 1))
       /#))))

(defun origami-entry (self action )
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(origami :type git
		     :host github
		     :repo "gregsexton/origami.el")))
     /#)
    ((:CALL)
     (origami-call self ))
    (otherwise "")))

(feat! origami
       "A text folding minor mode for Emacs"
       (:modes :app)
       origami-entry)
