;; Utility contract for common functions and validations
;; =========================================

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
    true
    false
  )
)

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

;; Function to validate if the sender is the admin (common utility)
(define-read-only (is-admin (admin principal))
  (is-eq tx-sender admin)
)

;; Safely add two unsigned integers (uint)
(define-read-only (safe-add (a uint) (b uint))
  (if (<= (+ a b) u18446744073709551615)
    (ok (+ a b))
    (err u100) ;; Error: Overflow
  )
)

;; Safely subtract two unsigned integers (uint)
(define-read-only (safe-subtract (a uint) (b uint))
  (if (>= a b)
    (ok (- a b))
    (err u101) ;; Error: Underflow
  )
)

;; Safely multiply two unsigned integers (uint)
(define-read-only (safe-multiply (a uint) (b uint))
  (if (<= (* a b) u18446744073709551615)
    (ok (* a b))
    (err u102) ;; Error: Overflow
  )
)

;; Safely divide two unsigned integers (uint)
(define-read-only (safe-divide (a uint) (b uint))
  (if (> b u0)
    (ok (/ a b))
    (err u103) ;; Error: Division by zero
  )
)
