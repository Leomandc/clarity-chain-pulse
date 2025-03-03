;; ChainPulse Contract - Enhanced Version

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-data (err u101))
(define-constant err-not-initialized (err u102))
(define-constant err-overflow (err u103))
(define-constant err-contract-paused (err u104))
(define-constant err-daily-limit-exceeded (err u105))
(define-constant max-transaction-amount u1000000000000)
(define-constant max-daily-volume u10000000000000)

;; Data Maps
(define-map daily-stats
  { date: uint }
  {
    tx-count: uint,
    active-addresses: uint,
    volume: uint,
    unique-addresses: uint,
    weighted-activity: uint
  }
)

(define-map address-activity
  { address: principal }
  { 
    last-active: uint,
    total-tx-count: uint,
    activity-score: uint
  }
)

;; Data Variables
(define-data-var current-day uint u0)
(define-data-var total-tx-count uint u0)
(define-data-var contract-paused bool false)
(define-data-var cumulative-volume uint u0)
(define-data-var pause-timeout uint u0)

;; Events
(define-data-var last-event-id uint u0)

(define-map events
  { id: uint }
  {
    event-type: (string-ascii 24),
    timestamp: uint,
    data: (optional (string-ascii 64))
  }
)

;; Private Functions
(define-private (emit-event (event-type (string-ascii 24)) (data (optional (string-ascii 64))))
  (let ((event-id (+ (var-get last-event-id) u1)))
    (var-set last-event-id event-id)
    (map-set events
      { id: event-id }
      {
        event-type: event-type,
        timestamp: block-height,
        data: data
      }
    )
    (ok event-id)
  )
)

(define-private (initialize-daily-stats (day uint))
  (begin
    (map-set daily-stats
      { date: day }
      {
        tx-count: u0,
        active-addresses: u0,
        volume: u0,
        unique-addresses: u0,
        weighted-activity: u0
      }
    )
    (emit-event "STATS_INITIALIZED" (some (concat "day_" (to-ascii day))))
  )
)

(define-private (calculate-activity-score (address principal) (tx-count uint))
  (let ((time-factor (- block-height 
        (get last-active (default-to { last-active: u0, total-tx-count: u0, activity-score: u0 }
          (map-get? address-activity { address: address }))))))
    (+ (* tx-count u100) (/ u10000 (+ time-factor u1)))
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
      (new-daily-volume (+ (get volume current-stats) amount))
    )
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (and (> amount u0) (<= amount max-transaction-amount)) err-invalid-data)
    (asserts! (<= new-daily-volume max-daily-volume) err-daily-limit-exceeded)
    
    (try! (update-total-tx-count))
    (let ((activity-score (calculate-activity-score tx-sender u1)))
      (map-set address-activity
        { address: tx-sender }
        {
          last-active: block-height,
          total-tx-count: (+ (get total-tx-count (default-to { last-active: u0, total-tx-count: u0, activity-score: u0 }
            (map-get? address-activity { address: tx-sender }))) u1),
          activity-score: activity-score
        }
      )
    )
    
    (var-set cumulative-volume (+ (var-get cumulative-volume) amount))
    (map-set daily-stats
      { date: (var-get current-day) }
      {
        tx-count: (+ (get tx-count current-stats) u1),
        active-addresses: (get active-addresses current-stats),
        volume: new-daily-volume,
        unique-addresses: (get unique-addresses current-stats),
        weighted-activity: (+ (get weighted-activity current-stats) u1)
      }
    )
    (emit-event "TRANSACTION_RECORDED" (some (concat "amount_" (to-ascii amount))))
    (ok true)
  )
)

;; [Rest of the contract functions remain unchanged...]
