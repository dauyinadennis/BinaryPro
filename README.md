# BinaryPro - Prediction Framework for Binary Events

A comprehensive prediction market platform where participants wager PWR tokens on binary outcomes. The system features a sophisticated oracle network that finalizes results and automatically distributes payouts to winning participants, creating a decentralized and trustless prediction ecosystem.

## Contract Overview

### Tokens
- **PWR**: Prediction Wager Rewards token used for all betting activities
- **ORACLE**: Oracle governance token required for oracle registration and staking

### Key Innovation

BinaryPro revolutionizes prediction markets through:
1. **Decentralized Oracle System**: Community-driven result verification with reputation tracking
2. **Dynamic Odds Calculation**: Real-time odds based on betting pool distribution
3. **Comprehensive Dispute Mechanism**: Multi-layered resolution system for contested outcomes
4. **Category-Based Organization**: Structured event categorization for better discovery

## Core Features

### 🎯 **Event Creation & Management**

#### Create Prediction Events
```clarity
(create-event title description category source-url duration resolution-delay)
```
- Define binary prediction events with rich metadata
- Set custom betting and resolution periods
- Optional source URL for verification
- Automatic category statistics tracking

#### Event Lifecycle Management
- **Open Phase**: Active betting period with dynamic odds
- **Closed Phase**: Betting ended, awaiting oracle resolution
- **Resolved Phase**: Oracle has determined outcome, payouts available
- **Disputed Phase**: Resolution contested, under review

### 🎲 **Betting System**

#### Place Bets on Outcomes
```clarity
(place-bet event-id outcome amount)
```
- Bet on YES (1) or NO (2) outcomes
- Dynamic odds calculation based on pool distribution
- Minimum bet: 1,000 PWR tokens
- Maximum bet: 10,000,000 PWR tokens

#### Advanced Betting Features
- **Real-time Odds**: Odds update with each bet placed
- **Payout Calculation**: Transparent fee breakdown and potential returns
- **Bet History**: Complete tracking of all user betting activity
- **Pool Analytics**: Detailed statistics on betting pools

### 🔮 **Oracle System**

#### Oracle Registration & Management
```clarity
(register-oracle name stake-amount)
```
- Minimum stake: 100,000 ORACLE tokens
- Reputation-based scoring system
- Activity tracking and performance metrics
- Dispute resolution capabilities

#### Event Resolution Process
```clarity
(resolve-event event-id outcome evidence)
```
- Oracle-driven outcome determination
- Evidence-based resolution with transparency
- Automatic fee distribution to oracles
- Reputation updates based on accuracy

### 💰 **Payout & Fee System**

#### Automatic Payout Distribution
- **Oracle Fee**: 2.5% of total pool to resolving oracle
- **Platform Fee**: 1.5% of total pool for protocol maintenance
- **Winner Payouts**: Remaining pool distributed to winning bettors
- **Refunds**: Full refunds for invalid/cancelled events

#### Claim Winnings
```clarity
(claim-winnings bet-id)
```
- Automatic calculation of winnings based on odds
- One-time claiming per bet
- Transparent fee deduction
- User statistics updates

## Event Categories & Organization

### Predefined Categories
- **Sports**: Athletic competitions and tournaments
- **Politics**: Elections, policy decisions, political events
- **Economics**: Market predictions, economic indicators
- **Technology**: Product launches, adoption metrics
- **Entertainment**: Awards, box office, cultural events
- **Weather**: Climate predictions, natural phenomena

### Category Management
```clarity
(create-category name description)
```
- Admin-controlled category creation
- Category-specific statistics tracking
- Volume and event count monitoring
- Active/inactive status management

## Oracle System Architecture

### Oracle Registration
- **Stake Requirement**: 100,000 ORACLE tokens minimum
- **Reputation System**: Performance-based scoring (0-100%)
- **Activity Tracking**: Resolution history and accuracy metrics
- **Slashing Mechanism**: Stake reduction for poor performance

### Resolution Process
1. **Event Closure**: Betting period ends automatically
2. **Resolution Window**: Oracle can resolve after resolution delay
3. **Evidence Submission**: Oracle provides supporting evidence
4. **Outcome Recording**: Result permanently recorded on-chain
5. **Fee Distribution**: Oracle receives 2.5% of total pool

