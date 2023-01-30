(in-package :uem)

(defun emacs/handler (cmd)
  "handler for uem/emacs command"
  (clingon:print-usage-and-exit cmd t))

(defun emacs/options ()
  nil)

(defun emacs-install (cmd)
  (declare (ignorable cmd))
  t)

(defun emacs/install ()
  (clingon:make-command :name "install"
                        :description "install emacs distribution"
                        :usage "install"
                        :options nil
                        :handler #'emacs-install))

(defun emacs-init (cmd)
  (let* ((data-dir (uem.data:get-data-directory))
         (init-script (merge-pathnames "emacs/scripts/init.sh" data-dir))
         (force (clingon:getopt cmd :force)))
    (if (uiop:file-exists-p init-script)
        (progn
          (uiop:run-program
           (if force
               (list init-script
                     (format nil "--data-dir=~A" data-dir)
                     "--force")
               (list init-script
                     (format nil "--data-dir=~A" data-dir)))
           :output :interactive))
        (format t "uem/emacs init script ~A is not existed~%"
                init-script))))


(defun emacs/init-options ()
  "Return the option for emacs/init"
  (list
   (clingon:make-option :boolean/true
                        :description "force"
                        :short-name #\f
                        :long-name "force"
                        :key :force)))

(defun emacs/init ()
  (clingon:make-command :name "init"
                        :description "init emacs distribution"
                        :usage "[-f | --force]"
                        :options (emacs/init-options)
                        :handler #'emacs-init))

(defun emacs ()
  (clingon:make-command :name "emacs"
                      :description "emacs addon"
                      :usage "init | install "
                      :handler #'emacs/handler
                      :options (emacs/options)
                      :sub-commands (list (emacs/install)
                                          (emacs/init))))

(uem/register-addon #'emacs)
