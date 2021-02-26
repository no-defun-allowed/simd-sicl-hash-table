(cl:in-package #:asdf-user)

(asdf:defsystem #:sicl-linear-probing-hash-table-simd
  :depends-on (#:cl-simd)
  :serial t
  :components ((:file "package-extrinsic")
               (:file "linear-probing-hash-table-defclass")
               (:file "bsr")
               (:file "sse-metadata-table")
               (:file "linear-probing-hash-table")))
