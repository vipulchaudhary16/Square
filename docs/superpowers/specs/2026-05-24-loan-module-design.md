# Loan Module — Design Spec

**Date:** 2026-05-24  
**Status:** Approved

---

## Overview

Redesign the loan module from a personal ledger into a bilateral debt-tracking system. Both lender and borrower can view the same loan record. The lender owns the record (full CRUD); the borrower has read-only access plus the ability to set a confirmation status. Supports partial repayments, flexible interest modes, and multi-channel reminders.

---

## 1. Data Model

### 1.1 New table: `contacts`

Each user maintains their own contact list. A contact is either a platform user (linked via `linked_user_id`) or an off-platform person (name + phone + email only).

```
contacts
  id                  bigint PK
  owner_user_id       bigint FK → users   (the user who owns this contact entry)
  linked_user_id      bigint FK → users   nullable  (set if contact is on the platform)
  name                string
  phone               string nullable
  email               string nullable
  created_at          datetime
  updated_at          datetime
```

**Lookup flow when creating a loan:** search by username, phone, or email. If a match is found on the platform, `linked_user_id` is set and `borrower_user_id` on the loan is populated. If no match, contact is stored as off-platform only.

### 1.2 Modified table: `loans`

`loan_type` column dropped — direction is inferred from whether `lender_user_id == current_user`.  
`status` gains a `PARTIAL` state.  
Interest config stored inline (no separate table).

```
loans
  id                    bigint PK
  lender_user_id        bigint FK → users          (owner — full access)
  borrower_user_id      bigint FK → users nullable  (set if borrower is on platform — read-only)
  contact_id            bigint FK → contacts        (the counterparty contact record)
  amount                decimal(12,2)               (original principal)
  date                  datetime
  due_date              datetime nullable            (required when interest_mode = 'penalty')
  status                string  PENDING | PARTIAL | PAID
  confirmation_status   string  pending | confirmed | disputed  default: pending
  confirmed_at          datetime nullable
  interest_mode         string  none | from_start | penalty    default: none
  interest_rate         decimal nullable             (e.g. 0.02 = 2%)
  interest_period       string  daily | monthly | annual  nullable
  interest_basis        string  principal | total   nullable
  description           text nullable
  category_id           bigint FK → categories nullable
  created_at            datetime
  updated_at            datetime
```

### 1.3 New table: `loan_payments`

Each row is one repayment event. Outstanding balance = `loans.amount − SUM(loan_payments.amount)`.

```
loan_payments
  id          bigint PK
  loan_id     bigint FK → loans
  amount      decimal(12,2)
  paid_at     datetime
  note        text nullable
  created_at  datetime
```

### 1.4 New table: `loan_reminders`

```
loan_reminders
  id               bigint PK
  loan_id          bigint FK → loans
  set_by_user_id   bigint FK → users
  remind_at        datetime
  nudge_borrower   boolean  default: false
  via_push         boolean  default: true
  via_sms          boolean  default: false
  via_email        boolean  default: true
  sent_at          datetime nullable
  created_at       datetime
```

### 1.5 Modified table: `users`

Add `mobile_number` (string, nullable) to support SMS delivery and phone-based contact lookup.

---

## 2. Access Control

| Action | Lender | Borrower |
|--------|--------|----------|
| View loan + payments | ✓ | ✓ |
| Edit loan (amount, date, interest, description) | ✓ | ✗ |
| Add payment | ✓ | ✗ |
| Delete loan | ✓ | ✗ |
| Set / edit reminders | ✓ | ✗ |
| Update `confirmation_status` | ✗ | ✓ |

API enforces this by checking `lender_user_id == current_user` vs `borrower_user_id == current_user`.

---

## 3. Interest Engine

Interest is **never stored** — computed on demand when the loan detail endpoint is called or when a payment is recorded. The API returns:

```json
{
  "outstanding": 6000.00,
  "accrued_interest": 160.00,
  "total_due": 6160.00,
  "daily_rate": 0.000667,
  "interest_timeline": [
    { "date": "2026-05-22", "daily_interest": 53.33, "cumulative": 53.33 },
    { "date": "2026-05-23", "daily_interest": 53.33, "cumulative": 106.67 },
    { "date": "2026-05-24", "daily_interest": 53.33, "cumulative": 160.00 }
  ]
}
```

### 3.1 Mode: `none`

```
outstanding = amount − Σ payments
interest    = 0
total_due   = outstanding
```

### 3.2 Mode: `from_start`

Interest accrues from `loan.date` regardless of due date.

```
days_elapsed = today − loan.date

# basis: principal
interest = outstanding × daily_rate × days_elapsed

# basis: total (compound)
interest = outstanding × ((1 + daily_rate) ^ days_elapsed − 1)
```

Payments reduce principal first; interest recalculates on remaining principal after each payment.

### 3.3 Mode: `penalty`

Zero interest until `due_date`. Penalty accrues on overdue days only. `due_date` is required for this mode.

