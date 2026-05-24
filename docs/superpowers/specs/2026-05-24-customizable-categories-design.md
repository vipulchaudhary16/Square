# Customizable Categories — Design Spec

**Date:** 2026-05-24  
**Status:** Approved

---

## Overview

Replace hardcoded category strings (Food, Transport, etc.) across expenses, incomes, and budgets with a per-user `categories` table. Users start with seeded standard categories and can create, rename, and delete their own. Standard categories cannot be deleted. Deleting a custom category reassigns all its records to "Other".

---

## Data Model

### New: `categories` table

| Column | Type | Notes |
|--------|------|-------|
| `id` | bigint PK | |
| `user_id` | bigint FK → users | not null |
| `name` | string | not null |
| `applies_to` | string[] | default: `["expense", "income", "budget"]` |
| `is_standard` | boolean | default: false |
| `created_at` | datetime | |
| `updated_at` | datetime | |

Unique index on `(user_id, name)`.

### Standard categories (seeded at signup for every user)

All standard categories have `applies_to: ["expense", "income", "budget"]` and `is_standard: true`:

`Food, Transport, Utilities, Entertainment, Shopping, Health, Travel, General, Other`

"Other" is the fallback category — always present, standard, cannot be deleted.

### Modified tables

`expenses`, `incomes`, `budgets` — replace `category` (string) with `category_id` (bigint FK → categories, not null).

### Migration path for existing data

1. Create `categories` table
2. Seed standard categories for all existing users
3. Add `category_id` (nullable) to `expenses`, `incomes`, `budgets`
4. Backfill: match existing `category` string value to `category_id` by name (case-insensitive). Fall back to "General" if no match found.
5. Set `category_id` to not null
6. Drop old `category` string columns

---

## API

### New resource: `/api/categories`

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/categories` | List current user's categories. Optional `?applies_to=expense\|income\|budget` filter |
| `POST` | `/api/categories` | Create a custom category |
| `PATCH` | `/api/categories/:id` | Rename a category (blocked for standard categories) |
| `DELETE` | `/api/categories/:id` | Delete — reassigns records to "Other"; blocked if `is_standard: true` |

**GET response:**
```json
[
  { "id": "1", "name": "Food", "applies_to": ["expense", "income", "budget"], "is_standard": true },
  { "id": "12", "name": "Freelance", "applies_to": ["income"], "is_standard": false }
]
```

**POST / PATCH body:**
```json
{ "name": "Freelance", "applies_to": ["income", "budget"] }
```

### Modified responses for expenses / incomes / budgets

Replace `"category": "Food"` with `"category_id": "1", "category_name": "Food"` in all list and detail responses. This avoids a separate lookup on the client side.

### Delete behaviour (server-side)

Before destroying a category:
1. Find the user's "Other" category
2. Update all expenses/incomes/budgets with `category_id = deleted_id` to `category_id = other_id`
3. Destroy the category record

---

## UI / UX

### Profile / Settings — "Categories" section (web + Flutter)

- List of user's categories with name and `applies_to` chips (Expense / Income / Budget)
- Standard categories show a lock icon — no delete or rename action
- Custom categories show rename (pencil) and delete (trash) actions
- "Add Category" opens a modal/sheet with:
  - Name text input
  - Multi-select for applies_to: Expense, Income, Budget (at least one required)
- Delete shows a confirmation dialog: "Deleting '[name]' will move all its records to 'Other'. Continue?"

### Forms (expense / income / budget)

- Category field is a dynamic dropdown populated from `GET /api/categories?applies_to=<type>`
- Replaces the current static `<select>` (web) and hardcoded chip list (Flutter)

---

## Error handling

| Scenario | Response |
|----------|----------|
| Delete standard category | 422 `"Standard categories cannot be deleted"` |
| Rename standard category | 422 `"Standard categories cannot be renamed"` |
| Duplicate category name | 422 `"Category name already exists"` |
| Delete "Other" | 422 (it is standard, blocked by standard rule) |
| `applies_to` empty array | 422 `"applies_to must include at least one type"` |

---

## Out of scope

- Category icons or colors (can be added later as columns on the categories table)
- Shared/group-level categories
- Reordering categories
