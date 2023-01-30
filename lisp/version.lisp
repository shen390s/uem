(in-package :uem)

(defun show-version ()
  (format t "Welcome to uem version ~A~%"
          uem-version)
  (format t "UEM base: ~A~%" uem-base))
