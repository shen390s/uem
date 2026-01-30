(defun auto-fill-entry (self action)
  (case action
    ((:CALL)
     #/
     (progn
       (auto-fill-mode 1))
     /#)
    (otherwise t)))

(feat! auto-fill
       "show the name of current function"
       (:modes)
       auto-fill-entry)