### Dispute Mechanism
```clarity
(dispute-resolution event-id proposed-outcome reason stake-amount)
```
- **Dispute Period**: 10 days after resolution
- **Minimum Stake**: 10,000 PWR tokens to dispute
- **Community Review**: Disputed resolutions reviewed by protocol
- **Stake Slashing**: Incorrect disputes result in stake loss

## Usage Examples

### 🎯 **Event Creator Flow**
```clarity
;; 1. Create a sports prediction event
(contract-call? .binary-prediction create-event
    "Will Team A win the championship?"
    "Prediction for the upcoming championship final match"
    "Sports"
    (some "https://sports-league.com/championship")
    u1440   ;; 10 days betting period
    u144)   ;; 1 day resolution delay

;; 2. Monitor event statistics
(contract-call? .binary-prediction get-event u1)
(contract-call? .binary-prediction get-event-pool u1)
```

### 🎲 **Bettor Experience**
```clarity
;; 1. Get PWR tokens for betting
(contract-call? .binary-prediction mint-pwr u100000 tx-sender)

;; 2. Check current odds and potential payout
(contract-call? .binary-prediction calculate-odds u1 u1) ;; YES outcome
(contract-call? .binary-prediction calculate-payout u1 u1 u10000)

;; 3. Place bet on YES outcome
(contract-call? .binary-prediction place-bet u1 u1 u10000)

;; 4. Monitor betting activity
(contract-call? .binary-prediction get-user-bets tx-sender)

;; 5. Claim winnings after resolution
(contract-call? .binary-prediction claim-winnings u1)
```

### 🔮 **Oracle Workflow**
```clarity
;; 1. Get ORACLE tokens and register
(contract-call? .binary-prediction mint-oracle u200000 tx-sender)
(contract-call? .binary-prediction register-oracle "TrustOracle" u150000)

;; 2. Monitor events ready for resolution
(contract-call? .binary-prediction get-events-by-status u2) ;; Closed events

;; 3. Resolve event with evidence
(contract-call? .binary-prediction resolve-event 
    u1 
    u1  ;; YES outcome
    "Team A won 3-1 in the championship final")

;; 4. Track oracle performance
(contract-call? .binary-prediction get-oracle tx-sender)
```

### 📊 **Analytics & Monitoring**
```clarity
;; Market overview
(contract-call? .binary-prediction get-market-stats)

;; Category performance
(contract-call? .binary-prediction get-category "Sports")

;; User statistics
(contract-call? .binary-prediction get-user-bets user-address)
(contract-call? .binary-prediction get-user-event-history user-address)

;; Event details
(contract-call? .binary-prediction get-event u1)
(contract-call? .binary-prediction get-event-pool u1)
```

## Mathematical Framework

### Odds Calculation
```
For YES outcome:
Odds = (Total Pool × Precision) ÷ YES Pool

For NO outcome:
Odds = (Total Pool × Precision) ÷ NO Pool

Initial odds (no bets): 1:1 (1,000,000 precision units)
```

### Payout Distribution
```
Gross Payout = Bet Amount × Odds ÷ Precision
Oracle Fee = Gross Payout × 2.5%
Platform Fee = Gross Payout × 1.5%
Net Payout = Gross Payout - Oracle Fee - Platform Fee
```

### Example Calculation
```
Event Pool: 100,000 PWR
YES Pool: 60,000 PWR (60%)
NO Pool: 40,000 PWR (40%)

YES Odds = 100,000 × 1,000,000 ÷ 60,000 = 1,666,667 (1.67:1)
NO Odds = 100,000 × 1,000,000 ÷ 40,000 = 2,500,000 (2.5:1)

For 10,000 PWR bet on NO:
Gross Payout = 10,000 × 2,500,000 ÷ 1,000,000 = 25,000 PWR
Oracle Fee = 25,000 × 0.025 = 625 PWR
Platform Fee = 25,000 × 0.015 = 375 PWR
Net Payout = 25,000 - 625 - 375 = 24,000 PWR
```

