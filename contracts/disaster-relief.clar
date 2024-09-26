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

