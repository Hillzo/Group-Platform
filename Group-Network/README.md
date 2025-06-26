# Decentralized Group Membership Management System

A comprehensive smart contract for managing decentralized groups with role-based permissions, governance proposals, and member activity tracking on the Stacks blockchain.

## Overview

This smart contract provides a complete solution for managing decentralized groups with features including member management, role-based access control, proposal governance, and activity tracking. It's designed to facilitate democratic decision-making and transparent group operations.

## Features

### Core Functionality
- **Member Management**: Add, remove, and suspend members
- **Role-Based Access Control**: Three built-in roles with customizable permissions
- **Governance System**: Proposal creation, voting, and execution
- **Activity Tracking**: Monitor member participation and engagement
- **Suspension System**: Temporary member suspension capabilities
- **Configurable Parameters**: Adjustable voting thresholds and group settings

### Built-in Roles
1. **Admin**: Full permissions including role management and member removal
2. **Moderator**: Can invite members and execute proposals but cannot remove members
3. **Member**: Basic permissions to create proposals and vote

## Configuration Constants

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| Voting Threshold | 51% | Minimum approval percentage for proposals |
| Proposal Duration | 144 blocks | Voting window (~24 hours) |
| Max Group Capacity | 1000 members | Maximum allowed group size |
| Admin Reputation | 100 points | Initial reputation for contract owner |

## Data Structures

### Member Profile
```clarity
{
  membership-start-block: uint,
  assigned-role-type: string-ascii,
  reputation-score: uint,
  is-currently-active: bool,
  suspension-expires-at-block: optional uint
}
```

### Proposal Structure
```clarity
{
  proposal-creator: principal,
  proposal-title: string-ascii,
  proposal-description: string-utf8,
  proposal-category-type: string-ascii,
  proposal-creation-block: uint,
  voting-deadline-block: uint,
  affirmative-vote-count: uint,
  negative-vote-count: uint,
  has-been-executed: bool,
  execution-payload-data: optional buff
}
```

## Public Functions

### Group Initialization
```clarity
(initialize-group-settings group-name description)
```
Initialize the group with a name and description. Only callable by contract owner.

### Member Management
```clarity
(invite-new-member member-address role-assignment)
(remove-existing-member member-to-remove)
(modify-member-role target-member new-role-assignment)
(suspend-member-temporarily target-member suspension-duration-blocks)
```

### Governance
```clarity
(submit-governance-proposal title description category execution-data)
(cast-vote-on-proposal proposal-id vote-in-favor)
(execute-approved-proposal proposal-id)
```

### Administrative Functions
```clarity
(update-voting-threshold-percentage new-threshold)
(update-maximum-member-capacity new-capacity)
(update-proposal-voting-duration new-duration)
```

## Read-Only Functions

### Member Queries
- `get-member-profile-details`: Get detailed member information
- `check-if-active-member`: Verify if a user is an active member
- `get-member-activity-stats`: Retrieve member participation statistics
- `check-member-suspension-status`: Check if member is currently suspended

### Group Information
- `get-current-member-count`: Get total active members
- `get-group-configuration-info`: Get complete group settings

### Governance Queries
- `get-proposal-details`: Get proposal information
- `check-if-member-has-voted`: Verify if member voted on a proposal
- `verify-member-permission`: Check if member has specific permissions

## Permission System

Each role has specific permissions:

| Permission | Admin | Moderator | Member |
|------------|-------|-----------|--------|
| Invite Members | ✅ | ✅ | ❌ |
| Remove Members | ✅ | ❌ | ❌ |
| Create Proposals | ✅ | ✅ | ✅ |
| Execute Proposals | ✅ | ✅ | ❌ |
| Manage Roles | ✅ | ❌ | ❌ |

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | ERR-UNAUTHORIZED-ACCESS | Insufficient permissions |
| u101 | ERR-MEMBER-ALREADY-EXISTS | Member already in group |
| u102 | ERR-MEMBER-NOT-FOUND | Member doesn't exist |
| u103 | ERR-INVALID-ROLE-TYPE | Invalid role specified |
| u104 | ERR-PROPOSAL-DOES-NOT-EXIST | Proposal not found |
| u105 | ERR-DUPLICATE-VOTE-ATTEMPT | Member already voted |
| u106 | ERR-PROPOSAL-VOTING-EXPIRED | Voting period ended |
| u107 | ERR-INSUFFICIENT-VOTE-COUNT | Not enough votes to pass |
| u108 | ERR-PROPOSAL-ALREADY-EXECUTED | Proposal already executed |
| u109 | ERR-INVALID-THRESHOLD-VALUE | Invalid threshold setting |
| u110 | ERR-GROUP-MEMBER-CAPACITY-EXCEEDED | Group at max capacity |
| u111 | ERR-INVALID-SUSPENSION-DURATION | Invalid suspension period |
| u112 | ERR-MEMBER-CURRENTLY-SUSPENDED | Member is suspended |

## Usage Examples

### Initialize a Group
```clarity
(contract-call? .group-management initialize-group-settings 
  "Developer DAO" 
  u"A decentralized autonomous organization for developers")
```

### Invite a New Member
```clarity
(contract-call? .group-management invite-new-member 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
  "member")
```

### Create a Proposal
```clarity
(contract-call? .group-management submit-governance-proposal 
  "Increase Member Limit" 
  u"Proposal to increase maximum group capacity to 2000 members"
  "administrative"
  none)
```

### Vote on a Proposal
```clarity
(contract-call? .group-management cast-vote-on-proposal u0 true)
```

## Deployment Instructions

1. Deploy the contract to the Stacks blockchain
2. Call `initialize-group-settings` with your group details
3. The contract owner automatically becomes an admin
4. Begin inviting members and creating proposals

## Security Considerations

- Only the contract owner can modify system parameters
- Members must be active and not suspended to participate
- Proposals require majority approval to execute
- All role changes require admin privileges
- Voting is time-limited to prevent stale proposals

## Contributing

This contract is designed to be extensible. Consider these enhancement areas:
- Custom role creation
- Reputation-based voting weights
- Multi-signature proposal execution
- Integration with external governance tokens
- Advanced activity metrics