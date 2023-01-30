(in-package :uem)

(defun fish/handler (cmd)
  "handler for uem/fish command"
  (clingon:print-usage-and-exit cmd t))

(defun fish/options ()
  nil)

(defun fish-install (cmd)
  (declare (ignorable cmd))
  t)

(defun fish/install ()
  (clingon:make-command :name "install"
                        :description "install fish distribution"
                        :usage "install"
                        :options nil
                        :handler #'fish-install))

(defun fish-use (cmd)
  (declare (ignorable cmd))
  t)

(defun fish/use ()
  (clingon:make-command :name "use"
                        :description "use fish distribution"
                        :usage "use"
                        :options nil
                        :handler #'fish-use))

(defun fish ()
  (clingon:make-command :name "fish"
                        :description "fish addon"
                        :usage "install | use"
                        :handler #'fish/handler
                        :options (fish/options)
                        :sub-commands (list (fish/install)
                                            (fish/use))))
(uem/register-addon #'fish)
