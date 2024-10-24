(defun origami-call (self args)
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

(defun origami-entry (self action args)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(origami :type git
		     :host github
		     :repo "gregsexton/origami.el")))
     /#)
    ((:CALL)
     (origami-call self args))
    (otherwise "")))

(feat! origami
       "A text folding minor mode for Emacs"
       (:modes :app)
       origami-entry)
