(defun call-yaml-pro-entry (self action)
  (case action
    ((:INIT)
     #/
     (progn
       (pkginstall '(yaml-pro :type git
			      :host github
			      :repo "zkry/yaml-pro"))
       (require 'yaml-pro))
     /#)
    ((:CALL)
     #/
     (progn
       (yaml-pro-mode 1))
     /#)))

(feat! yaml-pro
       "yaml-pro mode for yaml file edit"
       (:modes)
       call-yaml-pro-entry)
