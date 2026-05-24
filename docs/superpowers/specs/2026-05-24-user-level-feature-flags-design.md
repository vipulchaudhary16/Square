# User-Level Feature Flags Design

**Date:** 2026-05-24  
**Status:** Approved

---

## Overview

Move feature flags from a hardcoded static Dart class to a per-user system backed by MongoDB. Flags are defined in a registry collection and user overrides are stored on the user document. Some flags are user-toggleable via a settings screen; others are admin-controlled via direct MongoDB access.

---

## Data Model

### `feature_flag_registry` collection

Each document defines one feature flag:

```json
{
  "_id": ObjectId("507f1f77bcf86cd799439011"),
  "key": "show_expense_trends_chart",
  "description": "Show expense trends chart on dashboard",
  "category": "dashboard",
  "user_toggleable": true,
  "default_value": false
}
```

- `_id`: Standard MongoDB ObjectId (primary key)
- `key`: Unique string identifier used by code to look up a flag. Unique index required.
- `description`: Human-readable label shown in the settings UI
- `category`: Groups flags in the UI (e.g. `"dashboard"`, `"finance"`)
- `user_toggleable`: `true` = user can toggle via settings screen; `false` = admin-only
- `default_value`: Resolved value when no user override exists

Admins manage this collection directly in MongoDB (add, update, delete flag definitions). No admin API endpoint.

### `users` collection — new field

```json
{
  "feature_flags": {
    "507f1f77bcf86cd799439011": true
  }
}
```

- Map of `ObjectId hex string → bool`
- Stores only overrides from registry defaults
- Keys that don't exist in the registry are ignored at read time
- If a registry entry is deleted, the stored override for its id is silently ignored

---

## Backend

### Go Model

```go
// FlagRegistryEntry represents one entry in the feature_flag_registry collection
type FlagRegistryEntry struct {
    ID             primitive.ObjectID `bson:"_id,omitempty" json:"id"`
    Key            string             `bson:"key" json:"key"`
    Description    string             `bson:"description" json:"description"`
    Category       string             `bson:"category" json:"category"`
    UserToggleable bool               `bson:"user_toggleable" json:"user_toggleable"`
    DefaultValue   bool               `bson:"default_value" json:"default_value"`
}

// ResolvedFlag is the merged result returned to the client
type ResolvedFlag struct {
    ID             string `json:"id"`
    Key            string `json:"key"`
    Description    string `json:"description"`
    Category       string `json:"category"`
    UserToggleable bool   `json:"user_toggleable"`
    Value          bool   `json:"value"`
}
```

The `User` struct gains:

```go
FeatureFlags map[string]bool `bson:"feature_flags" json:"-"`
```

### API Endpoints

#### `GET /users/me/flags`

Protected. Fetches all registry entries and merges with the authenticated user's `feature_flags` overrides.

**Resolution logic:**
1. Fetch all docs from `feature_flag_registry`
2. For each, check if `user.feature_flags[id.Hex()]` exists
3. If yes, use stored value; if no, use `default_value`
4. Return array of `ResolvedFlag`

**Response 200:**
```json
[
  {
    "id": "507f1f77bcf86cd799439011",
    "key": "show_expense_trends_chart",
    "description": "Show expense trends chart on dashboard",
    "category": "dashboard",
    "user_toggleable": true,
    "value": true
  }
]
```

#### `PATCH /users/me/flags`

Protected. Updates user-toggleable flags only.

**Request body:**
```json
{
  "507f1f77bcf86cd799439011": true
}
```

**Validation:**
- Each key must be a valid ObjectId hex → 400 if not
- Each key must exist in `feature_flag_registry` → 400 if not found
- Each matched registry entry must have `user_toggleable: true` → 403 if not
- Valid keys are merged into `users.feature_flags` via `$set`

**Response 200:** Updated full flag list (same shape as `GET /users/me/flags`)

### Existing `GET /auth/me`

Unchanged. Feature flags are fetched via a separate endpoint to keep the user profile response lean.

---

## Flutter Layer

### Model

Replace `FeatureFlags` static class with:

```dart
class FeatureFlag {
  final String id;            // ObjectId hex
  final String key;
  final String description;
  final String category;
  final bool userToggleable;
  final bool value;
}
```

### Repository

New `FeatureFlagsRepository`:
- `Future<List<FeatureFlag>> getFlags()` → `GET /users/me/flags`
- `Future<List<FeatureFlag>> updateFlag(String id, bool value)` → `PATCH /users/me/flags`

### State

Replace `featureFlagsProvider` with `AsyncNotifierProvider<FeatureFlagsNotifier, List<FeatureFlag>>`:

- Loads flags on app start / after login
- `toggle(String id, bool value)` method: optimistic local update → `PATCH` call → revert on error
- Helper `flagValue(String key)` returns resolved bool (defaults `false` on loading/error)

### Existing flag consumption

`dashboard_screen.dart` and `dashboard_provider.dart` replace `FeatureFlags.showExpenseTrendsChart` with `ref.watch(featureFlagsProvider.notifier).flagValue('show_expense_trends_chart')`.

### Settings Screen

New `FeaturesSettingsScreen`:
- Fetches from `featureFlagsProvider`
- Groups flags by `category` using a `Map<String, List<FeatureFlag>>`
- Renders only `user_toggleable: true` flags as `SwitchListTile`
- Calls `notifier.toggle(id, value)` on switch change
- Reachable from the existing profile/settings navigation

---

## Migration

1. Create `feature_flag_registry` collection in MongoDB with a unique index on `key`
2. Insert the initial registry entry for `show_expense_trends_chart`
3. No migration needed for existing user documents — absence of `feature_flags` field resolves to registry defaults
4. Remove `square_app/lib/core/config/feature_flags.dart` once new provider is wired up

---

## Out of Scope

- Admin UI for managing the registry
- Cross-user flag analytics
- Flag expiry / scheduled rollouts
- Backend-side flag gating (e.g., skipping server computations based on flags) — current flags are UI-only
