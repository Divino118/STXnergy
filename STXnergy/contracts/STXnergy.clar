;; Renewable Trade Contract - Resource Exchange Smart Contract

;; Define constants
(define-constant admin tx-sender)
(define-constant err-not-admin (err u100))
(define-constant err-insufficient-funds (err u101))
(define-constant err-process-failed (err u102))
(define-constant err-invalid-value (err u103))
(define-constant err-invalid-quantity (err u104))
(define-constant err-percentage-exceeded (err u105))
(define-constant err-comp-failed (err u106))
(define-constant err-self-dealing (err u107))
(define-constant err-limit-breached (err u108))
(define-constant err-storage-overflow (err u109))

;; Define data variables
(define-data-var unit-price uint u100) ;; Price per kWh in microstacks
(define-data-var user-quota uint u10000) ;; Max kWh a user can trade
(define-data-var fee-rate uint u5) ;; Service fee percentage
(define-data-var refund-rate uint u90) ;; Refund percentage
(define-data-var system-cap uint u1000000) ;; Global resource cap
(define-data-var active-stock uint u0) ;; Current system-wide resource

;; Define data maps
(define-map holdings principal uint)
(define-map stx-wallet principal uint)
(define-map market {owner: principal} {volume: uint, cost: uint})

;; Private functions

;; Compute service fee
(define-private (calc-fee (amount uint))
  (/ (* amount (var-get fee-rate)) u100))

;; Compute refund amount
(define-private (calc-refund (quantity uint))
  (/ (* quantity (var-get unit-price) (var-get refund-rate)) u100))

;; Modify system stock
(define-private (adjust-stock (quantity int))
  (let (
    (current (var-get active-stock))
    (updated (if (< quantity 0)
                 (if (>= current (to-uint (- 0 quantity)))
                     (- current (to-uint (- 0 quantity)))
                     u0)
                 (+ current (to-uint quantity))))
  )
    (asserts! (<= updated (var-get system-cap)) err-limit-breached)
    (var-set active-stock updated)
    (ok true)))

;; Public functions

;; Set unit price (admin only)
(define-public (set-unit-price (price uint))
  (begin
    (asserts! (is-eq tx-sender admin) err-not-admin)
    (asserts! (> price u0) err-invalid-value)
    (var-set unit-price price)
    (ok true)))

;; Set service fee rate (admin only)
(define-public (set-fee-rate (rate uint))
  (begin
    (asserts! (is-eq tx-sender admin) err-not-admin)
    (asserts! (<= rate u100) err-percentage-exceeded)
    (var-set fee-rate rate)
    (ok true)))

;; Set refund rate (admin only)
(define-public (set-refund-rate (rate uint))
  (begin
    (asserts! (is-eq tx-sender admin) err-not-admin)
    (asserts! (<= rate u100) err-percentage-exceeded)
    (var-set refund-rate rate)
    (ok true)))

;; Set system capacity (admin only)
(define-public (set-system-cap (limit uint))
  (begin
    (asserts! (is-eq tx-sender admin) err-not-admin)
    (asserts! (>= limit (var-get active-stock)) err-storage-overflow)
    (var-set system-cap limit)
    (ok true)))

;; Add resource to market
(define-public (list-resource (quantity uint) (price uint))
  (let (
    (user-holding (default-to u0 (map-get? holdings tx-sender)))
    (existing (get volume (default-to {volume: u0, cost: u0} (map-get? market {owner: tx-sender}))))
    (new-listing (+ quantity existing))
  )
    (asserts! (> quantity u0) err-invalid-quantity)
    (asserts! (> price u0) err-invalid-value)
    (asserts! (>= user-holding new-listing) err-insufficient-funds)
    (try! (adjust-stock (to-int quantity)))
    (map-set market {owner: tx-sender} {volume: new-listing, cost: price})
    (ok true)))

;; Remove resource from market
(define-public (delist-resource (quantity uint))
  (let (
    (existing (get volume (default-to {volume: u0, cost: u0} (map-get? market {owner: tx-sender}))))
  )
    (asserts! (>= existing quantity) err-insufficient-funds)
    (try! (adjust-stock (to-int (- quantity))))
    (map-set market {owner: tx-sender} {volume: (- existing quantity), cost: (get cost (default-to {volume: u0, cost: u0} (map-get? market {owner: tx-sender})))})
    (ok true)))

;; Buy resource from seller
(define-public (purchase (seller principal) (quantity uint))
  (let (
    (listing (default-to {volume: u0, cost: u0} (map-get? market {owner: seller})))
    (total-price (* quantity (get cost listing)))
    (service-charge (calc-fee total-price))
    (final-cost (+ total-price service-charge))
    (seller-holding (default-to u0 (map-get? holdings seller)))
    (buyer-funds (default-to u0 (map-get? stx-wallet tx-sender)))
    (seller-funds (default-to u0 (map-get? stx-wallet seller)))
    (admin-funds (default-to u0 (map-get? stx-wallet admin)))
  )
    (asserts! (not (is-eq tx-sender seller)) err-self-dealing)
    (asserts! (> quantity u0) err-invalid-quantity)
    (asserts! (>= (get volume listing) quantity) err-insufficient-funds)
    (asserts! (>= seller-holding quantity) err-insufficient-funds)
    (asserts! (>= buyer-funds final-cost) err-insufficient-funds)
    
    (map-set holdings seller (- seller-holding quantity))
    (map-set market {owner: seller} {volume: (- (get volume listing) quantity), cost: (get cost listing)})
    (map-set stx-wallet tx-sender (- buyer-funds final-cost))
    (map-set holdings tx-sender (+ (default-to u0 (map-get? holdings tx-sender)) quantity))
    (map-set stx-wallet seller (+ seller-funds total-price))
    (map-set stx-wallet admin (+ admin-funds service-charge))
    (ok true)))
