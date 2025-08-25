;; BinaryPro - Prediction Framework for Binary Events
;; A comprehensive prediction market where participants wager PWR tokens on binary outcomes
;; Oracle system finalizes results and distributes payouts to winning participants

;; Define tokens
(define-fungible-token PWR) ;; Prediction Wager Rewards token
(define-fungible-token ORACLE) ;; Oracle governance token

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u700))
(define-constant ERR-EVENT-NOT-FOUND (err u701))
(define-constant ERR-EVENT-CLOSED (err u702))
(define-constant ERR-EVENT-ACTIVE (err u703))
(define-constant ERR-INVALID-OUTCOME (err u704))
(define-constant ERR-INSUFFICIENT-BALANCE (err u705))
(define-constant ERR-INVALID-AMOUNT (err u706))
(define-constant ERR-TRANSFER-FAILED (err u707))
(define-constant ERR-ALREADY-RESOLVED (err u708))
(define-constant ERR-BET-NOT-FOUND (err u709))
(define-constant ERR-INVALID-ORACLE (err u710))
(define-constant ERR-ORACLE-DISPUTE (err u711))
(define-constant ERR-MARKET-PAUSED (err u712))

;; Event status constants
(define-constant STATUS-OPEN u1)
(define-constant STATUS-CLOSED u2)
(define-constant STATUS-RESOLVED u3)
(define-constant STATUS-DISPUTED u4)
(define-constant STATUS-CANCELLED u5)

;; Outcome constants
(define-constant OUTCOME-YES u1)
(define-constant OUTCOME-NO u2)
(define-constant OUTCOME-INVALID u3)

;; Protocol parameters
(define-constant MIN-BET-AMOUNT u1000) ;; Minimum bet: 1000 PWR
(define-constant MAX-BET-AMOUNT u10000000) ;; Maximum bet: 10M PWR
(define-constant ORACLE-FEE u25000) ;; 2.5% oracle fee
(define-constant PLATFORM-FEE u15000) ;; 1.5% platform fee
(define-constant MIN-EVENT-DURATION u144) ;; ~1 day minimum
(define-constant MAX-EVENT_DURATION u14400) ;; ~100 days maximum
(define-constant DISPUTE-PERIOD u1440) ;; ~10 days dispute period
(define-constant PRECISION u1000000) ;; 6 decimal precision

;; Data variables
(define-data-var next-event-id uint u1)
(define-data-var next-bet-id uint u1)
(define-data-var total-volume uint u0)
(define-data-var total-events uint u0)
(define-data-var market-paused bool false)
(define-data-var oracle-admin (optional principal) none)
(define-data-var dispute-resolver (optional principal) none)

;; Event definitions
(define-map events
    uint ;; event-id
    {
        creator: principal,
        title: (string-ascii 128),
        description: (string-ascii 512),
        category: (string-ascii 64),
        source-url: (optional (string-ascii 256)),
        start-time: uint,
        end-time: uint,
        resolution-time: uint,
        status: uint,
        outcome: (optional uint),
        total-yes-amount: uint,
        total-no-amount: uint,
        total-bets: uint,
        oracle: (optional principal),
        created-at: uint
    }
)

;; Individual bets
(define-map bets
    uint ;; bet-id
    {
        event-id: uint,
        bettor: principal,
        outcome: uint,
        amount: uint,
        odds: uint,
        potential-payout: uint,
        claimed: bool,
        timestamp: uint
    }
)

;; User betting history
(define-map user-bets
    principal
    {
        total-bets: uint,
        total-wagered: uint,
        total-won: uint,
        win-rate: uint,
        active-bets: (list 32 uint) ;; bet-ids
    }
)

;; Event betting pools
(define-map event-pools
    uint ;; event-id
    {
        yes-pool: uint,
        no-pool: uint,
        total-pool: uint,
        yes-bettors: uint,
        no-bettors: uint,
        oracle-fee-collected: uint,
        platform-fee-collected: uint
    }
)

