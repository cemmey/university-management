;; admission-management.clar

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_NOT_FOUND (err u2))
(define-constant ERR_ALREADY_EXISTS (err u3))
(define-constant ERR_INVALID_STATUS (err u4))

;; Data Maps
(define-map applications
    { application-id: uint }
    {
        student-name: (string-ascii 50),
        email: (string-ascii 50),
        program: (string-ascii 50),
        test-score: uint,
        grades: uint,
        interview-score: (optional uint),
        status: (string-ascii 20),
        submitted-at: uint
    }
)

(define-map admission-criteria
    { program: (string-ascii 50) }
    {
        min-test-score: uint,
        min-grades: uint,
        min-interview-score: uint
    }
)

(define-map acceptance-confirmations
    { application-id: uint }
    {
        confirmed: bool,
        confirmation-date: uint,
        deposit-paid: bool
    }
)

;; Functions
(define-public (submit-application 
    (application-id uint)
    (student-name (string-ascii 50))
    (email (string-ascii 50))
    (program (string-ascii 50))
    (test-score uint)
    (grades uint))
    (begin
        (asserts! (is-none (map-get? applications {application-id: application-id})) ERR_ALREADY_EXISTS)
        (ok (map-set applications
            {application-id: application-id}
            {
                student-name: student-name,
                email: email,
                program: program,
                test-score: test-score,
                grades: grades,
                interview-score: none,
                status: "pending",
                submitted-at: block-height
            }
        ))
    )
)

(define-public (update-interview-score
    (application-id uint)
    (score uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (ok (map-set applications
            {application-id: application-id}
            (merge (unwrap! (map-get? applications {application-id: application-id}) ERR_NOT_FOUND)
                  {interview-score: (some score)})
        ))
    )
)

(define-public (evaluate-application
    (application-id uint))
    (let (
        (application (unwrap! (map-get? applications {application-id: application-id}) ERR_NOT_FOUND))
        (criteria (unwrap! (map-get? admission-criteria {program: (get program application)}) ERR_NOT_FOUND))
        )
        (begin
            (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
            (ok (map-set applications
                {application-id: application-id}
                (merge application 
                    {status: (evaluate-criteria application criteria)})
            ))
        )
    )
)

(define-private (evaluate-criteria
    (application {
        student-name: (string-ascii 50),
        email: (string-ascii 50),
        program: (string-ascii 50),
        test-score: uint,
        grades: uint,
        interview-score: (optional uint),
        status: (string-ascii 20),
        submitted-at: uint
    })
    (criteria {
        min-test-score: uint,
        min-grades: uint,
        min-interview-score: uint
    }))
    (if (and
            (>= (get test-score application) (get min-test-score criteria))
            (>= (get grades application) (get min-grades criteria))
            (>= (default-to u0 (get interview-score application)) (get min-interview-score criteria)))
        "accepted"
        "rejected"
    )
)

(define-public (confirm-acceptance
    (application-id uint)
    (accept bool))
    (begin
        (asserts! (not (is-none (map-get? applications {application-id: application-id}))) ERR_NOT_FOUND)
        (ok (map-set acceptance-confirmations
            {application-id: application-id}
            {
                confirmed: accept,
                confirmation-date: block-height,
                deposit-paid: false
            }
        ))
    )
)

;; Read-only functions
(define-read-only (get-application-status (application-id uint))
    (map-get? applications {application-id: application-id}))

(define-read-only (get-confirmation-status (application-id uint))
    (map-get? acceptance-confirmations {application-id: application-id}))