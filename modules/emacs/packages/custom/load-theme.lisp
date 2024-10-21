(defun load-custom-entry (action args)
  (case action
    ((:INIT)
     (let ((themes (getf args :theme))
           (predata #/
(defun load-theme-ex (theme flag)
  (condition-case err
      (load-theme theme flag)
    (error (message "%s" (error-message-string err))
           nil)))

(defun load-themes (themes flag)
  (when themes
    (unless (load-theme-ex (car themes) flag)
      (load-themes (cdr themes) flag))))
(defvar custom-themes nil)
/#
                    ))
       (concatenate 'string
                    predata
                    (if themes
                        (format nil "(setq custom-themes '(~a))~%"
                                themes)
                      "")
                    (format nil "(push \"~a/themes\" custom-theme-load-path)~%"
                            *uem-module-root*))))
    ((:CALL) #/
     (progn
       (when custom-file
         (load custom-file t t))
       (when custom-themes
         (load-themes custom-themes t)))
/#
     )))

(feat! load-custom
       "Load customization theme"
       (:ui)
       load-custom-entry)
