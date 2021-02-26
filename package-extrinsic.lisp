(cl:in-package #:common-lisp-user)

(defpackage #:simd-hash-table
  (:shadow #:gethash #:remhash #:clrhash
           #:maphash)
  (:use :cl)
  (:export #:linear-probing-hash-table
           #:gethash #:remhash #:clrhash #:maphash
           #:make-linear-hash-table))
