;; university-core.clar

;; Constants and Errors
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_NOT_FOUND (err u2))
(define-constant ERR_ALREADY_EXISTS (err u3))
(define-constant ERR_INVALID_VALUE (err u4))

;; Student Management
(define-map students 
    { student-id: uint }
    {
        name: (string-ascii 50),
        course: (string-ascii 50),
        enrollment-year: uint,
        status: (string-ascii 20),
        graduation-status: bool,
        required-credits: uint,
        completed-credits: uint
    }
)

(define-map student-courses
    { student-id: uint, course-id: uint }
    {
        grade: (optional uint),
        attendance: uint,
        semester: uint,
        status: (string-ascii 20)
    }
)

(define-map student-performance
    { student-id: uint, semester: uint }
    {
        gpa: uint,
        attendance: uint,
        completed-credits: uint
    }
)

;; Lecturer Management
(define-map lecturers
    { lecturer-id: uint }
    {
        name: (string-ascii 50),
        department: (string-ascii 50),
        status: (string-ascii 20),
        joining-date: uint,
        hourly-rate: uint
    }
)

(define-map lecturer-courses
    { lecturer-id: uint, course-id: uint, semester: uint }
    {
        hours-worked: uint,
        performance-rating: (optional uint),
        status: (string-ascii 20)
    }
)

(define-map lecturer-payments
    { lecturer-id: uint, month: uint, year: uint }
    {
        total-hours: uint,
        payment-amount: uint,
        payment-status: (string-ascii 20)
    }
)

;; Student Functions
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
                course: course,
                enrollment-year: block-height,
                status: "active",
                graduation-status: false,
                required-credits: required-credits,
                completed-credits: u0
            }
        ))
    )
)

(define-public (enroll-course
    (student-id uint)
    (course-id uint)
    (semester uint))
    (begin
        (asserts! (not (is-none (map-get? students {student-id: student-id}))) ERR_NOT_FOUND)
        (ok (map-set student-courses
            {student-id: student-id, course-id: course-id}
            {
                grade: none,
                attendance: u0,
                semester: semester,
                status: "enrolled"
            }
        ))
    )
)

(define-public (update-student-performance
    (student-id uint)
    (semester uint)
    (gpa uint)
    (attendance uint)
    (completed-credits uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (ok (map-set student-performance
            {student-id: student-id, semester: semester}
            {
                gpa: gpa,
                attendance: attendance,
                completed-credits: completed-credits
            }
        ))
    )
)

;; Lecturer Functions
(define-public (register-lecturer
    (lecturer-id uint)
    (name (string-ascii 50))
    (department (string-ascii 50))
    (hourly-rate uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? lecturers {lecturer-id: lecturer-id})) ERR_ALREADY_EXISTS)
        
        (ok (map-set lecturers
            {lecturer-id: lecturer-id}
            {
                name: name,
                department: department,
                status: "active",
                joining-date: block-height,
                hourly-rate: hourly-rate
            }
        ))
    )
)

(define-public (assign-course
    (lecturer-id uint)
    (course-id uint)
    (semester uint))
    (begin
        (asserts! (not (is-none (map-get? lecturers {lecturer-id: lecturer-id}))) ERR_NOT_FOUND)
        (ok (map-set lecturer-courses
            {lecturer-id: lecturer-id, course-id: course-id, semester: semester}
            {
                hours-worked: u0,
                performance-rating: none,
                status: "assigned"
            }
        ))
    )
)

(define-public (record-lecturer-hours
    (lecturer-id uint)
    (course-id uint)
    (semester uint)
    (hours uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (ok (map-set lecturer-courses
            {lecturer-id: lecturer-id, course-id: course-id, semester: semester}
            (merge (unwrap! (map-get? lecturer-courses 
                {lecturer-id: lecturer-id, course-id: course-id, semester: semester}) 
                ERR_NOT_FOUND)
            {hours-worked: hours})
        ))
    )
)

(define-public (process-lecturer-payment
    (lecturer-id uint)
    (month uint)
    (year uint)
    (total-hours uint))
    (let ((lecturer (unwrap! (map-get? lecturers {lecturer-id: lecturer-id}) ERR_NOT_FOUND)))
        (begin
            (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
            (ok (map-set lecturer-payments
                {lecturer-id: lecturer-id, month: month, year: year}
                {
                    total-hours: total-hours,
                    payment-amount: (* total-hours (get hourly-rate lecturer)),
                    payment-status: "pending"
                }
            ))
        )
    )
)

;; Read-only Functions
(define-read-only (get-student-info (student-id uint))
    (map-get? students {student-id: student-id}))

(define-read-only (get-student-course-info (student-id uint) (course-id uint))
    (map-get? student-courses {student-id: student-id, course-id: course-id}))

(define-read-only (get-lecturer-info (lecturer-id uint))
    (map-get? lecturers {lecturer-id: lecturer-id}))

(define-read-only (get-lecturer-payment-info 
    (lecturer-id uint) 
    (month uint) 
    (year uint))
    (map-get? lecturer-payments {lecturer-id: lecturer-id, month: month, year: year}))