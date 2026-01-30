(defun cursory-entry (self action)
  (case action
	((:INIT)
	 #/
	 (pkginstall 'cursory)
	 /#)
	((:CALL)
	 #/
	 (progn
	   (setq cursory-presets
	         '((box
	            :cursor-color success ; will typically be green
	            :blink-cursor-interval 1.2)
	           (box-no-blink
	            :inherit box
	            :blink-cursor-mode -1)
	           (bar
	            :cursor-type (bar . 2)
	            :cursor-color error ; will typically be red
	            :blink-cursor-interval 0.8)
	           (bar-no-other-window
	            :inherit bar
	            :cursor-in-non-selected-windows nil)
	           (bar-no-blink
	            :inherit bar
	            :blink-cursor-mode -1)
	           (underscore
	            :cursor-color warning ; will typically be yellow
	            :cursor-type (hbar . 3)
	            :blink-cursor-interval 0.3
	            :blink-cursor-blinks 50)
	           (underscore-no-other-window
	            :inherit underscore
	            :cursor-in-non-selected-windows nil)
	           (underscore-thick
	            :inherit underscore
	            :cursor-type (hbar . 8)
	            :cursor-in-non-selected-windows (hbar . 3))
	           (t ; the default values
	            :cursor-color unspecified ; use the theme's original
	            :cursor-type box
	            :cursor-in-non-selected-windows hollow
	            :blink-cursor-mode 1
	            :blink-cursor-blinks 10
	            :blink-cursor-interval 0.2
	            :blink-cursor-delay 0.2)))
       (cursory-mode 1)
       (when (boundp 'cursory-default-preset)
         (cursory-set-preset cursory-default-preset)))
	 /#)
	(otherwise "")))

(feat! cursory
       "highlight current line number"
       (:ui)
       cursory-entry)
