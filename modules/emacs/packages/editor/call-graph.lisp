(defun call-graph-entry (self action)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall 'call-graph)
       (require 'call-graph))
     /#)
    ((:CALL)
     #/
     (progn
       (call-graph))
     /#
     )))

(feat! call-graph
       "Generate call graph for c/c++"
       (:modes)
       call-graph-entry)