;; Oracle system
(define-map oracles
    principal
    {
        name: (string-ascii 64),
        reputation: uint,
        total-resolutions: uint,
        correct-resolutions: uint,
        disputed-resolutions: uint,
        active: bool,
        stake-amount: uint,
        last-activity: uint
    }
)

;; Oracle resolutions
(define-map oracle-resolutions
    {
        event-id: uint,
        oracle: principal
    }
    {
        outcome: uint,
        confidence: uint,
        timestamp: uint,
        evidence: (string-ascii 256)
    }
)

;; Dispute system
(define-map disputes
    uint ;; event-id
    {
        disputer: principal,
        reason: (string-ascii 256),
        disputed-outcome: uint,
        proposed-outcome: uint,
        stake-amount: uint,
        status: uint,
        created-at: uint,
        resolved-at: (optional uint)
    }
)

;; Event categories
(define-map categories
    (string-ascii 64)
    {
        name: (string-ascii 64),
        description: (string-ascii 256),
        total-events: uint,
        total-volume: uint,
        active: bool
    }
)

;; User event creation history
(define-map user-events
    principal
    {
        events-created: uint,
        total-volume-generated: uint,
        successful-events: uint,
        last-event: uint
    }
)

;; Read-only functions

;; Get event details
(define-read-only (get-event (event-id uint))
    (map-get? events event-id)
)

;; Get bet details
(define-read-only (get-bet (bet-id uint))
    (map-get? bets bet-id)
)

;; Get user betting history
(define-read-only (get-user-bets (user principal))
    (map-get? user-bets user)
)

;; Get event pool information
(define-read-only (get-event-pool (event-id uint))
    (map-get? event-pools event-id)
)

;; Get oracle information
(define-read-only (get-oracle (oracle principal))
    (map-get? oracles oracle)
)

;; Get oracle resolution
(define-read-only (get-oracle-resolution (event-id uint) (oracle principal))
    (map-get? oracle-resolutions {event-id: event-id, oracle: oracle})
)

;; Get dispute information
(define-read-only (get-dispute (event-id uint))
    (map-get? disputes event-id)
)

;; Get category information
(define-read-only (get-category (category-name (string-ascii 64)))
    (map-get? categories category-name)
)

;; Calculate current odds for an outcome
(define-read-only (calculate-odds (event-id uint) (outcome uint))
    (match (get-event-pool event-id)
        pool (let (
            (yes-pool (get yes-pool pool))
            (no-pool (get no-pool pool))
            (total-pool (+ yes-pool no-pool))
        )
            (if (> total-pool u0)
                (if (is-eq outcome OUTCOME-YES)
                    (ok (if (> yes-pool u0) (/ (* total-pool PRECISION) yes-pool) PRECISION))
                    (ok (if (> no-pool u0) (/ (* total-pool PRECISION) no-pool) PRECISION))
                )
                (ok PRECISION) ;; 1:1 odds if no bets yet
            )
        )
        ERR-EVENT-NOT-FOUND
    )
)

;; Calculate potential payout for a bet
(define-read-only (calculate-payout (event-id uint) (outcome uint) (amount uint))
    (match (calculate-odds event-id outcome)
        odds (let (
            (gross-payout (/ (* amount odds) PRECISION))
            (oracle-fee-amount (/ (* gross-payout ORACLE-FEE) PRECISION))
            (platform-fee-amount (/ (* gross-payout PLATFORM-FEE) PRECISION))
            (net-payout (- gross-payout (+ oracle-fee-amount platform-fee-amount)))
        )
            (ok {
                gross-payout: gross-payout,
                oracle-fee: oracle-fee-amount,
                platform-fee: platform-fee-amount,
                net-payout: net-payout
            })
        )
        error-code (err error-code)
    )
)

