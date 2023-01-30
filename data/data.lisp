(in-package :cl-user)

(defpackage uem.data
  (:use :cl)
  (:export :get-data-file
           :get-data-directory)
  (:documentation "uem data"))

(in-package :uem.data)

(defparameter +data-directory+
  (asdf:system-relative-pathname :uem #p"data/"))

(defun get-data-directory ()
  +data-directory+)

(defun get-data-file (filename)
  (merge-pathnames filename
                   +data-directory+))