```
days_overdue = max(0, today − due_date)

# basis: principal
interest = outstanding × daily_rate × days_overdue

# basis: total (compound)
interest = outstanding × ((1 + daily_rate) ^ days_overdue − 1)
```

### 3.4 Rate normalisation

All rates stored as decimals. Normalise to daily rate before calculation:
- `daily` → use as-is
- `monthly` → rate / 30
- `annual` → rate / 365

---

## 4. Payment & Settlement Flow

1. Lender taps **"Record Payment"** on the loan detail screen.
2. A bottom sheet opens pre-filled with `total_due` (outstanding + accrued interest).
3. If `accrued_interest > 0`, an "Add interest to Income" toggle is shown (default: on).
4. Lender can override the amount for a partial payment.
5. On confirm:
   - A `loan_payment` row is created.
   - If `Σ payments >= amount`, `loan.status` → `PAID`.
   - Else if `Σ payments > 0`, `loan.status` → `PARTIAL`.
   - If interest toggle was on, an `income` record is created for the interest amount with a generated description ("Interest on loan: [counterparty name]") and category "Interest Income" (created automatically if not present for the user).
6. Borrower receives an in-app / email / SMS notification: "Vipul marked ₹X received."

---

## 5. Counterparty Screen (Problem 1)

A dedicated screen per contact showing all loans with that person.

**Route:** `/contacts/:contact_id` or `Loans > tap counterparty name`

**Layout (Option A — approved):**
- Header: avatar, name, phone, platform badge (if linked)
- Net balance card: "Rahul owes you ₹12,400" or "You owe Rahul ₹X" — sum of all outstanding + interest across active loans
- Tabs: Active | Settled
- Loan list: each item shows description, date, due date, interest mode, amount, status chip
- "+ Add new loan with [name]" button at bottom — pre-fills the contact on the Add Loan screen

**Data query:** `loans WHERE contact_id = :id AND (lender_user_id = :me OR borrower_user_id = :me)`

---

## 6. Reminders

**Who can set:** lender only.

**Reminder options at creation:**
- Quick chips: Tomorrow / In 3 days / On due date / Custom date
- "On due date" chip is disabled (greyed out) if `due_date` is null
- Toggle: "Also nudge [borrower name]" — sends notification to borrower when reminder fires

**Delivery by counterparty type:**

| Counterparty | Lender notification | Borrower nudge |
|---|---|---|
| On-platform | Push + email + SMS (if mobile set) | Push + email + SMS |
| Off-platform | Push + email + SMS (if mobile set) | SMS + email (to saved contact details) |

**Auto-events (no reminder needed):**  
Borrower is notified automatically on: loan created, payment recorded, loan fully settled.

---

## 7. API Changes

### New endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/contacts` | List current user's contacts |
| POST | `/api/v1/contacts` | Create contact (with platform lookup) |
| GET | `/api/v1/contacts/:id/loans` | All loans with a contact (counterparty screen) |
| POST | `/api/v1/loans/:id/payments` | Record a payment |
| GET | `/api/v1/loans/:id/payments` | List payments for a loan |
| POST | `/api/v1/loans/:id/reminders` | Set a reminder |
| PATCH | `/api/v1/loans/:id/confirmation` | Borrower updates confirmation_status |

### Modified endpoints

- `GET /api/v1/loans` — now returns loans where user is lender OR borrower. Adds computed `outstanding`, `accrued_interest`, `total_due` fields.
- `GET /api/v1/loans/:id` — adds `payments`, `interest_timeline`, computed fields.
- `POST /api/v1/loans` — accepts `contact_id` instead of `counterparty_name`. Drops `loan_type`.
- `PATCH /api/v1/loans/:id` — lender-only fields enforced server-side.

---

## 8. Flutter App Changes

### New screens
- `ContactsScreen` — searchable list of contacts
- `ContactDetailScreen` — counterparty screen (net balance + loan list)
- `AddContactScreen` — create/link a contact

### Modified screens
- `AddEditLoanScreen` — replace `counterparty_name` text field with contact picker. Add interest config section (mode, rate, period, basis). Add due date (required for penalty mode).
- `LoanDetailScreen` (new) — shows payment history, interest timeline, "Record Payment" button, confirmation status badge (borrower view).

### New widgets
- `RecordPaymentSheet` — bottom sheet with amount input, date, note, interest-to-income toggle
- `InterestTimelineCard` — expandable daily interest breakdown
- `ReminderSheet` — quick chips + nudge toggle

### Model updates
- `Loan` — add `contact_id`, `borrower_user_id`, `confirmation_status`, `interest_mode`, `interest_rate`, `interest_period`, `interest_basis`, `outstanding`, `accrued_interest`, `total_due`
- New `LoanPayment` model
- New `Contact` model

---

## 9. Out of Scope

- Dispute resolution flow (confirmation_status = 'disputed' is stored but no in-app dispute chat)
- Multi-currency loans
- Loan sharing between more than two parties
- Mutual netting across multiple loans (net balance shown per-contact only, not globally)