;; Get market statistics
(define-read-only (get-market-stats)
    {
        total-events: (var-get total-events),
        total-volume: (var-get total-volume),
        active-events: (- (var-get next-event-id) u1),
        market-paused: (var-get market-paused)
    }
)

;; Check if event is bettable
(define-read-only (is-event-bettable (event-id uint))
    (match (get-event event-id)
        event (let (
            (current-block stacks-block-height)
            (status (get status event))
            (end-time (get end-time event))
        )
            (ok (and 
                (is-eq status STATUS-OPEN)
                (< current-block end-time)
                (not (var-get market-paused))
            ))
        )
        ERR-EVENT-NOT-FOUND
    )
)

;; Get user's active bets for an event
(define-read-only (get-user-event-bets (user principal) (event-id uint))
    (let (
        (user-bet-history (default-to {
            total-bets: u0,
            total-wagered: u0,
            total-won: u0,
            win-rate: u0,
            active-bets: (list)
        } (get-user-bets user)))
    )
        ;; Simplified implementation - would filter by event-id in practice
        (ok (get active-bets user-bet-history))
    )
)

;; Public functions

;; Create a new prediction event
(define-public (create-event
    (title (string-ascii 128))
    (description (string-ascii 512))
    (category (string-ascii 64))
    (source-url (optional (string-ascii 256)))
    (duration uint)
    (resolution-delay uint))
    (let (
        (event-id (var-get next-event-id))
        (current-block stacks-block-height)
        (end-time (+ current-block duration))
        (resolution-time (+ end-time resolution-delay))
    )
        (asserts! (not (var-get market-paused)) ERR-MARKET-PAUSED)
        (asserts! (>= duration MIN-EVENT-DURATION) ERR-INVALID-AMOUNT)
        (asserts! (<= duration MAX-EVENT_DURATION) ERR-INVALID-AMOUNT)
        (asserts! (>= resolution-delay u144) ERR-INVALID-AMOUNT) ;; Min 1 day for resolution
        
        ;; Create event
        (map-set events event-id {
            creator: tx-sender,
            title: title,
            description: description,
            category: category,
            source-url: source-url,
            start-time: current-block,
            end-time: end-time,
            resolution-time: resolution-time,
            status: STATUS-OPEN,
            outcome: none,
            total-yes-amount: u0,
            total-no-amount: u0,
            total-bets: u0,
            oracle: none,
            created-at: current-block
        })
        
        ;; Initialize event pool
        (map-set event-pools event-id {
            yes-pool: u0,
            no-pool: u0,
            total-pool: u0,
            yes-bettors: u0,
            no-bettors: u0,
            oracle-fee-collected: u0,
            platform-fee-collected: u0
        })
        
        ;; Update category statistics
        (update-category-stats category u1 u0)
        
        ;; Update user event creation history
        (update-user-event-history tx-sender u1 u0 u0)
        
        ;; Update global statistics
        (var-set next-event-id (+ event-id u1))
        (var-set total-events (+ (var-get total-events) u1))
        
        (ok event-id)
    )
)

