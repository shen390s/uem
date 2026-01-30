(in-package :uem)

(defgeneric gencode (s output action)
            (:documentation "Generate code for scope"))

(defclass UEMScope (UEMContainerObject)
  ())

(defmethod gencode((s UEMScope) output action)
           (format output ""))

(defclass UEMFeatureScope (UEMFeatureContainer)
  ())

