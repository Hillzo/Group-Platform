;; Decentralized Group Membership Management System Smart Contract
;; Enhanced implementation with improved readability and structure


;; CONSTANTS & ERROR DEFINITIONS


(define-constant contract-owner-address tx-sender)

;; Error constants
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-MEMBER-ALREADY-EXISTS (err u101))
(define-constant ERR-MEMBER-NOT-FOUND (err u102))
(define-constant ERR-INVALID-ROLE-TYPE (err u103))
(define-constant ERR-PROPOSAL-DOES-NOT-EXIST (err u104))
(define-constant ERR-DUPLICATE-VOTE-ATTEMPT (err u105))
(define-constant ERR-PROPOSAL-VOTING-EXPIRED (err u106))
(define-constant ERR-INSUFFICIENT-VOTE-COUNT (err u107))
(define-constant ERR-PROPOSAL-ALREADY-EXECUTED (err u108))
(define-constant ERR-INVALID-THRESHOLD-VALUE (err u109))
(define-constant ERR-GROUP-MEMBER-CAPACITY-EXCEEDED (err u110))
(define-constant ERR-INVALID-SUSPENSION-DURATION (err u111))
(define-constant ERR-MEMBER-CURRENTLY-SUSPENDED (err u112))

;; System configuration constants
(define-constant default-voting-threshold-percentage u51)
(define-constant default-proposal-voting-duration u144) ;; approximately 24 hours in blocks
(define-constant default-max-group-capacity u1000)
(define-constant initial-admin-reputation-score u100)
(define-constant minimum-threshold-percentage u1)
(define-constant maximum-threshold-percentage u100)

;; STATE VARIABLES

(define-data-var group-display-name (string-ascii 50) "Default Group")
(define-data-var group-description-text (string-utf8 500) u"A decentralized group management system")
(define-data-var current-total-members uint u0)
(define-data-var maximum-allowed-members uint default-max-group-capacity)
(define-data-var next-proposal-identifier uint u0)
(define-data-var required-voting-threshold-percentage uint default-voting-threshold-percentage)
(define-data-var proposal-voting-window-duration uint default-proposal-voting-duration)


;; DATA STRUCTURES


;; Member profile information
(define-map group-member-profiles principal 
  {
    membership-start-block: uint,
    assigned-role-type: (string-ascii 20),
    reputation-score: uint,
    is-currently-active: bool,
    suspension-expires-at-block: (optional uint)
  }
)

;; Member activity tracking
(define-map member-activity-statistics principal
  {
    total-proposals-created: uint,
    total-votes-cast: uint,
    participation-attendance-rate: uint
  }
)

;; Proposal records
(define-map governance-proposals uint
  {
    proposal-creator: principal,
    proposal-title: (string-ascii 100),
    proposal-description: (string-utf8 1000),
    proposal-category-type: (string-ascii 20),
    proposal-creation-block: uint,
    voting-deadline-block: uint,
    affirmative-vote-count: uint,
    negative-vote-count: uint,
    has-been-executed: bool,
    execution-payload-data: (optional (buff 256))
  }
)

;; Vote tracking
(define-map member-proposal-votes {proposal-id: uint, voting-member: principal} bool)

;; Role permission definitions
(define-map role-permission-matrix (string-ascii 20)
  {
    can-invite-new-members: bool,
    can-remove-existing-members: bool,
    can-submit-proposals: bool,
    can-execute-approved-proposals: bool,
    can-manage-role-permissions: bool
  }
)

;; INITIALIZATION FUNCTIONS

(define-private (setup-default-role-permissions)
  (begin
    ;; Administrator role with full permissions
    (map-set role-permission-matrix "admin" {
      can-invite-new-members: true,
      can-remove-existing-members: true,
      can-submit-proposals: true,
      can-execute-approved-proposals: true,
      can-manage-role-permissions: true
    })
    ;; Moderator role with limited permissions
    (map-set role-permission-matrix "moderator" {
      can-invite-new-members: true,
      can-remove-existing-members: false,
      can-submit-proposals: true,
      can-execute-approved-proposals: true,
      can-manage-role-permissions: false
    })
    ;; Standard member role with basic permissions
    (map-set role-permission-matrix "member" {
      can-invite-new-members: false,
      can-remove-existing-members: false,
      can-submit-proposals: true,
      can-execute-approved-proposals: false,
      can-manage-role-permissions: false
    })
    (ok true)
  )
)

