;; ChainPulse Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-data (err u101))

;; Data Maps
(define-map daily-stats
  { date: uint }
  {
    tx-count: uint,
    active-addresses: uint,
    volume: uint
  }
)

(define-map address-activity
  { address: principal }
  { last-active: uint }
)

;; Data Variables
(define-data-var current-day uint u0)
(define-data-var total-tx-count uint u0)

;; Public Functions
(define-public (record-transaction (amount uint))
  (let
    (
      (current-stats (unwrap! (get-daily-stats (var-get current-day)) (err u102)))
    )
    (map-set daily-stats
      { date: (var-get current-day) }
      {
        tx-count: (+ (get tx-count current-stats) u1),
        active-addresses: (get active-addresses current-stats),
        volume: (+ (get volume current-stats) amount)
      }
    )
    (ok true)
  )
)

(define-public (record-active-address (address principal))
  (begin
    (map-set address-activity
      { address: address }
      { last-active: block-height }
    )
    (ok true)
  )
)

;; Admin Functions
(define-public (set-current-day (new-day uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set current-day new-day)
    (ok true)
  )
)

;; Read Only Functions
(define-read-only (get-daily-stats (day uint))
  (map-get? daily-stats { date: day })
)

(define-read-only (get-address-last-active (address principal))
  (map-get? address-activity { address: address })
)
