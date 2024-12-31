;; student-management.clar

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_NOT_FOUND (err u2))
(define-constant ERR_ALREADY_EXISTS (err u3))
(define-constant ERR_INVALID_STATUS (err u4))

;; Data Maps
(define-map students 
    { student-id: uint }
    {
        name: (string-ascii 50),
        enrollment-year: uint,
        course: (string-ascii 50),
        status: (string-ascii 20),
        graduation-status: bool,
        total-credits: uint,
        required-credits: uint
    }
)

(define-map student-courses
    { student-id: uint, course-id: uint }
    {
        grade: (optional uint),
        status: (string-ascii 20),
        semester: uint,
        attendance: uint,
        credits: uint
    }
)

(define-map student-performance
    { student-id: uint }
    {
        gpa: uint,
        total-attendance: uint,
        completed-credits: uint
    }
)

;; Student Registration
(define-public (register-student 
    (student-id uint) 
    (name (string-ascii 50))
    (course (string-ascii 50))
    (required-credits uint))
    (begin 
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? students {student-id: student-id})) ERR_ALREADY_EXISTS)
        
        (ok (map-set students
            {student-id: student-id}
            {
                name: name,
                enrollment-year: block-height,
                course: course,
                status: "active",
                graduation-status: false,
                total-credits: u0,
                required-credits: required-credits
            }
        ))
    )
)

;; Course Enrollment
(define-public (enroll-in-course 
    (student-id uint)
    (course-id uint)
    (semester uint)
    (credits uint))
    (begin
        (asserts! (not (is-none (map-get? students {student-id: student-id}))) ERR_NOT_FOUND)
        
        (ok (map-set student-courses
            {student-id: student-id, course-id: course-id}
            {
                grade: none,
                status: "enrolled",
                semester: semester,
                attendance: u0,
                credits: credits
            }
        ))
    )
)

;; Update Student Performance
(define-public (update-performance
    (student-id uint)
    (gpa uint)
    (attendance uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (not (is-none (map-get? students {student-id: student-id}))) ERR_NOT_FOUND)
        
        (ok (map-set student-performance
            {student-id: student-id}
            {
                gpa: gpa,
                total-attendance: attendance,
                completed-credits: (get-completed-credits student-id)
            }
        ))
    )
)

;; Update Course Grade and Attendance
(define-public (update-course-details
    (student-id uint)
    (course-id uint)
    (grade (optional uint))
    (attendance uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (not (is-none (map-get? student-courses {student-id: student-id, course-id: course-id}))) ERR_NOT_FOUND)
        
        (ok (map-set student-courses
            {student-id: student-id, course-id: course-id}
            (merge (unwrap! (map-get? student-courses {student-id: student-id, course-id: course-id}) ERR_NOT_FOUND)
                  {grade: grade,
                   attendance: attendance})
        ))
    )
)

;; Check Graduation Eligibility
(define-public (check-graduation-eligibility (student-id uint))
    (let (
        (student (unwrap! (map-get? students {student-id: student-id}) ERR_NOT_FOUND))
        (completed-credits (get-completed-credits student-id)))
        (if (>= completed-credits (get required-credits student))
            (ok (map-set students
                {student-id: student-id}
                (merge student {graduation-status: true})))
            ERR_NOT_FOUND
        )
    )
)

;; Helper Functions
(define-private (get-completed-credits (student-id uint))
    (default-to u0 
        (get credits 
            (map-get? student-performance {student-id: student-id}))))

;; Read-only Functions
(define-read-only (get-student-info (student-id uint))
    (map-get? students {student-id: student-id}))

(define-read-only (get-student-courses (student-id uint))
    (map-get? student-courses {student-id: student-id}))

(define-read-only (get-student-performance-info (student-id uint))
    (map-get? student-performance {student-id: student-id}))