;; READ-ONLY QUERY FUNCTIONS

(define-read-only (get-member-profile-details (member-address principal))
  (map-get? group-member-profiles member-address)
)

(define-read-only (check-if-active-member (user-address principal))
  (match (map-get? group-member-profiles user-address)
    member-profile-data (get is-currently-active member-profile-data)
    false
  )
)

(define-read-only (get-current-member-count)
  (var-get current-total-members)
)

(define-read-only (get-proposal-details (proposal-identifier uint))
  (map-get? governance-proposals proposal-identifier)
)

(define-read-only (check-if-member-has-voted (proposal-identifier uint) (voter-address principal))
  (is-some (map-get? member-proposal-votes {proposal-id: proposal-identifier, voting-member: voter-address}))
)

(define-read-only (get-member-activity-stats (member-address principal))
  (default-to 
    {total-proposals-created: u0, total-votes-cast: u0, participation-attendance-rate: u0}
    (map-get? member-activity-statistics member-address)
  )
)

(define-read-only (verify-member-permission (user-address principal) (requested-action (string-ascii 20)))
  (match (map-get? group-member-profiles user-address)
    member-profile-data
      (match (map-get? role-permission-matrix (get assigned-role-type member-profile-data))
        role-permissions-data
          (if (is-eq requested-action "invite-members") (get can-invite-new-members role-permissions-data)
          (if (is-eq requested-action "remove-members") (get can-remove-existing-members role-permissions-data)
          (if (is-eq requested-action "create-proposals") (get can-submit-proposals role-permissions-data)
          (if (is-eq requested-action "execute-proposals") (get can-execute-approved-proposals role-permissions-data)
          (if (is-eq requested-action "modify-roles") (get can-manage-role-permissions role-permissions-data)
          false)))))
        false
      )
    false
  )
)

(define-read-only (check-member-suspension-status (member-address principal))
  (match (map-get? group-member-profiles member-address)
    member-profile-data
      (match (get suspension-expires-at-block member-profile-data)
        suspension-expiry-block (> suspension-expiry-block block-height)
        false
      )
    false
  )
)

(define-read-only (get-group-configuration-info)
  {
    group-name: (var-get group-display-name),
    description: (var-get group-description-text),
    total-members: (var-get current-total-members),
    max-capacity: (var-get maximum-allowed-members),
    voting-threshold: (var-get required-voting-threshold-percentage),
    proposal-duration: (var-get proposal-voting-window-duration)
  }
)

;; PRIVATE UTILITY FUNCTIONS

(define-private (validate-member-not-suspended (member-address principal))
  (if (check-member-suspension-status member-address)
    ERR-MEMBER-CURRENTLY-SUSPENDED
    (ok true)
  )
)

(define-private (update-member-activity-metrics (member-address principal) (activity-type (string-ascii 20)))
  (let ((current-activity-stats (get-member-activity-stats member-address)))
    (if (is-eq activity-type "proposal-creation")
      (map-set member-activity-statistics member-address 
        (merge current-activity-stats {total-proposals-created: (+ (get total-proposals-created current-activity-stats) u1)}))
    (if (is-eq activity-type "vote-casting")
      (map-set member-activity-statistics member-address 
        (merge current-activity-stats {total-votes-cast: (+ (get total-votes-cast current-activity-stats) u1)}))
      false))
  )
)

(define-private (calculate-proposal-approval-rate (affirmative-votes uint) (negative-votes uint))
  (let ((total-vote-count (+ affirmative-votes negative-votes)))
    (if (> total-vote-count u0)
      (/ (* affirmative-votes u100) total-vote-count)
      u0)
  )
)

(define-private (validate-role-exists (role-name (string-ascii 20)))
  (is-some (map-get? role-permission-matrix role-name))
)

;; PUBLIC TRANSACTION FUNCTIONS

