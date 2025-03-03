;; ChainPulse Contract - Enhanced Version

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-data (err u101))
(define-constant err-not-initialized (err u102))
(define-constant err-overflow (err u103))
(define-constant err-contract-paused (err u104))
(define-constant max-transaction-amount u1000000000000)

;; Data Maps
(define-map daily-stats
  { date: uint }
  {
    tx-count: uint,
    active-addresses: uint,
    volume: uint,
    unique-addresses: uint
  }
)

(define-map address-activity
  { address: principal }
  { 
    last-active: uint,
    total-tx-count: uint
  }
)

;; Data Variables
(define-data-var current-day uint u0)
(define-data-var total-tx-count uint u0)
(define-data-var contract-paused bool false)
(define-data-var cumulative-volume uint u0)

;; Private Functions
(define-private (initialize-daily-stats (day uint))
  (map-set daily-stats
    { date: day }
    {
      tx-count: u0,
      active-addresses: u0,
      volume: u0,
      unique-addresses: u0
    }
  )
)

(define-private (update-total-tx-count)
  (match (+ (var-get total-tx-count) u1)
    total (begin
      (var-set total-tx-count total)
      (ok total))
    error err-overflow
  )
)

(define-private (update-address-stats (address principal))
  (let ((current-stats (default-to 
    { last-active: u0, total-tx-count: u0 }
    (map-get? address-activity { address: address }))))
    (map-set address-activity
      { address: address }
      {
        last-active: block-height,
        total-tx-count: (+ (get total-tx-count current-stats) u1)
      }
    )
  )
)

;; Public Functions
(define-public (record-transaction (amount uint))
  (let
    (
      (current-stats (match (get-daily-stats (var-get current-day))
        success success
        failure (begin
          (initialize-daily-stats (var-get current-day))
          (unwrap! (get-daily-stats (var-get current-day)) err-not-initialized)
        )
      ))
    )
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (and (> amount u0) (<= amount max-transaction-amount)) err-invalid-data)
    (try! (update-total-tx-count))
    (update-address-stats tx-sender)
    (var-set cumulative-volume (+ (var-get cumulative-volume) amount))
    (map-set daily-stats
      { date: (var-get current-day) }
      {
        tx-count: (+ (get tx-count current-stats) u1),
        active-addresses: (get active-addresses current-stats),
        volume: (+ (get volume current-stats) amount),
        unique-addresses: (get unique-addresses current-stats)
      }
    )
    (ok true)
  )
)

(define-public (record-active-address (address principal))
  (begin
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (update-address-stats address)
    (ok true)
  )
)

;; Admin Functions
(define-public (set-current-day (new-day uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (>= new-day (var-get current-day)) err-invalid-data)
    (var-set current-day new-day)
    (ok true)
  )
)

(define-public (toggle-contract-pause)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-paused (not (var-get contract-paused)))
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

(define-read-only (get-total-tx-count)
  (ok (var-get total-tx-count))
)

(define-read-only (get-cumulative-volume)
  (ok (var-get cumulative-volume))
)

(define-read-only (get-contract-state)
  (ok (not (var-get contract-paused)))
)
