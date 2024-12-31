;; course-curriculum-management.clar

;; Constants and Errors
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_NOT_FOUND (err u2))
(define-constant ERR_ALREADY_EXISTS (err u3))

;; Data Maps

;; Courses
(define-map courses
    { course-id: uint }
    {
        name: (string-ascii 50),
        description: (string-ascii 200),
        credits: uint,
        prerequisites: (list 5 uint) ;; Maximum of prerequisites per course
    }
)

;; Course Schedules
(define-map course-schedules
    { course-id: uint, semester: uint }
    {
        start-date: uint,
        end-date: uint,
        location: (string-ascii 50),
        lecturer-id: uint
    }
)

;; Curriculum (Program)
(define-map curricula
    { program-id: uint }
    {
        name: (string-ascii 50),
        required-courses: (list 20 uint) ;; Assuming max 20 courses in a curriculum
    }
)

;; Student Enrollment in Courses
(define-map student-enrollments
    { student-id: uint, course-id: uint, semester: uint }
    {
        status: (string-ascii 20)
    }
)

;; Functions

;; Course Registration
(define-public (register-course 
    (course-id uint) 
    (name (string-ascii 50))
    (description (string-ascii 200))
    (credits uint)
    (prerequisites (list 5 uint)))
    (begin 
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? courses {course-id: course-id})) ERR_ALREADY_EXISTS)
        
        (ok (map-set courses
            {course-id: course-id}
            {
                name: name,
                description: description,
                credits: credits,
                prerequisites: prerequisites
            }
        ))
    )
)

;; Course Enrollment
(define-public (enroll-student-in-course
    (student-id uint)
    (course-id uint)
    (semester uint))
    (begin
        (asserts! (not (is-none (map-get? courses {course-id: course-id}))) ERR_NOT_FOUND)
        (ok (map-set student-enrollments
            {student-id: student-id, course-id: course-id, semester: semester}
            {
                status: "enrolled"
            }
        ))
    )
)

;; Curriculum Management
(define-public (create-curriculum 
    (program-id uint) 
    (name (string-ascii 50))
    (required-courses (list 20 uint)))
    (begin 
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? curricula {program-id: program-id})) ERR_ALREADY_EXISTS)
        
        (ok (map-set curricula
            {program-id: program-id}
            {
                name: name,
                required-courses: required-courses
            }
        ))
    )
)

;; Course Scheduling
(define-public (schedule-course 
    (course-id uint) 
    (semester uint)
    (start-date uint)
    (end-date uint)
    (location (string-ascii 50))
    (lecturer-id uint))
    (begin
        (asserts! (not (is-none (map-get? courses {course-id: course-id}))) ERR_NOT_FOUND)
        (asserts! (not (is-none (map-get? lecturers {lecturer-id: lecturer-id}))) ERR_NOT_FOUND)
        
        (ok (map-set course-schedules
            {course-id: course-id, semester: semester}
            {
                start-date: start-date,
                end-date: end-date,
                location: location,
                lecturer-id: lecturer-id
            }
        ))
    )
)

;; Read-only Functions

(define-read-only (get-course-info (course-id uint))
    (map-get? courses {course-id: course-id}))

(define-read-only (get-course-schedule (course-id uint) (semester uint))
    (map-get? course-schedules {course-id: course-id, semester: semester}))

(define-read-only (get-curriculum-info (program-id uint))
    (map-get? curricula {program-id: program-id}))

(define-read-only (get-student-enrollment (student-id uint) (course-id uint) (semester uint))
    (map-get? student-enrollments {student-id: student-id, course-id: course-id, semester: semester}))