(define-public (initialize-group-settings (group-name (string-ascii 50)) (description (string-utf8 500)))
  (if (is-eq tx-sender contract-owner-address)
    (begin
      (var-set group-display-name group-name)
      (var-set group-description-text description)
      (unwrap-panic (setup-default-role-permissions))
      (map-set group-member-profiles contract-owner-address {
        membership-start-block: block-height,
        assigned-role-type: "admin",
        reputation-score: initial-admin-reputation-score,
        is-currently-active: true,
        suspension-expires-at-block: none
      })
      (var-set current-total-members u1)
      (ok true)
    )
    ERR-UNAUTHORIZED-ACCESS
  )
)

(define-public (invite-new-member (new-member-address principal) (role-assignment (string-ascii 20)))
  (let ((caller-has-invite-permission (verify-member-permission tx-sender "invite-members")))
    (asserts! caller-has-invite-permission ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-none (map-get? group-member-profiles new-member-address)) ERR-MEMBER-ALREADY-EXISTS)
    (asserts! (< (var-get current-total-members) (var-get maximum-allowed-members)) ERR-GROUP-MEMBER-CAPACITY-EXCEEDED)
    (asserts! (validate-role-exists role-assignment) ERR-INVALID-ROLE-TYPE)
    
    (map-set group-member-profiles new-member-address {
      membership-start-block: block-height,
      assigned-role-type: role-assignment,
      reputation-score: u0,
      is-currently-active: true,
      suspension-expires-at-block: none
    })
    (var-set current-total-members (+ (var-get current-total-members) u1))
    (ok true)
  )
)

(define-public (remove-existing-member (member-to-remove principal))
  (let ((caller-has-removal-permission (verify-member-permission tx-sender "remove-members")))
    (asserts! caller-has-removal-permission ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-some (map-get? group-member-profiles member-to-remove)) ERR-MEMBER-NOT-FOUND)
    
    (map-set group-member-profiles member-to-remove 
      (merge (unwrap-panic (map-get? group-member-profiles member-to-remove)) {is-currently-active: false}))
    (var-set current-total-members (- (var-get current-total-members) u1))
    (ok true)
  )
)

(define-public (modify-member-role (target-member principal) (new-role-assignment (string-ascii 20)))
  (let ((caller-has-modification-permission (verify-member-permission tx-sender "modify-roles")))
    (asserts! caller-has-modification-permission ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-some (map-get? group-member-profiles target-member)) ERR-MEMBER-NOT-FOUND)
    (asserts! (validate-role-exists new-role-assignment) ERR-INVALID-ROLE-TYPE)
    
    (map-set group-member-profiles target-member 
      (merge (unwrap-panic (map-get? group-member-profiles target-member)) {assigned-role-type: new-role-assignment}))
    (ok true)
  )
)

(define-public (submit-governance-proposal 
    (proposal-title (string-ascii 100)) 
    (proposal-description (string-utf8 1000))
    (proposal-category (string-ascii 20))
    (execution-data (optional (buff 256))))
  (let (
    (current-proposal-id (var-get next-proposal-identifier))
    (caller-has-proposal-permission (verify-member-permission tx-sender "create-proposals"))
  )
    (asserts! caller-has-proposal-permission ERR-UNAUTHORIZED-ACCESS)
    (try! (validate-member-not-suspended tx-sender))
    
    (map-set governance-proposals current-proposal-id {
      proposal-creator: tx-sender,
      proposal-title: proposal-title,
      proposal-description: proposal-description,
      proposal-category-type: proposal-category,
      proposal-creation-block: block-height,
      voting-deadline-block: (+ block-height (var-get proposal-voting-window-duration)),
      affirmative-vote-count: u0,
      negative-vote-count: u0,
      has-been-executed: false,
      execution-payload-data: execution-data
    })
    
    (var-set next-proposal-identifier (+ current-proposal-id u1))
    (update-member-activity-metrics tx-sender "proposal-creation")
    (ok current-proposal-id)
  )
)

