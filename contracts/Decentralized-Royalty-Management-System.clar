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
