(sys! emacs
      :init (progn
              (format t "hello from emacs"))
      :modes
      ()
      :app
      ((emacs-server :port 300)
       (sly :fancy 1)))

(format t "Hello from loading file~%")
