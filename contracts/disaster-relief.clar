;; This smart contract manages a disaster-relief donation system with recipient allocations and admin controls.
;; It allows users to donate funds, administrators to manage recipients and contract settings,
;; and recipients to withdraw allocated funds.

;; constants
;;
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_INVALID_AMOUNT (err u2))
(define-constant ERR_INSUFFICIENT_FUNDS (err u3))
(define-constant ERR_RECIPIENT_NOT_FOUND (err u4))
(define-constant ERR_RECIPIENT_EXISTS (err u5))
(define-constant ERR_NOT_CONFIRMED (err u8))
(define-constant ERR_UNCHANGED_STATE (err u9))
(define-constant withdrawal-cooldown u86400) ;; 24 hours in seconds

;; data maps and vars
;;
(define-data-var total-funds uint u0)
(define-data-var admin principal tx-sender)
(define-data-var min-donation uint u1)
(define-data-var max-donation uint u1000000000)
(define-data-var paused bool false)

;; Maps
(define-map donations principal uint)
(define-map recipients principal uint)
(define-map last-withdrawal principal uint)

;; private functions
(define-private (distribute-to-recipient (recipient-data {recipient: principal, allocation: uint}))
  (let ((recipient (get recipient recipient-data))
        (allocation (get allocation recipient-data)))
    (try! (as-contract (stx-transfer? allocation tx-sender recipient)))
    (print {event: "funds-sent", recipient: recipient, amount: allocation})
    (ok true)
  )
)


;; public functions
;;
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

(define-public (set-admin (new-admin principal))
  (let ((current-admin (var-get admin)))
    (begin
      (asserts! (is-eq tx-sender current-admin) ERR_UNAUTHORIZED)
      (asserts! (not (is-eq new-admin current-admin)) (err u6)) ;; New error for unchanged admin
      (var-set admin new-admin)
      (ok new-admin)
    )
  )
)

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

(define-public (set-paused (new-paused-state bool))
  (let ((current-paused-state (var-get paused)))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) ERR_UNAUTHORIZED)
      (asserts! (not (is-eq new-paused-state current-paused-state)) ERR_UNCHANGED_STATE)
      (var-set paused new-paused-state)
      (print {event: "contract-pause-changed", paused: new-paused-state})
      (ok new-paused-state)
    )
  )
)

(define-public (update-recipient-allocation (recipient principal) (new-allocation uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_UNAUTHORIZED)
    (asserts! (> new-allocation u0) ERR_INVALID_AMOUNT)
    (asserts! (is-some (map-get? recipients recipient)) ERR_RECIPIENT_NOT_FOUND)
    (ok (map-set recipients recipient new-allocation))
  )
)

(define-public (remove-recipient (recipient principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? recipients recipient)) ERR_RECIPIENT_NOT_FOUND)
    (map-delete recipients recipient)
    (ok true)
  )
)

(define-public (confirm-remove-recipient (recipient principal) (confirm bool))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_UNAUTHORIZED)
    (asserts! confirm ERR_NOT_CONFIRMED)
    (asserts! (is-some (map-get? recipients recipient)) ERR_RECIPIENT_NOT_FOUND)
    (map-delete recipients recipient)
    (print {event: "recipient-removed", recipient: recipient})
    (ok true)
  )
)

(define-public (request-refund (amount uint))
  (let ((donation (get-donation tx-sender))
        (current-time (unwrap-panic (get-block-info? time u0))))
    (if (and (<= amount donation) 
             (>= (- current-time (unwrap-panic (get-block-info? time u0))) withdrawal-cooldown)) ;; Refund within 24 hours
      (begin
        (map-set donations tx-sender (- donation amount))
        (var-set total-funds (- (var-get total-funds) amount))
        (as-contract (stx-transfer? amount tx-sender 'ST000000000000000000002AMW42H))
      )
      (err u110) ;; Error: Refund period expired or invalid amount
    )
  )
)

(define-public (emergency-shutdown)
  (if (is-eq tx-sender (var-get admin))
    (begin
      (var-set paused true)
      (print {event: "emergency-shutdown", admin: tx-sender})
      (ok true)
    )
    (err u105) ;; Error: Unauthorized
  )
)

(define-public (log-audit (action-type (string-ascii 32)) (actor principal))
  (let ((current-time (unwrap-panic (get-block-info? time u0))))
    (ok true)
  )
)


(define-read-only (get-donation (user principal))
  (default-to u0 (map-get? donations user))
)

(define-read-only (get-total-funds)
  (ok (var-get total-funds))
)

(define-read-only (is-paused)
  (ok (var-get paused))
)

(define-read-only (get-recipient-allocation (recipient principal))
  (ok (default-to u0 (map-get? recipients recipient)))
)

(define-read-only (get-admin)
  (ok (var-get admin))
)

(define-read-only (get-user-history (user principal))
  ;; Return donation and withdrawal records for a user
  (ok (tuple (donations (map-get? donations user)) (withdrawals (map-get? last-withdrawal user))))
)


