(sys! emacs
      :init
      (progn
        (message \"hello from emacs\"))
      :modes
      ((c +flymake +lsp)
       (python -flymake +lsp))
      :app
      ((emacs-server :port 300)
       (sly :fancy 1)))

(format t "Hello from loading file~%")
