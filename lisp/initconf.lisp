(in-package :uem)

(defun init-conf (module-path)
  (if module-path
      (setf module-path (uiop/filesystem:truename* module-path))
    (let ((executable-path (get-executable-path)))
      (setf module-path
            (make-pathname :name "modules"
                           :type nil
                           :defaults (get-directory-part
                                      (get-directory-part executable-path))))))
  (let ((init-file (make-pathname :name "emacs/emacs"
                                  :type "lisp"
                                  :defaults (uiop:ensure-directory-pathname module-path)))
        (init-config-file "emacs.lisp"))
    (uiop:copy-file init-file init-config-file)))
