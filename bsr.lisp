(cl:in-package #:simd-hash-table)

(sb-c:defknown bsf ((unsigned-byte 64))
    (unsigned-byte 64)
    (sb-c:foldable sb-c:movable sb-c:flushable))

(in-package :sb-vm)

(define-vop (simd-hash-table::bsf)
  (:translate simd-hash-table::bsf)
  (:policy :fast-safe)
  (:args (value :scs (unsigned-reg)))
  (:arg-types unsigned-num)
  (:results (scan :scs (unsigned-reg)))
  (:result-types unsigned-byte-64)
  (:generator 1
              (inst bsf scan value)))

(cl:in-package #:simd-hash-table)

(defun bsf (x)
  (bsf x))
