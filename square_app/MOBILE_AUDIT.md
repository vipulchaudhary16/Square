# Square Mobile — Feature Audit

*Reviewed 15 Aug 2026 · scope: `square_app` (Flutter) only · cross-checked against `rails_backend` routes*

**Status counts:** 6 Working · 4 Partial · 3 Not built · 5 concrete bugs

---

## Core

| Feature | Status | Notes |
|---|---|---|
| **Auth** | Partial | Login/signup fully wired to `/auth/login`, `/auth/signup`, session persists correctly. "Forgot Password" is a no-op (`auth_screen.dart:213`) despite working backend reset endpoints. No signup field validation. No 401-interceptor to force logout on an expired token. |
| **Dashboard** | Working | Real data from the `Dashboard::Engine` mount; expense-trends chart is genuinely feature-flag-gated. Minor: avatar shows a hardcoded letter instead of the user's real initial (`dashboard_screen.dart:60`). |
| **Feature Flags** | Working | Fetch/toggle fully wired, optimistic update with rollback on failure. |
| **Categories** | Working | Full CRUD, standard categories locked from edit/delete, correct "moves to Other" delete confirmation. |
| **Profile** | Partial | Logout + links to Feature Flags/Categories work. "Personal Information," "Settings," "Notifications," "Privacy & Security" are dead `onTap: () {}` rows (`profile_screen.dart:94,100,118,124`). |

## Money

| Feature | Status | Notes |
|---|---|---|
| **Expenses** | Working | Most complete feature — full CRUD, group splitting (equal/exact/percent) with validation, detail screen with pull-to-refresh fully wired. |
| **Loans** | Working | Interest timeline (simple/compound), record payment, reminders, confirm/dispute flow — all correctly wired. |
| **Income & Investments** | Partial | Create-only. No edit, delete, or detail screen — tapping a card does nothing, despite full backend CRUD support. |

## Social

| Feature | Status | Notes |
|---|---|---|
| **Contacts** | Working | List/search/add/edit all wired end-to-end, including per-contact loan history. |
| **Groups** | Partial | Create/list/view/invite/add-member all work. **Settle Up has zero UI** (backend: `POST /groups/:id/settle`, unused). **No invite-accept screen** (`POST /groups/join`, unused) — invite loop doesn't close on mobile. |

## Not built

| Feature | Status | Notes |
|---|---|---|
| **Reports** | Stub | Literal placeholder screen, not even linked from bottom nav. |
| **Budgets** | Stub | Full backend CRUD exists (`resources :budgets`), zero mobile UI. |
| **Comments** | Stub | Backend supports comments on expenses/incomes/investments/loans; no mobile UI anywhere. |

## Bugs found

1. Income entries always save with a blank title — the "source" field is sent as `''` (`add_edit_income_screen.dart`).
2. Color-key typo: `AppColors.slate[00]` (`create_group_screen.dart:79`) — likely meant `50`/`100`.
3. Dashboard avatar hardcoded to a letter, not the real user's initial (`dashboard_screen.dart:60`).
4. Dead code: an old non-paginated `ExpenseListScreen`/`ExpenseNotifier` pair, unreferenced by the router.
5. Group expenses hardcode the payer as "You" — can't record an expense someone else paid.

## Structural risk

`lib/data/api/api_client.dart` is a **0-byte empty file**. Every repository hand-rolls its own Dio instance and re-reads the token from SharedPreferences — duplicated across 10+ files, no central interceptor/401-handling. `api_constants.dart` also hardcodes `localhost`/`10.0.2.2` with no env override.

## Finishing order

1. Group Settle Up + invite-accept screen (core to the splitting-app promise)
2. Income/Investment edit, detail, delete (parity with Expenses)
3. Fix the income "source" bug
4. Build a real shared `ApiClient`
5. Wire up Forgot Password + Profile stubs, or remove them
6. Decide: build Reports/Budgets or drop from router
7. Delete dead `ExpenseListScreen`/`ExpenseNotifier`

**Before touching any of this:** the working tree has a large uncommitted diff across nearly every Rails controller/model plus untracked files (`concerns/trackable.rb`, `square_app/macos/Podfile`) — worth committing/reviewing first.