## Security Features

### 🛡️ **Betting Security**
- **Balance Validation**: Sufficient PWR balance required before betting
- **Amount Limits**: Minimum and maximum bet amounts enforced
- **Event Status Checks**: Only open events accept new bets
- **Double-Bet Prevention**: Users can place multiple bets on same event

### 🔒 **Oracle Security**
- **Stake Requirements**: Significant ORACLE token stake required
- **Reputation System**: Performance-based oracle scoring
- **Dispute Mechanism**: Community-driven resolution challenges
- **Evidence Requirements**: Oracles must provide supporting evidence

### 📊 **System Security**
- **Emergency Pause**: Admin can halt all market activities
- **Access Controls**: Role-based permissions for different functions
- **Fee Validation**: Automatic fee calculation and distribution
- **State Management**: Comprehensive event lifecycle tracking

## Error Handling

### Comprehensive Error Codes
- `u700`: Unauthorized access
- `u701`: Event not found
- `u702`: Event closed for betting
- `u703`: Event still active
- `u704`: Invalid outcome specified
- `u705`: Insufficient balance
- `u706`: Invalid amount
- `u707`: Transfer failed
- `u708`: Already resolved/claimed
- `u709`: Bet not found
- `u710`: Invalid oracle
- `u711`: Oracle dispute error
- `u712`: Market paused

### Validation & Safety
- **Input Validation**: All parameters validated before execution
- **State Verification**: Event status checked for all operations
- **Balance Checks**: Sufficient token balance verified
- **Time Validation**: Event timing and duration validation

## Advanced Features

### 🎯 **Dynamic Pricing**
- **Real-time Odds**: Odds update with each bet placement
- **Pool-based Calculation**: Odds reflect actual betting distribution
- **Arbitrage Prevention**: Automatic price discovery mechanism
- **Liquidity Incentives**: Better odds for early bettors

### 📊 **Analytics Dashboard**
- **User Performance**: Win rates, total wagered, profit/loss
- **Oracle Metrics**: Resolution accuracy, reputation scores
- **Market Trends**: Volume, popular categories, event success rates
- **Category Analytics**: Performance by event type

### 🔄 **Automated Systems**
- **Event Lifecycle**: Automatic status transitions
- **Fee Distribution**: Automatic oracle and platform payments
- **Payout Calculation**: Real-time payout estimation
- **Statistics Updates**: Automatic user and oracle metrics

## Dispute Resolution System

### Dispute Process
1. **Dispute Initiation**: Stake PWR tokens to challenge resolution
2. **Evidence Review**: Community examines oracle evidence
3. **Resolution Review**: Protocol team evaluates dispute
4. **Outcome Decision**: Final determination with stake distribution
5. **Reputation Update**: Oracle reputation adjusted based on outcome

### Dispute Outcomes
- **Valid Dispute**: Oracle stake slashed, disputer rewarded
- **Invalid Dispute**: Disputer stake slashed, oracle rewarded
- **Inconclusive**: Stakes returned, event marked invalid

## Future Enhancements

- **Multi-Oracle Consensus**: Require multiple oracle confirmations
- **Automated Resolution**: Integration with external data feeds
- **Prediction Tournaments**: Competitive prediction challenges
- **Social Features**: Following successful predictors and oracles
- **Cross-Chain Integration**: Multi-blockchain prediction markets

## Mathematical Formulas

### Odds Calculation
```
Odds(outcome) = (Total Pool × Precision) ÷ Outcome Pool
Where Precision = 1,000,000 for 6 decimal places
```

### Win Rate Calculation
```
Win Rate = (Total Won × 100) ÷ Total Wagered
Oracle Reputation = (Correct Resolutions × 100) ÷ Total Resolutions
```

### Pool Distribution
```
Winner Share = (Bet Amount × Odds) ÷ Precision
Oracle Fee = Total Pool × 2.5%
Platform Fee = Total Pool × 1.5%
```

BinaryPro represents the next generation of prediction markets, combining decentralized oracle networks with sophisticated betting mechanisms to create a trustless, transparent, and efficient platform for forecasting future events across multiple domains.