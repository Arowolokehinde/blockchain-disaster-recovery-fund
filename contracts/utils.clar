;; Utility contract for common functions and validations
;; =========================================

(define-constant ERR-INVALID-PRINCIPAL u1000)
(define-constant ERR-INVALID-AMOUNT u1001)
(define-constant ERR-UNAUTHORIZED u1002)
(define-constant ERR-OVERFLOW u1003)
(define-constant ERR-UNDERFLOW u1004)
(define-constant ERR-DIVIDE-BY-ZERO u1005)

;; Function to check if the given principal is a contract
(define-read-only (is-contract (user principal))
  (is-eq (as-contract user) user)
)

;; Function to check if a principal is valid (either a standard or contract principal)
(define-read-only (is-valid-principal (user principal))
  (or
    (is-contract user)   ;; Check if it's a contract
    (is-eq user tx-sender) ;; Validate as a standard principal if it's the same as tx-sender
  )
)

;; Function to check if a given value is greater than zero
(define-read-only (is-valid-amount (amount uint))
  (if (> amount u0)
    (ok true)
    (err ERR-INVALID-AMOUNT)))


(define-read-only (is-some-principal (value (optional principal)))
  (is-some value)
)

(define-read-only (is-some-value (value (optional uint)))
  (is-some value)
)

;; Function to check if tx-sender is the same as a given principal
(define-read-only (is-sender (user principal))
  (is-eq tx-sender user)
)

;; Function to get the current block height
(define-read-only (get-current-block-height)
  block-height)

;; Function to get the current chain tip
(define-read-only (get-current-chain-tip)
  (get-block-info? id-header-hash (- block-height u1)))


;; Function to validate if the sender is the admin (common utility)
(define-read-only (is-admin (admin principal))
  (is-eq tx-sender admin)
)

(define-read-only (is-within-range (value uint) (min uint) (max uint))
  (and (>= value min) (<= value max)))

;; Function to convert a uint to an optional uint
(define-read-only (uint-to-optional (value uint))
  (some value))

;; Function to convert an optional uint to a uint with a default value
(define-read-only (optional-to-uint (value (optional uint)) (default uint))
  (default-to default value))


;; Safely add two unsigned integers (uint)
(define-read-only (safe-add (a uint) (b uint))
  (let ((result (+ a b)))
    (if (< result a)
      (err ERR-OVERFLOW)
      (ok result))))

;; Safely subtract two unsigned integers (uint)
(define-read-only (safe-subtract (a uint) (b uint))
  (if (< a b)
    (err ERR-UNDERFLOW)
    (ok (- a b))))

;; Safely multiply two unsigned integers (uint)
(define-read-only (safe-multiply (a uint) (b uint))
  (let ((result (* a b)))
    (if (and (> a u0) (not (is-eq (/ result a) b)))
      (err ERR-OVERFLOW)
      (ok result))))

;; Safely divide two unsigned integers (uint)
(define-read-only (safe-divide (a uint) (b uint))
  (if (is-eq b u0)
    (err ERR-DIVIDE-BY-ZERO)
    (ok (/ a b))))