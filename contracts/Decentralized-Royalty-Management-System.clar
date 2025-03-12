;; Royalty Management System - Main Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_NFT_NOT_FOUND (err u101))
(define-constant ERR_INVALID_PERCENTAGE (err u102))
(define-constant ERR_INVALID_INPUT (err u103))

;; Data Maps
(define-map nft-royalties 
    { token-id: uint }
    { creator: principal, base-royalty: uint, sale-count: uint, current-royalty: uint })

;; Public Functions
(define-public (register-nft (token-id uint) (base-royalty uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (<= base-royalty u100) ERR_INVALID_PERCENTAGE)
        (ok (map-set nft-royalties
            { token-id: token-id }
            { creator: tx-sender, 
              base-royalty: base-royalty,
              sale-count: u0,
              current-royalty: base-royalty }))))

(define-public (update-royalty (token-id uint))
    (let ((nft-data (unwrap! (map-get? nft-royalties { token-id: token-id }) ERR_NFT_NOT_FOUND))
          (new-sale-count (+ (get sale-count nft-data) u1))
          (adjusted-royalty (calculate-dynamic-royalty 
                            (get base-royalty nft-data) 
                            new-sale-count)))
        (ok (map-set nft-royalties
            { token-id: token-id }
            { creator: (get creator nft-data),
              base-royalty: (get base-royalty nft-data),
              sale-count: new-sale-count,
              current-royalty: adjusted-royalty }))))

;; Read-only Functions
(define-read-only (get-nft-royalty (token-id uint))
    (map-get? nft-royalties { token-id: token-id }))

(define-read-only (calculate-dynamic-royalty (base-royalty uint) (sale-count uint))
    (let ((royalty-reduction (mul-down base-royalty u5 sale-count)))
        (if (> royalty-reduction base-royalty)
            u1
            (- base-royalty royalty-reduction))))

;; Internal Functions
(define-private (mul-down (a uint) (b uint) (c uint))
    (/ (* a b) (* u100 c)))


;; Add new data map for royalty splits
(define-map royalty-splits
    { token-id: uint }
    { beneficiaries: (list 10 principal), 
      shares: (list 10 uint) })

(define-public (set-royalty-split (token-id uint) (beneficiaries (list 10 principal)) (shares (list 10 uint)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set royalty-splits
            { token-id: token-id }
            { beneficiaries: beneficiaries,
              shares: shares }))))


(define-map royalty-tiers
    { tier-level: uint }
    { min-price: uint, royalty-multiplier: uint })

(define-public (set-royalty-tier (tier-level uint) (min-price uint) (multiplier uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set royalty-tiers
            { tier-level: tier-level }
            { min-price: min-price, 
              royalty-multiplier: multiplier }))))


(define-map whitelisted-addresses
    { address: principal }
    { discount-percentage: uint })

(define-public (add-to-whitelist (address principal) (discount uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (<= discount u50) ERR_INVALID_PERCENTAGE)
        (ok (map-set whitelisted-addresses
            { address: address }
            { discount-percentage: discount }))))


(define-map royalty-locks
    { token-id: uint }
    { locked-until: uint, 
      locked-percentage: uint })

(define-public (set-royalty-lock (token-id uint) (lock-period uint) (locked-rate uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set royalty-locks
            { token-id: token-id }
            { locked-until: (+ burn-block-height lock-period),
              locked-percentage: locked-rate }))))


(define-map market-incentives
    { market-address: principal }
    { royalty-discount: uint })

(define-public (set-market-incentive (market principal) (discount uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set market-incentives
            { market-address: market }
            { royalty-discount: discount }))))


(define-private (register-nft-internal (token-id uint) (base-royalty uint))
    (begin
        (asserts! (<= base-royalty u100) ERR_INVALID_PERCENTAGE)
        (map-set nft-royalties
            { token-id: token-id }
            { creator: tx-sender, 
              base-royalty: base-royalty,
              sale-count: u0,
              current-royalty: base-royalty })
        (ok true)))




(define-map royalty-boosts
    { token-id: uint }
    { boost-start: uint, boost-end: uint, boost-percentage: uint })

(define-public (set-royalty-boost (token-id uint) (duration uint) (boost uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set royalty-boosts
            { token-id: token-id }
            { boost-start: burn-block-height,
              boost-end: (+ burn-block-height duration),
              boost-percentage: boost }))))



(define-public (register-multiple-nfts (token-ids (list 50 uint)) (base-royalties (list 50 uint)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (map register-nft-internal token-ids base-royalties)
        (ok true)))


(define-map royalty-history
    { token-id: uint, sale-id: uint }
    { amount: uint, timestamp: uint, buyer: principal, seller: principal })

(define-public (record-royalty-payment (token-id uint) (amount uint) (buyer principal) (seller principal))
    (let ((sale-count (unwrap! (get sale-count (map-get? nft-royalties { token-id: token-id })) ERR_NFT_NOT_FOUND)))
        (ok (map-set royalty-history
            { token-id: token-id, sale-id: sale-count }
            { amount: amount, 
              timestamp: burn-block-height,
              buyer: buyer,
              seller: seller }))))


(define-data-var royalty-paused bool false)

(define-public (toggle-royalty-pause)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (var-set royalty-paused (not (var-get royalty-paused))))))


(define-map collection-royalties
    { collection-id: uint }
    { base-royalty: uint, override-individual: bool })

(define-public (set-collection-royalty (collection-id uint) (royalty uint) (override bool))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set collection-royalties
            { collection-id: collection-id }
            { base-royalty: royalty, override-individual: override }))))


(define-map distribution-schedule
    { token-id: uint }
    { interval: uint, last-distribution: uint, auto-distribute: bool })

