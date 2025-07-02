(define-constant CONTRACT_OWNER (as-contract tx-sender))
(define-constant ERR_NOT_AUTHORIZED (err u400))
(define-constant ERR_INVALID_CHAIN (err u401))
(define-constant ERR_BRIDGE_PAUSED (err u402))
(define-constant ERR_INVALID_SIGNATURE (err u403))
(define-constant ERR_DUPLICATE_TRANSACTION (err u404))

(define-data-var bridge-paused bool false)
(define-data-var nonce-counter uint u0)

(define-map supported-chains
    { chain_id: uint }
    { chain_name: (string-ascii 20), bridge_address: (string-ascii 64), active: bool })

(define-map cross-chain-royalties
    { token-id: uint, royalty-chain-id: uint }
    { creator: principal, royalty-rate: uint, total-collected: uint, last-sync: uint })

(define-map bridge-transactions
    { tx_hash: (string-ascii 64) }
    { token_id: uint, chain_id: uint, amount: uint, timestamp: uint, processed: bool })

(define-map chain-validators
    { validator: principal }
    { supported-chains: (list 10 uint), active: bool })

(define-map pending-distributions
    { distribution_id: uint }
    { token_id: uint, chain_id: uint, amount: uint, recipient: principal, status: uint })

(define-public (add-supported-chain (chain_id uint) (name (string-ascii 20)) (bridge_addr (string-ascii 64)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set supported-chains
            { chain_id: chain_id }
            { chain_name: name, bridge_address: bridge_addr, active: true }))))

(define-public (register-cross-chain-royalty (token_id uint) (chain_id uint) (creator principal) (rate uint))
    (begin
        (asserts! (not (var-get bridge-paused)) ERR_BRIDGE_PAUSED)
        (asserts! (is-some (map-get? supported-chains { chain_id: chain_id })) ERR_INVALID_CHAIN)
        (ok (map-set cross-chain-royalties
            { token-id: token_id, royalty-chain-id: chain_id }
            { creator: creator, royalty-rate: rate, total-collected: u0, last-sync: burn-block-height }))))

(define-public (process-cross-chain-sale (tx_hash (string-ascii 64)) (token_id uint) (chain_id uint) (sale_amount uint))
    (let ((royalty_info (unwrap! (map-get? cross-chain-royalties { token-id: token_id, royalty-chain-id: chain_id }) ERR_INVALID_CHAIN))
          (royalty_amount (/ (* sale_amount (get royalty-rate royalty_info)) u10000))
          (distribution_id (var-get nonce-counter)))
        (asserts! (not (var-get bridge-paused)) ERR_BRIDGE_PAUSED)
        (asserts! (is-none (map-get? bridge-transactions { tx_hash: tx_hash })) ERR_DUPLICATE_TRANSACTION)
        (map-set bridge-transactions
            { tx_hash: tx_hash }
            { token_id: token_id, chain_id: chain_id, amount: royalty_amount, timestamp: burn-block-height, processed: true })
        (map-set cross-chain-royalties
            { token-id: token_id, royalty-chain-id: chain_id }
            { creator: (get creator royalty_info),
              royalty-rate: (get royalty-rate royalty_info),
              total-collected: (+ (get total-collected royalty_info) royalty_amount),
              last-sync: burn-block-height })
        (map-set pending-distributions
            { distribution_id: distribution_id }
            { token_id: token_id, chain_id: chain_id, amount: royalty_amount, recipient: (get creator royalty_info), status: u0 })
        (var-set nonce-counter (+ distribution_id u1))
        (ok distribution_id)))

(define-public (add-validator (validator principal) (chains (list 10 uint)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set chain-validators
            { validator: validator }
            { supported-chains: chains, active: true }))))

(define-public (validate-cross-chain-transaction (tx_hash (string-ascii 64)) (token_id uint) (chain_id uint))
    (let ((validator_info (unwrap! (map-get? chain-validators { validator: tx-sender }) ERR_NOT_AUTHORIZED))
          (tx_info (unwrap! (map-get? bridge-transactions { tx_hash: tx_hash }) ERR_DUPLICATE_TRANSACTION)))
        (asserts! (get active validator_info) ERR_NOT_AUTHORIZED)
        (asserts! (is-some (index-of (get supported-chains validator_info) chain_id)) ERR_INVALID_CHAIN)
        (ok true)))

(define-public (execute-distribution (distribution_id uint))
    (let ((distribution (unwrap! (map-get? pending-distributions { distribution_id: distribution_id }) ERR_DUPLICATE_TRANSACTION)))
        (asserts! (is-eq (get status distribution) u0) ERR_DUPLICATE_TRANSACTION)
        (map-set pending-distributions
            { distribution_id: distribution_id }
            { token_id: (get token_id distribution),
              chain_id: (get chain_id distribution),
              amount: (get amount distribution),
              recipient: (get recipient distribution),
              status: u1 })
        (ok (get amount distribution))))

(define-public (toggle-bridge-pause)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (var-set bridge-paused (not (var-get bridge-paused))))))

(define-public (deactivate-chain (chain_id uint))
    (let ((chain_info (unwrap! (map-get? supported-chains { chain_id: chain_id }) ERR_INVALID_CHAIN)))
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (ok (map-set supported-chains
            { chain_id: chain_id }
            { chain_name: (get chain_name chain_info),
              bridge_address: (get bridge_address chain_info),
              active: false }))))

(define-read-only (get-cross-chain-royalty (token_id uint) (chain_id uint))
    (map-get? cross-chain-royalties { token-id: token_id, royalty-chain-id: chain_id }))

(define-read-only (get-supported-chain (chain_id uint))
    (map-get? supported-chains { chain_id: chain_id }))

(define-read-only (get-bridge-transaction (tx_hash (string-ascii 64)))
    (map-get? bridge-transactions { tx_hash: tx_hash }))

(define-read-only (get-pending-distribution (distribution_id uint))
    (map-get? pending-distributions { distribution_id: distribution_id }))

(define-read-only (is-bridge-paused)
    (var-get bridge-paused))

(define-read-only (get-validator-info (validator principal))
    (map-get? chain-validators { validator: validator }))

(define-read-only (calculate-cross-chain-total (token_id uint))
    (let ((ethereum_royalties (default-to { creator: CONTRACT_OWNER, royalty-rate: u0, total-collected: u0, last-sync: u0 }
                              (map-get? cross-chain-royalties { token-id: token_id, royalty-chain-id: u1 })))
          (polygon_royalties (default-to { creator: CONTRACT_OWNER, royalty-rate: u0, total-collected: u0, last-sync: u0 }
                             (map-get? cross-chain-royalties { token-id: token_id, royalty-chain-id: u137 })))
          (bsc_royalties (default-to { creator: CONTRACT_OWNER, royalty-rate: u0, total-collected: u0, last-sync: u0 }
                         (map-get? cross-chain-royalties { token-id: token_id, royalty-chain-id: u56 }))))
        (+ (+ (get total-collected ethereum_royalties) (get total-collected polygon_royalties)) (get total-collected bsc_royalties))))