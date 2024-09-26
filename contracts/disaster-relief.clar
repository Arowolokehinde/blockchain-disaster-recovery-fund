;; =========================================
;; DATA VARIABLES
;; =========================================

(define-data-var total-funds uint u0)
(define-data-var admin principal tx-sender)
(define-data-var min-donation uint u1)
(define-data-var max-donation uint u1000000000)
(define-data-var paused bool false)

;; Maps
(define-map donations principal uint)
(define-map recipients principal uint)
(define-map last-withdrawal principal uint)

;; =========================================
;; CONSTANTS
;; =========================================

(define-constant withdrawal-cooldown u86400) ;; 24 hours in seconds


;; =========================================
;; CORE FUNCTIONS
;; =========================================

;; Function to donate funds (anyone can call)
(define-public (donate (amount uint))
  (if (and (not (var-get paused))
           (>= amount (var-get min-donation))
           (<= amount (var-get max-donation)))
    (begin
      (map-set donations tx-sender (+ (get-donation tx-sender) amount))
      (var-set total-funds (+ (var-get total-funds) amount))
      (print {event: "donation", sender: tx-sender, amount: amount})
      (ok amount)
    )
    (err u100) ;; Error: Invalid donation amount or contract paused
  )
)

;; Function to get current donation of a user
(define-read-only (get-donation (user principal))
  (default-to u0 (map-get? donations user))
)

;; Function to add a recipient (only admin can call)
(define-public (add-recipient (recipient principal) (allocation uint))
  (if (and (is-eq tx-sender (var-get admin))
           (is-none (map-get? recipients recipient))
           (> allocation u0))
    (begin
      (map-set recipients recipient allocation)
      (print {event: "recipient-added", recipient: recipient, allocation: allocation})
      (ok (tuple (recipient recipient) (allocation allocation)))
    )
    (err u101) ;; Error: Unauthorized or invalid input
  )
)

;; Function to withdraw funds (only for verified recipients)
(define-public (withdraw (amount uint))
  (let (
    (recipient-allocation (default-to u0 (map-get? recipients tx-sender)))
    (last-withdrawal-time (default-to u0 (map-get? last-withdrawal tx-sender)))
    (current-time (unwrap-panic (get-block-info? time u0)))
  )
    (if (and (not (var-get paused))
             (> recipient-allocation u0)
             (>= recipient-allocation amount)
             (>= (- current-time last-withdrawal-time) withdrawal-cooldown))
      (begin
        (map-set recipients tx-sender (- recipient-allocation amount))
        (var-set total-funds (- (var-get total-funds) amount))
        (map-set last-withdrawal tx-sender current-time)
        (print {event: "withdrawal", recipient: tx-sender, amount: amount})
        (as-contract (stx-transfer? amount tx-sender 'ST000000000000000000002AMW42H))
      )
      (err u102) ;; Error: Invalid withdrawal or cooldown period not met
    )
  )
)


;; =========================================
;; ADMIN FUNCTIONS
;; =========================================

;; Function to set a new admin (only current admin can call)
(define-public (set-admin (new-admin principal))
  (if (is-eq tx-sender (var-get admin))
    (begin
      (var-set admin new-admin)
      (print {event: "admin-changed", new-admin: new-admin})
      (ok new-admin)
    )
    (err u103) ;; Error: Unauthorized
  )
)

;; Function to update donation limits (only admin can call)
(define-public (set-donation-limits (new-min uint) (new-max uint))
  (if (and (is-eq tx-sender (var-get admin)) (< new-min new-max))
    (begin
      (var-set min-donation new-min)
      (var-set max-donation new-max)
      (print {event: "donation-limits-updated", min: new-min, max: new-max})
      (ok true)
    )
    (err u104) ;; Error: Unauthorized or invalid limits
  )
)

;; Function to pause/unpause the contract (only admin can call)
(define-public (set-paused (new-paused-state bool))
  (if (is-eq tx-sender (var-get admin))
    (begin
      (var-set paused new-paused-state)
      (print {event: "contract-pause-changed", paused: new-paused-state})
      (ok new-paused-state)
    )
    (err u105) ;; Error: Unauthorized
  )
)

;; Function to update recipient allocation (only admin can call)
(define-public (update-recipient-allocation (recipient principal) (new-allocation uint))
  (if (and (is-eq tx-sender (var-get admin)) (is-some (map-get? recipients recipient)))
    (begin
      (map-set recipients recipient new-allocation)
      (print {event: "recipient-allocation-updated", recipient: recipient, new-allocation: new-allocation})
      (ok new-allocation)
    )
    (err u106) ;; Error: Unauthorized or recipient not found
  )
)




;; =========================================
;; READ-ONLY FUNCTIONS
;; =========================================

;; Function to get the contract's total balance
(define-read-only (get-total-funds)
  (ok (var-get total-funds))
)

;; Function to check if the contract is paused
(define-read-only (is-paused)
  (ok (var-get paused))
)

;; Function to get recipient's allocation
(define-read-only (get-recipient-allocation (recipient principal))
  (ok (default-to u0 (map-get? recipients recipient)))
)



;; Function to get the current admin
(define-read-only (get-admin)
  (ok (var-get admin))
)
