;; recruitment-staff-management.clar

;; Constants and Errors
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_NOT_FOUND (err u2))
(define-constant ERR_ALREADY_EXISTS (err u3))

;; Data Maps

;; Job Listings
(define-map job-listings
    { job-id: uint }
    {
        title: (string-ascii 50),
        department: (string-ascii 50),
        description: (string-ascii 200),
        status: (string-ascii 20)  ;; e.g., "open", "closed"
    }
)

;; Job Applications
(define-map job-applications
    { job-id: uint, applicant-id: uint }
    {
        name: (string-ascii 50),
        email: (string-ascii 50),
        resume-link: (string-ascii 200),
        application-date: uint,
        interview-score: (optional uint),
        status: (string-ascii 20)  ;; e.g., "pending", "rejected", "accepted"
    }
)

;; Employment Contracts
(define-map staff-contracts
    { staff-id: uint }
    {
        job-title: (string-ascii 50),
        start-date: uint,
        end-date: (optional uint),  ;; null for permanent positions
        salary: uint,
        contract-type: (string-ascii 20)  ;; e.g., "full-time", "part-time"
    }
)

;; Staff Performance Reviews
(define-map staff-performance
    { staff-id: uint, review-year: uint }
    {
        performance-score: uint,
        comments: (string-ascii 200)
    }
)

;; Functions

;; Job Listings
(define-public (create-job-listing 
    (job-id uint)
    (title (string-ascii 50))
    (department (string-ascii 50))
    (description (string-ascii 200)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? job-listings {job-id: job-id})) ERR_ALREADY_EXISTS)
        
        (ok (map-set job-listings
            {job-id: job-id}
            {
                title: title,
                department: department,
                description: description,
                status: "open"
            }
        ))
    )
)

;; Application Processing
(define-public (submit-job-application 
    (job-id uint)
    (applicant-id uint)
    (name (string-ascii 50))
    (email (string-ascii 50))
    (resume-link (string-ascii 200)))
    (begin
        (asserts! (is-eq "open" (get status (unwrap! (map-get? job-listings {job-id: job-id}) ERR_NOT_FOUND))) ERR_NOT_FOUND)
        (asserts! (is-none (map-get? job-applications {job-id: job-id, applicant-id: applicant-id})) ERR_ALREADY_EXISTS)
        
        (ok (map-set job-applications
            {job-id: job-id, applicant-id: applicant-id}
            {
                name: name,
                email: email,
                resume-link: resume-link,
                application-date: block-height,
                interview-score: none,
                status: "pending"
            }
        ))
    )
)

(define-public (evaluate-applicant 
    (job-id uint)
    (applicant-id uint)
    (score uint)
    (status (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (ok (map-set job-applications
            {job-id: job-id, applicant-id: applicant-id}
            (merge (unwrap! (map-get? job-applications {job-id: job-id, applicant-id: applicant-id}) ERR_NOT_FOUND)
                   {interview-score: (some score), status: status})
        ))
    )
)

;; Staff Contracts
(define-public (create-staff-contract 
    (staff-id uint)
    (job-title (string-ascii 50))
    (start-date uint)
    (end-date (optional uint))
    (salary uint)
    (contract-type (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? staff-contracts {staff-id: staff-id})) ERR_ALREADY_EXISTS)
        
        (ok (map-set staff-contracts
            {staff-id: staff-id}
            {
                job-title: job-title,
                start-date: start-date,
                end-date: end-date,
                salary: salary,
                contract-type: contract-type
            }
        ))
    )
)

;; Staff Performance Evaluation
(define-public (record-performance-review 
    (staff-id uint)
    (review-year uint)
    (score uint)
    (comments (string-ascii 200)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        
        (ok (map-set staff-performance
            {staff-id: staff-id, review-year: review-year}
            {
                performance-score: score,
                comments: comments
            }
        ))
    )
)

;; Read-only Functions

(define-read-only (get-job-listing (job-id uint))
    (map-get? job-listings {job-id: job-id}))

(define-read-only (get-job-application (job-id uint) (applicant-id uint))
    (map-get? job-applications {job-id: job-id, applicant-id: applicant-id}))

(define-read-only (get-staff-contract (staff-id uint))
    (map-get? staff-contracts {staff-id: staff-id}))

(define-read-only (get-staff-performance (staff-id uint) (review-year uint))
    (map-get? staff-performance {staff-id: staff-id, review-year: review-year}))