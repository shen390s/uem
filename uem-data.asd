(defsystem uem-data
  :author "Rongsong Shen <rshen@shenrs.eu>"
  :maintainer "Rongsong Shen <rshen@shenrs.eu>"
  :license "BSD"
  :version "0.1"
  :homepage "https://github.com/shen390s/uem"
  :bug-tracker "https://github.com/shen390s/uem/issues"
  :source-control (:git "git@github.com:shen390s/uem.git")
  :depends-on ()
  :components ((:module "data"
                :serial t
                :components
                ((:file "data")
                 (:module "emacs"
                  :serial t
                  :components
                  ((:module "startup"
                    :serial t
                    :components
                            ((:static-file "early-init.el")
                             (:static-file "init.el")
                             (:static-file "uem.el")))
                   (:module "scripts"
                    :serial t
                    :components
                            ((:static-file "init.sh")))
                   (:module "profiles"
                    :serial t
                    :components
                            ((:static-file "default"))))))))
  :description "A tool for universal environ configuration")
