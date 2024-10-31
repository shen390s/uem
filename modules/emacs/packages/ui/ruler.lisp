(defun ruler-entry (self action)
  (case action
        ((:INIT)
         "")
        ((:CALL)
         #/
         (ruler-mode 1)
         /#)
        (otherwise "")))

(feat! ruler
       "Enable ruler"
       (:ui)
       ruler-entry)
