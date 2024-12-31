;; certificate-transcript-issuance.clar

;; Constants and Errors
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_NOT_FOUND (err u2))

;; Data Maps

;; Student Graduation Status
(define-map student-graduation-status
    { student-id: uint }
    {
        has-graduated: bool,
        graduation-year: (optional uint),
        program: (string-ascii 50)
    }
)

;; Transcript Entries
(define-map transcript-entries
    { student-id: uint, course-id: uint }
    {
        course-name: (string-ascii 50),
        grade: (string-ascii 2),
        credits: uint,
        semester: uint
    }
)

;; Certificates
(define-map certificates
    { student-id: uint, certificate-id: uint }
    {
        certificate-type: (string-ascii 50),
        issued-date: uint,
        program: (string-ascii 50)
    }
)

;; Functions

;; Update Graduation Status
(define-public (update-graduation-status 
    (student-id uint)
    (has-graduated bool)
    (program (string-ascii 50))
    (year uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        
        (ok (map-set student-graduation-status
            {student-id: student-id}
            {
                has-graduated: has-graduated,
                graduation-year: (if has-graduated (some year) none),
                program: program
            }
        ))
    )
)

;; Transcript Generation
(define-public (add-to-transcript 
    (student-id uint)
    (course-id uint)
    (course-name (string-ascii 50))
    (grade (string-ascii 2))
    (credits uint)
    (semester uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        
        (ok (map-set transcript-entries
            {student-id: student-id, course-id: course-id}
            {
                course-name: course-name,
                grade: grade,
                credits: credits,
                semester: semester
            }
        ))
    )
)

;; Certificate Generation
(define-public (issue-certificate 
    (student-id uint)
    (certificate-id uint)
    (certificate-type (string-ascii 50))
    (program (string-ascii 50)))
    (let (
        (graduation-status (unwrap! (map-get? student-graduation-status {student-id: student-id}) ERR_NOT_FOUND))
    )
        (begin
            (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
            (asserts! (get has-graduated graduation-status) ERR_NOT_FOUND)
            
            (ok (map-set certificates
                {student-id: student-id, certificate-id: certificate-id}
                {
                    certificate-type: certificate-type,
                    issued-date: block-height,
                    program: program
                }
            ))
        )
    )
)

;; Read-only Functions

(define-read-only (get-graduation-status (student-id uint))
    (map-get? student-graduation-status {student-id: student-id}))

(define-read-only (get-transcript-entry (student-id uint) (course-id uint))
    (map-get? transcript-entries {student-id: student-id, course-id: course-id}))

;; Helper Function to get all transcript entries for a student
(define-read-only (get-full-transcript (student-id uint))
    (filter 
        (lambda (entry) 
            (is-some (get-transcript-entry student-id (get course-id entry))))
        (map 
            (lambda (course-id) 
                {course-id: course-id})
            (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10))))  ;; Assuming max 10 courses, adjust as needed

(define-read-only (get-certificates (student-id uint))
    (filter 
        (lambda (cert) 
            (is-some (get-certificates student-id (get certificate-id cert))))
        (map 
            (lambda (certificate-id) 
                {certificate-id: certificate-id})
            (list u1 u2 u3 u4 u5))))  ;; Assuming max 5 certificates, adjust as needed