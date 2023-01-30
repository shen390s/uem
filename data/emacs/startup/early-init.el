;; early-init.el --- -*- lexical-binding: t; -*-
;;
(require 'uem
         (expand-file-name "uem.el"
                           (file-name-directory
                            (file-truename load-file-name))))
(uem-load-user-init "early-init.el")