(define-public (cast-vote-on-proposal (proposal-identifier uint) (vote-in-favor bool))
  (let (
    (proposal-details (unwrap! (map-get? governance-proposals proposal-identifier) ERR-PROPOSAL-DOES-NOT-EXIST))
    (voter-profile (unwrap! (map-get? group-member-profiles tx-sender) ERR-MEMBER-NOT-FOUND))
  )
    (asserts! (get is-currently-active voter-profile) ERR-MEMBER-NOT-FOUND)
    (asserts! (< block-height (get voting-deadline-block proposal-details)) ERR-PROPOSAL-VOTING-EXPIRED)
    (asserts! (not (check-if-member-has-voted proposal-identifier tx-sender)) ERR-DUPLICATE-VOTE-ATTEMPT)
    (asserts! (not (get has-been-executed proposal-details)) ERR-PROPOSAL-ALREADY-EXECUTED)
    (try! (validate-member-not-suspended tx-sender))
    
    (map-set member-proposal-votes {proposal-id: proposal-identifier, voting-member: tx-sender} vote-in-favor)
    
    (if vote-in-favor
      (map-set governance-proposals proposal-identifier 
        (merge proposal-details {affirmative-vote-count: (+ (get affirmative-vote-count proposal-details) u1)}))
      (map-set governance-proposals proposal-identifier 
        (merge proposal-details {negative-vote-count: (+ (get negative-vote-count proposal-details) u1)}))
    )
    
    (update-member-activity-metrics tx-sender "vote-casting")
    (ok true)
  )
)

(define-public (execute-approved-proposal (proposal-identifier uint))
  (let (
    (proposal-details (unwrap! (map-get? governance-proposals proposal-identifier) ERR-PROPOSAL-DOES-NOT-EXIST))
    (proposal-approval-percentage (calculate-proposal-approval-rate 
                                    (get affirmative-vote-count proposal-details) 
                                    (get negative-vote-count proposal-details)))
  )
    (asserts! (verify-member-permission tx-sender "execute-proposals") ERR-UNAUTHORIZED-ACCESS)
    (asserts! (>= block-height (get voting-deadline-block proposal-details)) ERR-PROPOSAL-VOTING-EXPIRED)
    (asserts! (not (get has-been-executed proposal-details)) ERR-PROPOSAL-ALREADY-EXECUTED)
    (asserts! (>= proposal-approval-percentage (var-get required-voting-threshold-percentage)) ERR-INSUFFICIENT-VOTE-COUNT)
    
    (map-set governance-proposals proposal-identifier (merge proposal-details {has-been-executed: true}))
    (ok true)
  )
)

(define-public (suspend-member-temporarily (target-member principal) (suspension-duration-blocks uint))
  (let ((caller-has-removal-permission (verify-member-permission tx-sender "remove-members")))
    (asserts! caller-has-removal-permission ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-some (map-get? group-member-profiles target-member)) ERR-MEMBER-NOT-FOUND)
    (asserts! (> suspension-duration-blocks u0) ERR-INVALID-SUSPENSION-DURATION)
    
    (map-set group-member-profiles target-member 
      (merge (unwrap-panic (map-get? group-member-profiles target-member)) 
        {suspension-expires-at-block: (some (+ block-height suspension-duration-blocks))}))
    (ok true)
  )
)

;; ADMINISTRATIVE FUNCTIONS

(define-public (update-voting-threshold-percentage (new-threshold-percentage uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner-address) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (and (>= new-threshold-percentage minimum-threshold-percentage) 
                  (<= new-threshold-percentage maximum-threshold-percentage)) ERR-INVALID-THRESHOLD-VALUE)
    (var-set required-voting-threshold-percentage new-threshold-percentage)
    (ok true)
  )
)

(define-public (update-maximum-member-capacity (new-maximum-capacity uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner-address) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (>= new-maximum-capacity (var-get current-total-members)) ERR-INVALID-THRESHOLD-VALUE)
    (var-set maximum-allowed-members new-maximum-capacity)
    (ok true)
  )
)

(define-public (update-proposal-voting-duration (new-duration-blocks uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner-address) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> new-duration-blocks u0) ERR-INVALID-SUSPENSION-DURATION)
    (var-set proposal-voting-window-duration new-duration-blocks)
    (ok true)
  )
)

;; CONTRACT INITIALIZATION

;; Initialize default role permissions on contract deployment
(setup-default-role-permissions)