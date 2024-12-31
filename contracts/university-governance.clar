;; university-governance.clar

;; Constants and Errors
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_NOT_FOUND (err u2))
(define-constant ERR_ALREADY_EXISTS (err u3))

;; Data Maps

;; Policy Proposals
(define-map policy-proposals
    { proposal-id: uint }
    {
        title: (string-ascii 100),
        description: (string-ascii 200),
        proposer: principal,
        status: (string-ascii 20),  ;; e.g., "pending", "approved", "rejected"
        votes-for: uint,
        votes-against: uint
    }
)

;; Voting System
(define-map votes
    { proposal-id: uint, voter: principal }
    {
        vote: (string-ascii 10) ;; "for" or "against"
    }
)

;; Budget Allocations
(define-map budget-allocations
    { allocation-id: uint }
    {
        department-or-project: (string-ascii 50),
        amount: uint,
        fiscal-year: uint,
        status: (string-ascii 20) ;; e.g., "allocated", "spent"
    }
)

;; Functions

;; Policy Proposals
(define-public (submit-policy-proposal 
    (proposal-id uint)
    (title (string-ascii 100))
    (description (string-ascii 200)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? policy-proposals {proposal-id: proposal-id})) ERR_ALREADY_EXISTS)
        
        (ok (map-set policy-proposals
            {proposal-id: proposal-id}
            {
                title: title,
                description: description,
                proposer: tx-sender,
                status: "pending",
                votes-for: u0,
                votes-against: u0
            }
        ))
    )
)

(define-public (vote-on-proposal 
    (proposal-id uint)
    (vote (string-ascii 10)))
    (let (
        (proposal (unwrap! (map-get? policy-proposals {proposal-id: proposal-id}) ERR_NOT_FOUND))
    )
        (begin
            (asserts! (or (is-eq "pending" (get status proposal)) (is-eq "voting" (get status proposal))) ERR_NOT_FOUND)
            (asserts! (or (is-eq vote "for") (is-eq vote "against")) ERR_NOT_FOUND)
            (asserts! (is-none (map-get? votes {proposal-id: proposal-id, voter: tx-sender})) ERR_ALREADY_EXISTS) ;; Prevent multiple votes
            
            (map-set votes
                {proposal-id: proposal-id, voter: tx-sender}
                {vote: vote})
            
            (if (is-eq vote "for")
                (map-set policy-proposals 
                    {proposal-id: proposal-id}
                    (merge proposal {votes-for: (+ (get votes-for proposal) u1)}))
                (map-set policy-proposals 
                    {proposal-id: proposal-id}
                    (merge proposal {votes-against: (+ (get votes-against proposal) u1)})))
            
            (ok true)
        )
    )
)

(define-public (finalize-proposal 
    (proposal-id uint))
    (let (
        (proposal (unwrap! (map-get? policy-proposals {proposal-id: proposal-id}) ERR_NOT_FOUND))
    )
        (begin
            (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
            (asserts! (is-eq "pending" (get status proposal)) ERR_NOT_FOUND)
            
            (if (> (get votes-for proposal) (get votes-against proposal))
                (map-set policy-proposals 
                    {proposal-id: proposal-id}
                    (merge proposal {status: "approved"}))
                (map-set policy-proposals 
                    {proposal-id: proposal-id}
                    (merge proposal {status: "rejected"})))
            
            (ok true)
        )
    )
)

;; Budgeting & Allocations
(define-public (allocate-budget 
    (allocation-id uint)
    (department-or-project (string-ascii 50))
    (amount uint)
    (fiscal-year uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? budget-allocations {allocation-id: allocation-id})) ERR_ALREADY_EXISTS)
        
        (ok (map-set budget-allocations
            {allocation-id: allocation-id}
            {
                department-or-project: department-or-project,
                amount: amount,
                fiscal-year: fiscal-year,
                status: "allocated"
            }
        ))
    )
)

(define-public (update-budget-status 
    (allocation-id uint)
    (new-status (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (ok (map-set budget-allocations
            {allocation-id: allocation-id}
            (merge (unwrap! (map-get? budget-allocations {allocation-id: allocation-id}) ERR_NOT_FOUND)
                {status: new-status})
        ))
    )
)

;; Read-only Functions

(define-read-only (get-policy-proposal (proposal-id uint))
    (map-get? policy-proposals {proposal-id: proposal-id}))

(define-read-only (get-vote (proposal-id uint) (voter principal))
    (map-get? votes {proposal-id: proposal-id, voter: voter}))

(define-read-only (get-budget-allocation (allocation-id uint))
    (map-get? budget-allocations {allocation-id: allocation-id}))

;; Helper function to get all allocations for a fiscal year
(define-read-only (get-yearly-budget (fiscal-year uint))
    (filter 
        (lambda (allocation-entry) 
            (is-eq (get fiscal-year allocation-entry) fiscal-year))
        (map 
            (lambda (allocation-id) 
                (unwrap! (get-budget-allocation allocation-id) {allocation-id: u0}))
            (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10))))  ;; Assuming max 10 allocations per year, adjust as needed