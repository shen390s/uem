(defsystem uem
  :author "Rongsong Shen <rshen@shenrs.eu>"
  :maintainer "Rongsong Shen <rshen@shenrs.eu>"
  :license "BSD"
  :version "0.1"
  :homepage "https://github.com/shen390s/uem"
  :bug-tracker "https://github.com/shen390s/uem/issues"
  :source-control (:git "git@github.com:shen390s/uem.git")
  :depends-on (:clingon
               :uem-data)
  :components ((:module "lisp"
                :serial t
                :components
                ((:file "package")
                 (:file "version")
                 (:file "const")
                 (:file "core")
                 (:file "gen")
                 (:file "utils"))))
  :description "A tool for universal environ configuration"
  :long-description
  #.(uiop:read-file-string
     (uiop:subpathname *load-pathname* "README.adoc"))
  :in-order-to ((test-op (test-op uem-test))))
