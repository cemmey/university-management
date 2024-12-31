;; examination-grading-management.clar

;; Constants and Errors
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_NOT_FOUND (err u2))
(define-constant ERR_ALREADY_EXISTS (err u3))

;; Data Maps

;; Exam Information
(define-map exams
    { exam-id: uint }
    {
        course-id: uint,
        exam-name: (string-ascii 50),
        exam-date: uint,  ;; Assuming this is a timestamp
        duration: uint,   ;; Duration in minutes
        status: (string-ascii 20)  ;; e.g., "scheduled", "completed"
    }
)

;; Exam Registrations
(define-map exam-registrations
    { student-id: uint, exam-id: uint }
    {
        status: (string-ascii 20)  ;; e.g., "registered", "attended", "absent"
    }
)

;; Grades
(define-map grades
    { student-id: uint, exam-id: uint }
    {
        score: uint,
        max-score: uint,
        grade: (string-ascii 2)  ;; e.g., "A", "B", "C"
    }
)

;; Functions

;; Exam Creation
(define-public (create-exam 
    (exam-id uint)
    (course-id uint)
    (exam-name (string-ascii 50))
    (exam-date uint)
    (duration uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? exams {exam-id: exam-id})) ERR_ALREADY_EXISTS)
        
        (ok (map-set exams
            {exam-id: exam-id}
            {
                course-id: course-id,
                exam-name: exam-name,
                exam-date: exam-date,
                duration: duration,
                status: "scheduled"
            }
        ))
    )
)

;; Exam Registration
(define-public (register-for-exam 
    (student-id uint)
    (exam-id uint))
    (begin
        (asserts! (not (is-none (map-get? exams {exam-id: exam-id}))) ERR_NOT_FOUND)
        (asserts! (is-none (map-get? exam-registrations {student-id: student-id, exam-id: exam-id})) ERR_ALREADY_EXISTS)
        
        (ok (map-set exam-registrations
            {student-id: student-id, exam-id: exam-id}
            {
                status: "registered"
            }
        ))
    )
)

;; Grading
(define-public (record-grade 
    (student-id uint)
    (exam-id uint)
    (score uint)
    (max-score uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-eq "attended" (get status (unwrap! (map-get? exam-registrations {student-id: student-id, exam-id: exam-id}) ERR_NOT_FOUND))) ERR_NOT_FOUND)
        
        (let (
            (grade (calculate-grade score max-score))
        )
            (ok (map-set grades
                {student-id: student-id, exam-id: exam-id}
                {
                    score: score,
                    max-score: max-score,
                    grade: grade
                }
            ))
        )
    )
)

(define-private (calculate-grade 
    (score uint) 
    (max-score uint))
    (let (
        (percentage (/ (* score u100) max-score))
    )
        (cond 
            ((>= percentage u90) "A")
            ((>= percentage u80) "B")
            ((>= percentage u70) "C")
            ((>= percentage u60) "D")
            (true "F")
        )
    )
)

;; Result Publication
(define-public (publish-results 
    (exam-id uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        
        ;; Here, we just update exam status to completed.
        (ok (map-set exams
            {exam-id: exam-id}
            (merge (unwrap! (map-get? exams {exam-id: exam-id}) ERR_NOT_FOUND)
                   {status: "completed"}))
        )
    )
)

;; Read-only Functions

(define-read-only (get-exam-info (exam-id uint))
    (map-get? exams {exam-id: exam-id}))

(define-read-only (get-exam-registration (student-id uint) (exam-id uint))
    (map-get? exam-registrations {student-id: student-id, exam-id: exam-id}))

(define-read-only (get-grade (student-id uint) (exam-id uint))
    (map-get? grades {student-id: student-id, exam-id: exam-id}))

;; Helper Function to get all grades for a student for a course across exams
(define-read-only (get-course-grades 
    (student-id uint) 
    (course-id uint))
    (filter 
        (lambda (grade-entry) 
            (is-some (get-grade student-id (get exam-id grade-entry))))
        (map 
            (lambda (exam-entry) 
                (let (
                    (exam (unwrap-panic (get-exam-info (get exam-id exam-entry))))
                )
                    (if (is-eq course-id (get course-id exam))
                        exam-entry
                        {exam-id: u0}
                )))
            (map-get? exams {course-id: course-id}))))