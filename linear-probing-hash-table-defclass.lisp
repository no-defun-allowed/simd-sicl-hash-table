(cl:in-package #:simd-hash-table)

(defstruct (linear-probing-hash-table
            (:constructor %make-hash-table)
            (:conc-name ht-))
  (size 64 :type fixnum)
  (test #'eql :type function)
  (hash-function #'sxhash :type function)
  (rehash-threshold 0.8s0 :type single-float)
  (metadata (error "no metadata")
   :type (simple-array (unsigned-byte 8) 1))
  (data (error "no data")
   :type simple-vector)
  (tombstone-count 0 :type fixnum)
  (count 0 :type fixnum)
  (cached-position 0 :type (mod #.(1- most-positive-fixnum))))

(defun make-linear-hash-table (&key (size 64) (test #'eql)
                                    (hash-function #'sxhash))
  (let ((size (nearest-allowed-size size)))
    (%make-hash-table
     :size size
     :test test
     :hash-function hash-function
     :data (make-data-vector size)
     :metadata (make-metadata-vector size))))

(defmethod print-object ((table linear-probing-hash-table) stream)
  (print-unreadable-object (table stream :type t :identity t)
    (format stream ":test ~s :load ~d/~d"
            (ht-test table)
            (ht-count table)
            (ht-size table))))