;; Place a bet on an event outcome
(define-public (place-bet (event-id uint) (outcome uint) (amount uint))
    (let (
        (bet-id (var-get next-bet-id))
        (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
        (current-block stacks-block-height)
        (odds (unwrap! (calculate-odds event-id outcome) ERR-EVENT-NOT-FOUND))
        (payout-info (unwrap! (calculate-payout event-id outcome amount) ERR-EVENT-NOT-FOUND))
    )
        (asserts! (not (var-get market-paused)) ERR-MARKET-PAUSED)
        (asserts! (is-eq (get status event) STATUS-OPEN) ERR-EVENT-CLOSED)
        (asserts! (< current-block (get end-time event)) ERR-EVENT-CLOSED)
        (asserts! (or (is-eq outcome OUTCOME-YES) (is-eq outcome OUTCOME-NO)) ERR-INVALID-OUTCOME)
        (asserts! (>= amount MIN-BET-AMOUNT) ERR-INVALID-AMOUNT)
        (asserts! (<= amount MAX-BET-AMOUNT) ERR-INVALID-AMOUNT)
        (asserts! (>= (ft-get-balance PWR tx-sender) amount) ERR-INSUFFICIENT-BALANCE)
        
        ;; Transfer bet amount to contract
        (match (ft-transfer? PWR amount tx-sender (as-contract tx-sender))
            success (begin
                ;; Create bet record
                (map-set bets bet-id {
                    event-id: event-id,
                    bettor: tx-sender,
                    outcome: outcome,
                    amount: amount,
                    odds: odds,
                    potential-payout: (get net-payout payout-info),
                    claimed: false,
                    timestamp: current-block
                })
                
                ;; Update event pools
                (update-event-pools event-id outcome amount)
                
                ;; Update event statistics
                (update-event-stats event-id outcome amount)
                
                ;; Update user betting history
                (update-user-betting-history tx-sender bet-id amount)
                
                ;; Update global volume
                (var-set total-volume (+ (var-get total-volume) amount))
                (var-set next-bet-id (+ bet-id u1))
                
                (ok bet-id)
            )
            error ERR-TRANSFER-FAILED
        )
    )
)

;; Resolve an event (oracle only)
(define-public (resolve-event (event-id uint) (outcome uint) (evidence (string-ascii 256)))
    (let (
        (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
        (current-block stacks-block-height)
        (oracle-info (unwrap! (get-oracle tx-sender) ERR-INVALID-ORACLE))
    )
        (asserts! (not (var-get market-paused)) ERR-MARKET-PAUSED)
        (asserts! (get active oracle-info) ERR-INVALID-ORACLE)
        (asserts! (is-eq (get status event) STATUS-CLOSED) ERR-EVENT-ACTIVE)
        (asserts! (>= current-block (get resolution-time event)) ERR-EVENT-ACTIVE)
        (asserts! (or (is-eq outcome OUTCOME-YES) 
                     (is-eq outcome OUTCOME-NO) 
                     (is-eq outcome OUTCOME-INVALID)) ERR-INVALID-OUTCOME)
        
        ;; Record oracle resolution
        (map-set oracle-resolutions {event-id: event-id, oracle: tx-sender} {
            outcome: outcome,
            confidence: u100, ;; Full confidence for now
            timestamp: current-block,
            evidence: evidence
        })
        
        ;; Update event with resolution
        (map-set events event-id 
            (merge event {
                status: STATUS-RESOLVED,
                outcome: (some outcome),
                oracle: (some tx-sender)
            })
        )
        
        ;; Update oracle statistics
        (update-oracle-stats tx-sender u1 u1 u0)
        
        ;; Distribute fees if valid outcome
        (if (not (is-eq outcome OUTCOME-INVALID))
            (unwrap! (distribute-fees event-id) ERR-TRANSFER-FAILED)
            true
        )
        
        (ok outcome)
    )
)

;; Claim winnings from a resolved bet
(define-public (claim-winnings (bet-id uint))
    (let (
        (bet (unwrap! (get-bet bet-id) ERR-BET-NOT-FOUND))
        (event (unwrap! (get-event (get event-id bet)) ERR-EVENT-NOT-FOUND))
        (event-outcome (unwrap! (get outcome event) ERR-EVENT-ACTIVE))
    )
        (asserts! (is-eq (get bettor bet) tx-sender) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status event) STATUS-RESOLVED) ERR-EVENT-ACTIVE)
        (asserts! (not (get claimed bet)) ERR-ALREADY-RESOLVED)
        
        ;; Check if bet won
        (if (or (is-eq (get outcome bet) event-outcome)
               (is-eq event-outcome OUTCOME-INVALID)) ;; Refund if invalid
            (let (
                (payout-amount (if (is-eq event-outcome OUTCOME-INVALID)
                                  (get amount bet) ;; Full refund for invalid
                                  (get potential-payout bet)))
            )
                ;; Transfer winnings
                (match (as-contract (ft-transfer? PWR payout-amount tx-sender tx-sender))
                    success (begin
                        ;; Mark bet as claimed
                        (map-set bets bet-id (merge bet {claimed: true}))
                        
                        ;; Update user statistics
                        (update-user-win-stats tx-sender payout-amount)
                        
                        (ok payout-amount)
                    )
                    error ERR-TRANSFER-FAILED
                )
            )
            ;; Bet lost
            (begin
                (map-set bets bet-id (merge bet {claimed: true}))
                (ok u0)
            )
        )
    )
)

