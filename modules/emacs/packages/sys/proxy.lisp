(defun proxy-entry (self action)
  (case action
    ((:INIT) #/
     (progn
       (defun check_proxy (proxy)
	 (let ((rc (call-process "curl" nil "check-proxy" t
				 "-x" proxy "www.gnu.org")))
	   (= rc 0)))

       (defun setup_proxy (proxies)
	 (when proxies
	   (let ((proxy (car proxies)))
	     (if (check_proxy proxy)
		 (progn
		   (setenv "HTTP_PROXY" proxy)
		   (setenv "HTTPS_PROXY" proxy))
		 (setup_proxy (cdr proxies))))))

       (when proxies
	 (setup_proxy proxies)))
/#
     )
    (otherwise "")))

(feat! proxy
       "setup proxy in emacs"
       (:core)
       proxy-entry)