(define-public (set-distribution-schedule (token-id uint) (interval uint) (auto-distribute bool))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set distribution-schedule
            { token-id: token-id }
            { interval: interval,
              last-distribution: burn-block-height,
              auto-distribute: auto-distribute }))))


(define-map referral-rewards
    { referrer: principal }
    { reward-percentage: uint, total-earned: uint })

(define-public (register-referrer (referrer principal) (reward-percentage uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set referral-rewards
            { referrer: referrer }
            { reward-percentage: reward-percentage, total-earned: u0 }))))



(define-map milestone-bonuses
    { token-id: uint }
    { sales-target: uint, bonus-percentage: uint, achieved: bool })

(define-public (set-milestone-bonus (token-id uint) (target uint) (bonus uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set milestone-bonuses
            { token-id: token-id }
            { sales-target: target,
              bonus-percentage: bonus,
              achieved: false }))))



(define-map market-royalty-caps
    { market-address: principal }
    { max-royalty: uint, min-royalty: uint })

(define-public (set-market-caps (market principal) (max uint) (min uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set market-royalty-caps
            { market-address: market }
            { max-royalty: max, min-royalty: min }))))


(define-map royalty-exemptions
    { address: principal }
    { exempt-until: uint, reason: (string-ascii 50) })

(define-public (grant-exemption (address principal) (duration uint) (reason (string-ascii 50)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set royalty-exemptions
            { address: address }
            { exempt-until: (+ burn-block-height duration),
              reason: reason }))))


;; Define event periods map
(define-map special-events
    { event-id: uint }
    { start-time: uint, end-time: uint, boost-percentage: uint, event-name: (string-ascii 50) })

(define-public (create-special-event (event-id uint) (duration uint) (boost uint) (name (string-ascii 50)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set special-events
            { event-id: event-id }
            { start-time: burn-block-height,
              end-time: (+ burn-block-height duration),
              boost-percentage: boost,
              event-name: name }))))


;; Define bundle map
(define-map royalty-bundles
    { bundle-id: uint }
    { token-ids: (list 50 uint), bundle-discount: uint })

(define-public (create-royalty-bundle (bundle-id uint) (tokens (list 50 uint)) (discount uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (<= discount u50) ERR_INVALID_PERCENTAGE)
        (ok (map-set royalty-bundles
            { bundle-id: bundle-id }
            { token-ids: tokens,
              bundle-discount: discount }))))


;; Define buyer tiers
(define-map buyer-tiers
    { buyer: principal }
    { purchase-count: uint, tier-level: uint, discount: uint })

(define-read-only (calculate-tier-level (purchase-count uint))
    (if (>= purchase-count u100)
        u3
        (if (>= purchase-count u50)
            u2
            (if (>= purchase-count u10)
                u1
                u0))))

(define-read-only (calculate-tier-discount (purchase-count uint))
    (if (>= purchase-count u100)
        u30
        (if (>= purchase-count u50)
            u20
            (if (>= purchase-count u10)
                u10
                u0))))

(define-public (update-buyer-tier (buyer principal))
    (let ((current-data (default-to 
            { purchase-count: u0, tier-level: u0, discount: u0 }
            (map-get? buyer-tiers { buyer: buyer }))))
        (ok (map-set buyer-tiers
            { buyer: buyer }
            { purchase-count: (+ (get purchase-count current-data) u1),
              tier-level: (calculate-tier-level (+ (get purchase-count current-data) u1)),
              discount: (calculate-tier-discount (+ (get purchase-count current-data) u1)) }))))


;; Define price tiers
(define-map price-based-royalties
    { token-id: uint }
    { tier1-threshold: uint, tier1-royalty: uint,
      tier2-threshold: uint, tier2-royalty: uint,
      tier3-threshold: uint, tier3-royalty: uint })

(define-public (set-price-tiers (token-id uint) (t1-threshold uint) (t1-royalty uint)
                               (t2-threshold uint) (t2-royalty uint)
                               (t3-threshold uint) (t3-royalty uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set price-based-royalties
            { token-id: token-id }
            { tier1-threshold: t1-threshold, tier1-royalty: t1-royalty,
              tier2-threshold: t2-threshold, tier2-royalty: t2-royalty,
              tier3-threshold: t3-threshold, tier3-royalty: t3-royalty }))))


;; Define distribution schedules
(define-map royalty-schedules
    { token-id: uint }
    { daily-limit: uint, weekly-limit: uint, monthly-limit: uint,
      last-distribution: uint, total-distributed: uint })

(define-public (set-distribution-limits (token-id uint) (daily uint) (weekly uint) (monthly uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set royalty-schedules
            { token-id: token-id }
            { daily-limit: daily,
              weekly-limit: weekly,
              monthly-limit: monthly,
              last-distribution: burn-block-height,
              total-distributed: u0 }))))



;; Define community pool
(define-map community-pool
    { pool-id: uint }
    { total-amount: uint, participants: (list 100 principal), share-percentages: (list 100 uint) })

(define-public (create-community-pool (pool-id uint) (participants (list 100 principal)) (shares (list 100 uint)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set community-pool
            { pool-id: pool-id }
            { total-amount: u0,
              participants: participants,
              share-percentages: shares }))))


;; Define promotional rates
(define-map promotional-rates
    { promo-id: uint }
    { start-block: uint, end-block: uint, discount-rate: uint, active: bool })

(define-public (create-promotion (promo-id uint) (duration uint) (discount uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set promotional-rates
            { promo-id: promo-id }
            { start-block: burn-block-height,
              end-block: (+ burn-block-height duration),
              discount-rate: discount,
              active: true }))))
