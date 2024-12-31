;; fee-payment-management.clar

;; Constants and Errors
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_NOT_FOUND (err u2))

;; Data Maps

;; Fee Structure
(define-map fee-structure
    { program-id: uint }
    {
        tuition: uint,
        additional-fees: uint  ;; e.g., for labs, materials
    }
)

;; Student Payments
(define-map student-payments
    { student-id: uint, semester: uint }
    {
        amount-paid: uint,
        total-due: uint,
        last-payment-date: uint,
        status: (string-ascii 20)  ;; e.g., "paid", "outstanding"
    }
)

;; Scholarships and Financial Aid
(define-map scholarships
    { scholarship-id: uint }
    {
        name: (string-ascii 50),
        amount: uint,
        criteria: (string-ascii 200)
    }
)

(define-map student-scholarships
    { student-id: uint, scholarship-id: uint }
    {
        awarded-amount: uint,
        year-awarded: uint
    }
)

;; Lecturer Salary Payments
(define-map lecturer-salary
    { lecturer-id: uint, month: uint, year: uint }
    {
        hours-worked: uint,
        rate-per-hour: uint,
        amount-due: uint,
        payment-status: (string-ascii 20)  ;; e.g., "paid", "pending"
    }
)

;; Functions

;; Fee Structure Management
(define-public (set-fee-structure 
    (program-id uint)
    (tuition uint)
    (additional-fees uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        
        (ok (map-set fee-structure
            {program-id: program-id}
            {
                tuition: tuition,
                additional-fees: additional-fees
            }
        ))
    )
)

;; Student Payment Tracking
(define-public (record-student-payment 
    (student-id uint)
    (semester uint)
    (amount uint))
    (let (
        (current-payment (unwrap! (map-get? student-payments {student-id: student-id, semester: semester}) ERR_NOT_FOUND))
    )
        (begin
            (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
            (ok (map-set student-payments
                {student-id: student-id, semester: semester}
                {
                    amount-paid: (+ (get amount-paid current-payment) amount),
                    total-due: (get total-due current-payment),
                    last-payment-date: block-height,
                    status: (if (>= (+ (get amount-paid current-payment) amount) (get total-due current-payment)) "paid" "outstanding")
                }
            ))
        )
    )
)

;; Scholarships & Financial Aid
(define-public (create-scholarship 
    (scholarship-id uint)
    (name (string-ascii 50))
    (amount uint)
    (criteria (string-ascii 200)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? scholarships {scholarship-id: scholarship-id})) ERR_NOT_FOUND)
        
        (ok (map-set scholarships
            {scholarship-id: scholarship-id}
            {
                name: name,
                amount: amount,
                criteria: criteria
            }
        ))
    )
)

(define-public (award-scholarship 
    (student-id uint)
    (scholarship-id uint)
    (awarded-amount uint)
    (year uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        
        (ok (map-set student-scholarships
            {student-id: student-id, scholarship-id: scholarship-id}
            {
                awarded-amount: awarded-amount,
                year-awarded: year
            }
        ))
    )
)

;; Lecturer Salary Payments
(define-public (process-lecturer-salary 
    (lecturer-id uint)
    (month uint)
    (year uint)
    (hours-worked uint)
    (rate-per-hour uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        
        (ok (map-set lecturer-salary
            {lecturer-id: lecturer-id, month: month, year: year}
            {
                hours-worked: hours-worked,
                rate-per-hour: rate-per-hour,
                amount-due: (* hours-worked rate-per-hour),
                payment-status: "pending"
            }
        ))
    )
)

(define-public (mark-salary-paid 
    (lecturer-id uint)
    (month uint)
    (year uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (let (
            (salary (unwrap! (map-get? lecturer-salary {lecturer-id: lecturer-id, month: month, year: year}) ERR_NOT_FOUND))
        )
            (ok (map-set lecturer-salary
                {lecturer-id: lecturer-id, month: month, year: year}
                (merge salary {payment-status: "paid"})
            ))
        )
    )
)

;; Read-only Functions

(define-read-only (get-fee-structure (program-id uint))
    (map-get? fee-structure {program-id: program-id}))

(define-read-only (get-student-payment-info (student-id uint) (semester uint))
    (map-get? student-payments {student-id: student-id, semester: semester}))

(define-read-only (get-scholarship-info (scholarship-id uint))
    (map-get? scholarships {scholarship-id: scholarship-id}))

(define-read-only (get-student-scholarship (student-id uint) (scholarship-id uint))
    (map-get? student-scholarships {student-id: student-id, scholarship-id: scholarship-id}))

(define-read-only (get-lecturer-salary-info (lecturer-id uint) (month uint) (year uint))
    (map-get? lecturer-salary {lecturer-id: lecturer-id, month: month, year: year}))