;; Close event for betting (automatic when end-time reached)
(define-public (close-event (event-id uint))
    (let (
        (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
        (current-block stacks-block-height)
    )
        (asserts! (is-eq (get status event) STATUS-OPEN) ERR-EVENT-CLOSED)
        (asserts! (>= current-block (get end-time event)) ERR-EVENT-ACTIVE)
        
        ;; Update event status to closed
        (map-set events event-id 
            (merge event {status: STATUS-CLOSED})
        )
        
        (ok true)
    )
)

;; Dispute an oracle resolution
(define-public (dispute-resolution (event-id uint) (proposed-outcome uint) (reason (string-ascii 256)) (stake-amount uint))
    (let (
        (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
        (current-block stacks-block-height)
        (resolution-time (get resolution-time event))
    )
        (asserts! (is-eq (get status event) STATUS-RESOLVED) ERR-EVENT-ACTIVE)
        (asserts! (< current-block (+ resolution-time DISPUTE-PERIOD)) ERR-ORACLE-DISPUTE)
        (asserts! (>= stake-amount u10000) ERR-INVALID-AMOUNT) ;; Minimum dispute stake
        (asserts! (>= (ft-get-balance PWR tx-sender) stake-amount) ERR-INSUFFICIENT-BALANCE)
        
        ;; Transfer dispute stake
        (match (ft-transfer? PWR stake-amount tx-sender (as-contract tx-sender))
            success (begin
                ;; Create dispute record
                (map-set disputes event-id {
                    disputer: tx-sender,
                    reason: reason,
                    disputed-outcome: (unwrap-panic (get outcome event)),
                    proposed-outcome: proposed-outcome,
                    stake-amount: stake-amount,
                    status: STATUS-DISPUTED,
                    created-at: current-block,
                    resolved-at: none
                })
                
                ;; Update event status
                (map-set events event-id 
                    (merge event {status: STATUS-DISPUTED})
                )
                
                (ok true)
            )
            error ERR-TRANSFER-FAILED
        )
    )
)

;; Register as an oracle
(define-public (register-oracle (name (string-ascii 64)) (stake-amount uint))
    (begin
        (asserts! (>= stake-amount u100000) ERR-INVALID-AMOUNT) ;; Minimum oracle stake
        (asserts! (>= (ft-get-balance ORACLE tx-sender) stake-amount) ERR-INSUFFICIENT-BALANCE)
        
        ;; Transfer oracle stake
        (match (ft-transfer? ORACLE stake-amount tx-sender (as-contract tx-sender))
            success (begin
                (map-set oracles tx-sender {
                    name: name,
                    reputation: u100, ;; Starting reputation
                    total-resolutions: u0,
                    correct-resolutions: u0,
                    disputed-resolutions: u0,
                    active: true,
                    stake-amount: stake-amount,
                    last-activity: stacks-block-height
                })
                (ok true)
            )
            error ERR-TRANSFER-FAILED
        )
    )
)

;; Create a new category
(define-public (create-category (name (string-ascii 64)) (description (string-ascii 256)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (asserts! (is-none (get-category name)) ERR-ALREADY-RESOLVED)
        
        (map-set categories name {
            name: name,
            description: description,
            total-events: u0,
            total-volume: u0,
            active: true
        })
        
        (ok true)
    )
)

;; Update event pools
(define-private (update-event-pools (event-id uint) (outcome uint) (amount uint))
    (let (
        (current-pool (default-to {
            yes-pool: u0,
            no-pool: u0,
            total-pool: u0,
            yes-bettors: u0,
            no-bettors: u0,
            oracle-fee-collected: u0,
            platform-fee-collected: u0
        } (get-event-pool event-id)))
    )
        (map-set event-pools event-id {
            yes-pool: (if (is-eq outcome OUTCOME-YES) 
                         (+ (get yes-pool current-pool) amount)
                         (get yes-pool current-pool)),
            no-pool: (if (is-eq outcome OUTCOME-NO) 
                        (+ (get no-pool current-pool) amount)
                        (get no-pool current-pool)),
            total-pool: (+ (get total-pool current-pool) amount),
            yes-bettors: (if (is-eq outcome OUTCOME-YES) 
                           (+ (get yes-bettors current-pool) u1)
                           (get yes-bettors current-pool)),
            no-bettors: (if (is-eq outcome OUTCOME-NO) 
                          (+ (get no-bettors current-pool) u1)
                          (get no-bettors current-pool)),
            oracle-fee-collected: (get oracle-fee-collected current-pool),
            platform-fee-collected: (get platform-fee-collected current-pool)
        })
        true
    )
)

;; Update event statistics
(define-private (update-event-stats (event-id uint) (outcome uint) (amount uint))
    (let (
        (event (unwrap-panic (get-event event-id)))
    )
        (map-set events event-id 
            (merge event {
                total-yes-amount: (if (is-eq outcome OUTCOME-YES) 
                                    (+ (get total-yes-amount event) amount)
                                    (get total-yes-amount event)),
                total-no-amount: (if (is-eq outcome OUTCOME-NO) 
                                   (+ (get total-no-amount event) amount)
                                   (get total-no-amount event)),
                total-bets: (+ (get total-bets event) u1)
            })
        )
        true
    )
)

;; Update user betting history
(define-private (update-user-betting-history (user principal) (bet-id uint) (amount uint))
    (let (
        (current-history (default-to {
            total-bets: u0,
            total-wagered: u0,
            total-won: u0,
            win-rate: u0,
            active-bets: (list)
        } (get-user-bets user)))
    )
        (match (as-max-len? (append (get active-bets current-history) bet-id) u32)
            new-active-bets (begin
                (map-set user-bets user {
                    total-bets: (+ (get total-bets current-history) u1),
                    total-wagered: (+ (get total-wagered current-history) amount),
                    total-won: (get total-won current-history),
                    win-rate: (get win-rate current-history),
                    active-bets: new-active-bets
                })
                true
            )
            false ;; Failed to append
        )
    )
)

;; Update user win statistics
(define-private (update-user-win-stats (user principal) (winnings uint))
    (let (
        (current-history (unwrap-panic (get-user-bets user)))
        (new-total-won (+ (get total-won current-history) winnings))
        (total-wagered (get total-wagered current-history))
    )
        (map-set user-bets user 
            (merge current-history {
                total-won: new-total-won,
                win-rate: (if (> total-wagered u0) 
                            (/ (* new-total-won u100) total-wagered) 
                            u0)
            })
        )
        true
    )
)

;; Update oracle statistics
(define-private (update-oracle-stats (oracle principal) (resolutions uint) (correct uint) (disputed uint))
    (let (
        (current-stats (unwrap-panic (get-oracle oracle)))
        (new-total (+ (get total-resolutions current-stats) resolutions))
        (new-correct (+ (get correct-resolutions current-stats) correct))
    )
        (map-set oracles oracle 
            (merge current-stats {
                total-resolutions: new-total,
                correct-resolutions: new-correct,
                disputed-resolutions: (+ (get disputed-resolutions current-stats) disputed),
                reputation: (if (> new-total u0) (/ (* new-correct u100) new-total) u100),
                last-activity: stacks-block-height
            })
        )
        true
    )
)

;; Update category statistics
(define-private (update-category-stats (category-name (string-ascii 64)) (event-count uint) (volume uint))
    (match (get-category category-name)
        category (begin
            (map-set categories category-name 
                (merge category {
                    total-events: (+ (get total-events category) event-count),
                    total-volume: (+ (get total-volume category) volume)
                })
            )
            true
        )
        false ;; Category doesn't exist
    )
)

;; Update user event creation history
(define-private (update-user-event-history (user principal) (event-count uint) (volume uint) (successful uint))
    (let (
        (current-history (default-to {
            events-created: u0,
            total-volume-generated: u0,
            successful-events: u0,
            last-event: u0
        } (map-get? user-events user)))
    )
        (map-set user-events user {
            events-created: (+ (get events-created current-history) event-count),
            total-volume-generated: (+ (get total-volume-generated current-history) volume),
            successful-events: (+ (get successful-events current-history) successful),
            last-event: stacks-block-height
        })
        true
    )
)

;; Distribute fees to oracle and platform
(define-private (distribute-fees (event-id uint))
    (let (
        (pool (unwrap! (get-event-pool event-id) ERR-EVENT-NOT-FOUND))
        (total-pool (get total-pool pool))
        (oracle-fee-amount (/ (* total-pool ORACLE-FEE) PRECISION))
        (platform-fee-amount (/ (* total-pool PLATFORM-FEE) PRECISION))
        (event (unwrap! (get-event event-id) ERR-EVENT-NOT-FOUND))
        (oracle (unwrap! (get oracle event) ERR-INVALID-ORACLE))
    )
        ;; Pay oracle fee
        (unwrap! (as-contract (ft-transfer? PWR oracle-fee-amount tx-sender oracle)) ERR-TRANSFER-FAILED)
        
        ;; Platform fee stays in contract
        ;; Update pool with collected fees
        (map-set event-pools event-id 
            (merge pool {
                oracle-fee-collected: oracle-fee-amount,
                platform-fee-collected: platform-fee-amount
            })
        )
        
        (ok true)
    )
)

;; Admin functions

;; Pause market
(define-public (pause-market)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (var-set market-paused true)
        (ok true)
    )
)

;; Resume market
(define-public (resume-market)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (var-set market-paused false)
        (ok true)
    )
)

;; Set oracle admin
(define-public (set-oracle-admin (admin principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (var-set oracle-admin (some admin))
        (ok true)
    )
)

;; Withdraw platform fees
(define-public (withdraw-platform-fees (amount uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (match (as-contract (ft-transfer? PWR amount tx-sender tx-sender))
            success (ok amount)
            error ERR-TRANSFER-FAILED
        )
    )
)

;; Mint PWR tokens (for testing)
(define-public (mint-pwr (amount uint) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (match (ft-mint? PWR amount recipient)
            success (ok amount)
            error ERR-TRANSFER-FAILED
        )
    )
)

;; Mint ORACLE tokens (for testing)
(define-public (mint-oracle (amount uint) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (match (ft-mint? ORACLE amount recipient)
            success (ok amount)
            error ERR-TRANSFER-FAILED
        )
    )
)

;; Get token balances
(define-read-only (get-pwr-balance (user principal))
    (ft-get-balance PWR user)
)

(define-read-only (get-oracle-balance (user principal))
    (ft-get-balance ORACLE user)
)

;; Get events by status
(define-read-only (get-events-by-status (status uint))
    ;; Simplified implementation - would iterate through events in practice
    (ok (var-get total-events))
)

;; Get user event creation history
(define-read-only (get-user-event-history (user principal))
    (map-get? user-events user)
)