(in-package :uem)

(defvar uem-base
  (format nil "~A/uem"
          (uiop:getenv "HOME")))

(defvar uem-version
  "0.2.0")
