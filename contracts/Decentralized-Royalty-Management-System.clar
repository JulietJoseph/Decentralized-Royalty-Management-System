;; Royalty Management System - Main Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_NFT_NOT_FOUND (err u101))
(define-constant ERR_INVALID_PERCENTAGE (err u102))

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
