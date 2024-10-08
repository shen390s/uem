(sys! emacs
      :init (progn
              (format t "hello from emacs"))
      :modes
      ()
      :app
      (emacs-server))

(format t "Hello from loading file~%")
