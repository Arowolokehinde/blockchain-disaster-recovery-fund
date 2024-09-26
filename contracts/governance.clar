;; Governance contract for managing the blockchain relief fund

;; =========================================
;; Data variables
;; =========================================

(define-data-var admin principal tx-sender)        ;; Admin who has special privileges
(define-data-var min-donation uint u10)            ;; Minimum donation required
(define-data-var withdrawal-limit uint u1000)      ;; Max withdrawal per recipient

;; =========================================
;; CORE FUNCTIONS
;; =========================================

;; Function to set a new admin (only callable by the current admin)
(define-public (set-admin (new-admin principal))
  (let ((current-admin (var-get admin)))
    (if (and 
          (is-eq tx-sender current-admin)
          (not (is-eq new-admin current-admin))
          (not (is-eq new-admin 'SP000000000000000000002Q6VF78))) ;; Example: Prevent setting to zero address
      (begin
        (var-set admin new-admin)
        (ok new-admin)
      )
      (err u401) ;; Error: Invalid admin change request
    )
  )
)

;; Function to update the minimum donation amount
(define-public (set-min-donation (amount uint))
  (if (is-eq tx-sender (var-get admin))
    (if (> amount u0)
      (begin
        (var-set min-donation amount)
        (ok amount)
      )
      (err u402) ;; Error: Invalid donation amount
    )
    (err u401) ;; Error: Only admin can call this function
  )
)

;; Function to update the maximum withdrawal limit
(define-public (set-withdrawal-limit (amount uint))
  (if (is-eq tx-sender (var-get admin))
    (if (> amount u0)
      (begin
        (var-set withdrawal-limit amount)
        (ok amount)
      )
      (err u403) ;; Error: Invalid withdrawal amount
    )
    (err u401) ;; Error: Only admin can call this function
  )
)

;; Read-only function to check the current admin
(define-read-only (get-admin)
  (ok (var-get admin))
)

;; Read-only function to get the minimum donation amount
(define-read-only (get-min-donation)
  (ok (var-get min-donation))
)

;; Read-only function to get the current withdrawal limit
(define-read-only (get-withdrawal-limit)
  (ok (var-get withdrawal-limit))
)

;; =========================================
;; RESTRICTIONS FOR DISASTER-RELIEF CONTRACT
;; =========================================

;; Function to validate if a donation meets the minimum requirement
(define-public (validate-donation (amount uint))
  (if (>= amount (var-get min-donation))
    (ok true)
    (err u404) ;; Error: Donation amount below minimum
  )
)

;; Function to validate if a recipient can withdraw within the set limit
(define-public (validate-withdrawal (amount uint))
  (if (<= amount (var-get withdrawal-limit))
    (ok true)
    (err u405) ;; Error: Withdrawal amount exceeds limit
  )
)
