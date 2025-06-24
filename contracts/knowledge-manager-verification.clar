;; Knowledge Manager Verification Contract
;; Validates and manages consulting knowledge managers

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-verified (err u101))
(define-constant err-not-found (err u102))
(define-constant err-unauthorized (err u103))

;; Data structures
(define-map verified-managers principal {
    verified: bool,
    verification-date: uint,
    expertise-level: (string-ascii 20),
    reputation-score: uint
})

(define-map pending-verifications principal {
    application-date: uint,
    credentials: (string-ascii 500),
    endorsements: uint
})

;; Read-only functions
(define-read-only (is-verified-manager (manager principal))
    (default-to false (get verified (map-get? verified-managers manager)))
)

(define-read-only (get-manager-info (manager principal))
    (map-get? verified-managers manager)
)

(define-read-only (get-reputation-score (manager principal))
    (default-to u0 (get reputation-score (map-get? verified-managers manager)))
)

;; Public functions
(define-public (apply-for-verification (credentials (string-ascii 500)))
    (let ((applicant tx-sender))
        (asserts! (is-none (map-get? verified-managers applicant)) err-already-verified)
        (map-set pending-verifications applicant {
            application-date: block-height,
            credentials: credentials,
            endorsements: u0
        })
        (ok true)
    )
)

(define-public (verify-manager (manager principal) (expertise-level (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set verified-managers manager {
            verified: true,
            verification-date: block-height,
            expertise-level: expertise-level,
            reputation-score: u100
        })
        (map-delete pending-verifications manager)
        (ok true)
    )
)

(define-public (update-reputation (manager principal) (new-score uint))
    (let ((current-info (unwrap! (map-get? verified-managers manager) err-not-found)))
        (asserts! (get verified current-info) err-not-found)
        (map-set verified-managers manager (merge current-info { reputation-score: new-score }))
        (ok true)
    )
)

(define-public (endorse-application (applicant principal))
    (let ((application (unwrap! (map-get? pending-verifications applicant) err-not-found)))
        (asserts! (is-verified-manager tx-sender) err-unauthorized)
        (map-set pending-verifications applicant
            (merge application { endorsements: (+ (get endorsements application) u1) }))
        (ok true)
    )
)
