;; library-resource-management.clar

;; Constants and Errors
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_NOT_FOUND (err u2))
(define-constant ERR_ALREADY_CHECKED_OUT (err u3))
(define-constant ERR_ALREADY_RETURNED (err u4))
(define-constant ERR_FINE_CALCULATION (err u5))

;; Constants for fine calculation
(define-constant FINE_PER_DAY u10)  ;; Fine rate of 10 units per day

;; Data Maps

;; Book Catalog
(define-map books
    { book-id: uint }
    {
        title: (string-ascii 100),
        author: (string-ascii 50),
        isbn: (string-ascii 20),
        available: bool,
        total-copies: uint
    }
)

;; Book Checkouts
(define-map checkouts
    { book-id: uint, user-id: uint }
    {
        checkout-date: uint,  ;; Block height at checkout
        due-date: uint,       ;; Block height when due
        returned: bool
    }
)

;; Fines
(define-map fines
    { user-id: uint }
    {
        amount: uint
    }
)

;; Functions

;; Book Catalog Management
(define-public (add-book 
    (book-id uint)
    (title (string-ascii 100))
    (author (string-ascii 50))
    (isbn (string-ascii 20))
    (total-copies uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? books {book-id: book-id})) ERR_NOT_FOUND)
        
        (ok (map-set books
            {book-id: book-id}
            {
                title: title,
                author: author,
                isbn: isbn,
                available: (> total-copies u0),
                total-copies: total-copies
            }
        ))
    )
)

;; Book Checkout
(define-public (checkout-book 
    (book-id uint)
    (user-id uint)
    (due-date uint))  ;; Due date as block height
    (let (
        (book (unwrap! (map-get? books {book-id: book-id}) ERR_NOT_FOUND))
        (checkout (map-get? checkouts {book-id: book-id, user-id: user-id}))
    )
        (begin
            (asserts! (get available book) ERR_NOT_FOUND)
            (asserts! (is-none checkout) ERR_ALREADY_CHECKED_OUT)
            
            ;; Decrement available copies if there's more than one
            (map-set books 
                {book-id: book-id}
                (merge book {available: false}))
            
            (map-set checkouts
                {book-id: book-id, user-id: user-id}
                {
                    checkout-date: block-height,
                    due-date: due-date,
                    returned: false
                }
            )
            
            (ok true)
        )
    )
)

;; Book Return
(define-public (return-book 
    (book-id uint)
    (user-id uint))
    (let (
        (book (unwrap! (map-get? books {book-id: book-id}) ERR_NOT_FOUND))
        (checkout (unwrap! (map-get? checkouts {book-id: book-id, user-id: user-id}) ERR_NOT_FOUND))
    )
        (begin
            (asserts! (not (get returned checkout)) ERR_ALREADY_RETURNED)
            
            ;; Update book availability
            (map-set books 
                {book-id: book-id}
                (merge book {available: true}))
            
            ;; Update checkout record
            (map-set checkouts
                {book-id: book-id, user-id: user-id}
                (merge checkout {returned: true}))
            
            ;; Calculate and update fines if any
            (try! (calculate-and-update-fine user-id (get due-date checkout)))
            
            (ok true)
        )
    )
)

;; Fine Management
(define-private (calculate-and-update-fine 
    (user-id uint) 
    (due-date uint))
    (let (
        (current-block block-height)
        (days-overdue (if (> current-block due-date) (- current-block due-date) u0))
        (fine-amount (* days-overdue FINE_PER_DAY))
        (current-fine (default-to {amount: u0} (map-get? fines {user-id: user-id})))
    )
        (begin
            (map-set fines
                {user-id: user-id}
                {amount: (+ (get amount current-fine) fine-amount)})
            
            (ok fine-amount)
        )
    )
)

;; Read-only Functions

(define-read-only (get-book-info (book-id uint))
    (map-get? books {book-id: book-id}))

(define-read-only (get-checkout-info (book-id uint) (user-id uint))
    (map-get? checkouts {book-id: book-id, user-id: user-id}))

(define-read-only (get-fine-amount (user-id uint))
    (default-to {amount: u0} (map-get? fines {user-id: user-id})))