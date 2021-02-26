(cl:in-package #:simd-hash-table)

(defconstant +metadata-entries-per-group+ 16
  "The number of metadata entries we store per group.")
(deftype metadata-group ()
  `(sse:sse-pack (unsigned-byte 8)))
(deftype metadata-vector ()
  `(sse:sse-array (unsigned-byte 8) 1))
(deftype group-index ()
  `(integer 0 ,(floor array-total-size-limit +metadata-entries-per-group+)))
(deftype vector-index ()
  `(and fixnum unsigned-byte))

(defconstant +empty-metadata+     #x80
  "The metadata byte stored for an empty entry.")
(defconstant +tombstone-metadata+ #x81
  "The metadata byte stored for a tombstoned entry.")

(declaim (inline bytes matches-p writable mask-h2))

(defun writable (group)
  "Return matches for metadata bytes we can put new mappings in."
  (let ((top-bits (sse:and-pi (sse:set1-pi8 +empty-metadata+) group)))
    (sse:movemask-pi8 (sse:/=-pi8 (sse:setzero-pi) top-bits))))

(defun has-value (group)
  "Return matches for metadata bytes that already have mappings."
  (logxor #xffff (writable group)))

(defun mask-h2 (h2)
  "Mask off part of the H2 hash, for use as metadata."
  (declare ((unsigned-byte 8) h2))
  (logand #x7f h2))

(defun bytes (byte group)
  "Return matches for a byte in a metadata group."
  (declare ((unsigned-byte 8) byte))
  (sse:movemask-pi8
   (sse:=-pi8 (sse:set1-pi8 byte) group)))

(declaim (inline call-with-matches))
(defun call-with-matches (bit-mask continuation)
  (declare (function continuation)
           ((unsigned-byte 16) bit-mask)
           (optimize (speed 3) (safety 0)))
  (let ((position 0))
    (declare (fixnum position))
    (loop
      (when (zerop bit-mask)
        (return-from call-with-matches))
      (funcall continuation position)
      (when (= 1 bit-mask)
        (return-from call-with-matches))
      (let ((next-jump (bsf
                        (sb-ext:truly-the (unsigned-byte 16) (1- bit-mask)))))
        (setf bit-mask (ash bit-mask (- next-jump))
              position (ldb (byte 62 0) (+ position next-jump)))))))

(defmacro do-matches ((position bit-mask) &body body)
  "Evaluate BODY with POSITION bound to every match in the provided BIT-MASK."
  (let ((continuation (gensym "CONTINUATION")))
    `(flet ((,continuation (,position)
              (declare ((mod ,+metadata-entries-per-group+) ,position))
              ,@body))
       (declare (inline ,continuation)
                (dynamic-extent #',continuation))
       (call-with-matches ,bit-mask #',continuation))))

(defun matches-p (bit-mask)
  "Are there any matches in BIT-MASK?"
  (plusp bit-mask))

(defun make-metadata-vector (size)
  "Create a metadata vector for a hash table of a given size, with all elements initialized to +EMPTY-METADATA+."
  (sse:make-sse-array size
                      :element-type '(unsigned-byte 8)
                      :initial-element +empty-metadata+))

(declaim (inline (setf metadata) metadata
                 metadata-group))

(defun (setf metadata) (new-byte vector position)
  "Set a metadata byte."
  (declare (metadata-vector vector)
           (vector-index position)
           ((unsigned-byte 8) new-byte))
  (setf (aref vector position) new-byte))

(defun metadata (vector position)
  "Retrieve a metadata byte."
  (declare (metadata-vector vector)
           (vector-index position))
  (aref vector position))

(defun metadata-group (vector position)
  "Retrieve the Nth metadata group from a vector. 
Note that N has a length of a group; on a 8-element-per-group implementation, 
(metadata-group V 1) retrieves the 8th through 15th metadata bytes of V."
  (declare (metadata-vector vector)
           (group-index position)
           (optimize (speed 3) (safety 0)))
  ;; Why won't SSE:AREF-PI work?
  (sse:mem-ref-pi (sb-sys:vector-sap vector)
                  (* position 16)))
