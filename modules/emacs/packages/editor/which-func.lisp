(defun which-func-entry (self action)
  (case action
    ((:CALL)
     #/
     (progn
       (which-function-mode 1))
     /#)
    (otherwise t)))

(feat! which-func
       "show the name of current function"
       (:modes)
       which-func-entry)
