# User-Level Feature Flags Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move feature flags from a hardcoded Dart static class to a per-user system backed by MongoDB, with a structured registry collection, user overrides on the user document, and a settings screen for user-toggleable flags.

**Architecture:** A `feature_flag_registry` MongoDB collection stores flag definitions (key, description, category, user_toggleable, default_value). The `users` collection gains a `feature_flags` map keyed by registry ObjectId hex. Two new protected endpoints (`GET/PATCH /api/users/me/flags`) merge registry defaults with user overrides. Flutter replaces the static `FeatureFlags` class with a Riverpod `AsyncNotifier` that fetches from the API and exposes a `toggle()` method used by a new `FeaturesSettingsScreen`.

**Tech Stack:** Go + Fiber + MongoDB (raw driver, bson), Dart + Flutter + Riverpod 2.x + Dio + GoRouter

---

## File Map

**Backend — new/modified:**
- Modify: `backend/pkg/models/models.go` — add `FlagRegistryEntry`, `ResolvedFlag`, `FeatureFlags` field on `User`
- Create: `backend/pkg/handlers/feature_flags.go` — `GetUserFlags`, `UpdateUserFlags`, pure helpers `mergeFlags`, `validateFlagUpdates`, `fetchRegistry`
- Create: `backend/pkg/handlers/feature_flags_test.go` — unit tests for pure helpers
- Modify: `backend/cmd/server/main.go` — register two new routes

**Flutter — new/modified:**
- Create: `square_app/lib/features/feature_flags/data/feature_flag_model.dart`
- Create: `square_app/lib/features/feature_flags/data/feature_flags_repository.dart`
- Create: `square_app/lib/features/feature_flags/presentation/feature_flags_provider.dart`
- Create: `square_app/lib/features/feature_flags/presentation/features_settings_screen.dart`
- Create: `square_app/test/features/feature_flags/feature_flag_model_test.dart`
- Modify: `square_app/lib/features/dashboard/presentation/dashboard_provider.dart`
- Modify: `square_app/lib/features/dashboard/presentation/dashboard_screen.dart`
- Modify: `square_app/lib/features/profile/presentation/profile_screen.dart`
- Modify: `square_app/lib/core/router.dart`
- Delete: `square_app/lib/core/config/feature_flags.dart`

---

## Task 1: Backend — Add models

**Files:**
- Modify: `backend/pkg/models/models.go`

- [ ] **Step 1: Add the three new types to models.go**

Open `backend/pkg/models/models.go` and append these structs after the `Budget` struct:

```go
type FlagRegistryEntry struct {
	ID             primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Key            string             `json:"key" bson:"key"`
	Description    string             `json:"description" bson:"description"`
	Category       string             `json:"category" bson:"category"`
	UserToggleable bool               `json:"user_toggleable" bson:"user_toggleable"`
	DefaultValue   bool               `json:"default_value" bson:"default_value"`
}

type ResolvedFlag struct {
	ID             string `json:"id"`
	Key            string `json:"key"`
	Description    string `json:"description"`
	Category       string `json:"category"`
	UserToggleable bool   `json:"user_toggleable"`
	Value          bool   `json:"value"`
}
```

- [ ] **Step 2: Add `FeatureFlags` field to the `User` struct**

In the `User` struct (lines 9–20), add the new field after `ResetTokenExpiry`:

```go
type User struct {
	ID               primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Username         string             `json:"username" bson:"username"`
	FirstName        string             `json:"first_name" bson:"first_name"`
	LastName         string             `json:"last_name" bson:"last_name"`
	Email            string             `json:"email" bson:"email"`
	Password         string             `json:"-" bson:"password,omitempty"`
	OTP              string             `json:"-" bson:"otp,omitempty"`
	OTPExpiry        time.Time          `json:"-" bson:"otp_expiry,omitempty"`
	ResetToken       string             `json:"-" bson:"reset_token,omitempty"`
	ResetTokenExpiry time.Time          `json:"-" bson:"reset_token_expiry,omitempty"`
	FeatureFlags     map[string]bool    `json:"-" bson:"feature_flags,omitempty"`
}
```

- [ ] **Step 3: Verify it compiles**

```bash
cd /Users/vipulchaudhary/Personal/Square/backend && go build ./...
```

Expected: no output (success).

- [ ] **Step 4: Commit**

```bash
cd /Users/vipulchaudhary/Personal/Square/backend
git add pkg/models/models.go
git commit -m "feat: add FlagRegistryEntry, ResolvedFlag models and FeatureFlags field on User"
```

---

## Task 2: Backend — Write failing tests for pure helpers

**Files:**
- Create: `backend/pkg/handlers/feature_flags_test.go`

- [ ] **Step 1: Create the test file**

Create `backend/pkg/handlers/feature_flags_test.go`:

```go
package handlers

import (
	"testing"

	"github.com/codewithvipul/expense-tracker/backend/pkg/models"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func TestMergeFlags(t *testing.T) {
	id1 := primitive.NewObjectID()
	id2 := primitive.NewObjectID()

	registry := []models.FlagRegistryEntry{
		{ID: id1, Key: "flag_a", Description: "Flag A", Category: "dashboard", UserToggleable: true, DefaultValue: false},
		{ID: id2, Key: "flag_b", Description: "Flag B", Category: "finance", UserToggleable: false, DefaultValue: true},
	}

	t.Run("uses default when no overrides", func(t *testing.T) {
		result := mergeFlags(registry, nil)
		if len(result) != 2 {
			t.Fatalf("expected 2 results, got %d", len(result))
		}
		if result[0].Value != false {
			t.Errorf("flag_a: expected false, got %v", result[0].Value)
		}
		if result[1].Value != true {
			t.Errorf("flag_b: expected true, got %v", result[1].Value)
		}
	})

	t.Run("applies user override", func(t *testing.T) {
		overrides := map[string]bool{id1.Hex(): true}
		result := mergeFlags(registry, overrides)
		if result[0].Value != true {
			t.Errorf("flag_a: expected true after override, got %v", result[0].Value)
		}
		if result[1].Value != true {
			t.Errorf("flag_b: expected default true, got %v", result[1].Value)
		}
	})

	t.Run("ignores unknown override keys", func(t *testing.T) {
		unknownID := primitive.NewObjectID()
		overrides := map[string]bool{unknownID.Hex(): true}
		result := mergeFlags(registry, overrides)
		if result[0].Value != false {
			t.Errorf("flag_a: expected default false, got %v", result[0].Value)
		}
	})

	t.Run("maps metadata correctly", func(t *testing.T) {
		result := mergeFlags(registry, nil)
		if result[0].ID != id1.Hex() {
			t.Errorf("expected ID %s, got %s", id1.Hex(), result[0].ID)
		}
		if result[0].Key != "flag_a" {
			t.Errorf("expected key flag_a, got %s", result[0].Key)
		}
		if result[0].UserToggleable != true {
			t.Errorf("expected user_toggleable true")
		}
	})
}

func TestValidateFlagUpdates(t *testing.T) {
	id1 := primitive.NewObjectID()
	id2 := primitive.NewObjectID()

	registry := []models.FlagRegistryEntry{
		{ID: id1, Key: "flag_a", UserToggleable: true},
		{ID: id2, Key: "flag_b", UserToggleable: false},
	}

	t.Run("accepts valid toggleable flag", func(t *testing.T) {
		body := map[string]bool{id1.Hex(): true}
		result, err := validateFlagUpdates(body, registry)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if result[id1.Hex()] != true {
			t.Errorf("expected true for id1")
		}
	})

	t.Run("rejects invalid ObjectId", func(t *testing.T) {
		body := map[string]bool{"not-an-objectid": true}
		_, err := validateFlagUpdates(body, registry)
		if err == nil {
			t.Error("expected error for invalid ObjectId")
		}
	})

	t.Run("rejects unknown flag id", func(t *testing.T) {
		unknownID := primitive.NewObjectID()
		body := map[string]bool{unknownID.Hex(): true}
		_, err := validateFlagUpdates(body, registry)
		if err == nil {
			t.Error("expected error for unknown flag id")
		}
	})

	t.Run("rejects non-toggleable flag with 403 status", func(t *testing.T) {
		body := map[string]bool{id2.Hex(): true}
		_, err := validateFlagUpdates(body, registry)
		if err == nil {
			t.Fatal("expected error for non-toggleable flag")
		}
		se, ok := err.(errStatus)
		if !ok || se.code != 403 {
			t.Errorf("expected errStatus with code 403, got %v", err)
		}
	})

	t.Run("empty body returns empty map with no error", func(t *testing.T) {
		result, err := validateFlagUpdates(map[string]bool{}, registry)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if len(result) != 0 {
			t.Errorf("expected empty result, got %d items", len(result))
		}
	})
}
```

- [ ] **Step 2: Run tests — verify they fail (functions not yet defined)**

```bash
cd /Users/vipulchaudhary/Personal/Square/backend && go test ./pkg/handlers/ -run "TestMergeFlags|TestValidateFlagUpdates" -v
```

Expected: compile error — `mergeFlags`, `validateFlagUpdates`, `errStatus` undefined.

---

## Task 3: Backend — Implement feature_flags.go

**Files:**
- Create: `backend/pkg/handlers/feature_flags.go`

- [ ] **Step 1: Create the handler file**

Create `backend/pkg/handlers/feature_flags.go`:

```go
package handlers

import (
	"context"
	"fmt"

	"github.com/codewithvipul/expense-tracker/backend/pkg/db"
	"github.com/codewithvipul/expense-tracker/backend/pkg/models"
	"github.com/gofiber/fiber/v2"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// errStatus carries an HTTP status code alongside an error message.
type errStatus struct {
	code int
	msg  string
}

func (e errStatus) Error() string { return e.msg }

// mergeFlags merges registry defaults with per-user overrides.
// userOverrides is keyed by ObjectId hex; nil map is safe.
func mergeFlags(registry []models.FlagRegistryEntry, userOverrides map[string]bool) []models.ResolvedFlag {
	resolved := make([]models.ResolvedFlag, len(registry))
	for i, entry := range registry {
		value := entry.DefaultValue
		if override, ok := userOverrides[entry.ID.Hex()]; ok {
			value = override
		}
		resolved[i] = models.ResolvedFlag{
			ID:             entry.ID.Hex(),
			Key:            entry.Key,
			Description:    entry.Description,
			Category:       entry.Category,
			UserToggleable: entry.UserToggleable,
			Value:          value,
		}
	}
	return resolved
}

// validateFlagUpdates validates body against registry.
// Returns only the accepted key→value pairs.
// Returns errStatus{400,...} for invalid/unknown IDs, errStatus{403,...} for non-toggleable.
func validateFlagUpdates(body map[string]bool, registry []models.FlagRegistryEntry) (map[string]bool, error) {
	byID := make(map[string]models.FlagRegistryEntry, len(registry))
	for _, entry := range registry {
		byID[entry.ID.Hex()] = entry
	}

	validated := make(map[string]bool, len(body))
	for idHex, value := range body {
		if _, err := primitive.ObjectIDFromHex(idHex); err != nil {
			return nil, errStatus{400, fmt.Sprintf("invalid flag id: %s", idHex)}
		}
		entry, ok := byID[idHex]
		if !ok {
			return nil, errStatus{400, fmt.Sprintf("flag not found: %s", idHex)}
		}
		if !entry.UserToggleable {
			return nil, errStatus{403, fmt.Sprintf("flag not user-toggleable: %s", entry.Key)}
		}
		validated[idHex] = value
	}
	return validated, nil
}

// fetchRegistry loads all entries from feature_flag_registry.
func fetchRegistry(ctx context.Context) ([]models.FlagRegistryEntry, error) {
	cursor, err := db.DB.Collection("feature_flag_registry").Find(ctx, bson.M{})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var registry []models.FlagRegistryEntry
	if err := cursor.All(ctx, &registry); err != nil {
		return nil, err
	}
	return registry, nil
}

// GetUserFlags returns resolved feature flags for the authenticated user.
func GetUserFlags(c *fiber.Ctx) error {
	userIDStr := c.Locals("user_id").(string)
	userID, err := primitive.ObjectIDFromHex(userIDStr)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid user id"})
	}

	ctx := context.Background()

	registry, err := fetchRegistry(ctx)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to fetch feature flag registry"})
	}

	var user models.User
	if err := db.DB.Collection("users").FindOne(ctx, bson.M{"_id": userID}).Decode(&user); err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "user not found"})
	}

	return c.JSON(mergeFlags(registry, user.FeatureFlags))
}

// UpdateUserFlags updates user-toggleable flags for the authenticated user.
func UpdateUserFlags(c *fiber.Ctx) error {
	userIDStr := c.Locals("user_id").(string)
	userID, err := primitive.ObjectIDFromHex(userIDStr)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid user id"})
	}

	var body map[string]bool
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid request body"})
	}

	ctx := context.Background()

	registry, err := fetchRegistry(ctx)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to fetch feature flag registry"})
	}

	validated, err := validateFlagUpdates(body, registry)
	if err != nil {
		if se, ok := err.(errStatus); ok {
			return c.Status(se.code).JSON(fiber.Map{"error": se.msg})
		}
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	if len(validated) > 0 {
		updates := bson.M{}
		for id, val := range validated {
			updates["feature_flags."+id] = val
		}
		if _, err := db.DB.Collection("users").UpdateOne(
			ctx,
			bson.M{"_id": userID},
			bson.M{"$set": updates},
		); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "failed to update feature flags"})
		}
	}

	var user models.User
	if err := db.DB.Collection("users").FindOne(ctx, bson.M{"_id": userID}).Decode(&user); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to fetch updated user"})
	}

	return c.JSON(mergeFlags(registry, user.FeatureFlags))
}
```

- [ ] **Step 2: Run tests — verify they pass**

```bash
cd /Users/vipulchaudhary/Personal/Square/backend && go test ./pkg/handlers/ -run "TestMergeFlags|TestValidateFlagUpdates" -v
```

Expected output: all subtests PASS.

- [ ] **Step 3: Verify the whole backend compiles**

```bash
cd /Users/vipulchaudhary/Personal/Square/backend && go build ./...
```

Expected: no output.

- [ ] **Step 4: Commit**

```bash
cd /Users/vipulchaudhary/Personal/Square/backend
git add pkg/handlers/feature_flags.go pkg/handlers/feature_flags_test.go
git commit -m "feat: add feature flags handlers with mergeFlags and validateFlagUpdates"
```

---

## Task 4: Backend — Register routes

**Files:**
- Modify: `backend/cmd/server/main.go`

- [ ] **Step 1: Add the two new routes**

In `backend/cmd/server/main.go`, add these two lines after the `api.Get("/users/search", ...)` line (line 55):

```go
api.Get("/users/me/flags", middleware.Protected(), handlers.GetUserFlags)
api.Patch("/users/me/flags", middleware.Protected(), handlers.UpdateUserFlags)
```

- [ ] **Step 2: Build and verify**

```bash
cd /Users/vipulchaudhary/Personal/Square/backend && go build ./...
```

Expected: no output.

- [ ] **Step 3: Smoke-test with curl (backend must be running)**

Start the backend in one terminal: `cd backend && go run ./cmd/server/main.go`

In another terminal, login first to get a token:
```bash
curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"your@email.com","password":"yourpassword"}' | jq '.token'
```

Then call the flags endpoint (replace TOKEN):
```bash
curl -s http://localhost:8080/api/users/me/flags \
  -H "Authorization: Bearer TOKEN" | jq .
```

Expected: JSON array (may be empty `[]` until the registry is seeded in Task 5).

- [ ] **Step 4: Commit**

```bash
cd /Users/vipulchaudhary/Personal/Square/backend
git add cmd/server/main.go
git commit -m "feat: register GET/PATCH /users/me/flags routes"
```

---

## Task 5: MongoDB seed — feature_flag_registry collection

- [ ] **Step 1: Open mongosh and seed the registry**

Connect to MongoDB:
```bash
mongosh "mongodb://localhost:27017/expense_tracker"
```

Run these commands:
```javascript
db.feature_flag_registry.createIndex({ key: 1 }, { unique: true })

db.feature_flag_registry.insertOne({
  key: "show_expense_trends_chart",
  description: "Show expense trends chart on dashboard",
  category: "dashboard",
  user_toggleable: true,
  default_value: false
})
```

Expected: `{ acknowledged: true, insertedId: ObjectId("...") }`

- [ ] **Step 2: Verify the endpoint returns the seeded flag**

```bash
curl -s http://localhost:8080/api/users/me/flags \
  -H "Authorization: Bearer TOKEN" | jq .
```

Expected:
```json
[
  {
    "id": "<objectid_hex>",
    "key": "show_expense_trends_chart",
    "description": "Show expense trends chart on dashboard",
    "category": "dashboard",
    "user_toggleable": true,
    "value": false
  }
]
```

---

## Task 6: Flutter — FeatureFlag model + test

**Files:**
- Create: `square_app/lib/features/feature_flags/data/feature_flag_model.dart`
- Create: `square_app/test/features/feature_flags/feature_flag_model_test.dart`

- [ ] **Step 1: Write the failing test first**

Create `square_app/test/features/feature_flags/feature_flag_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:square_app/features/feature_flags/data/feature_flag_model.dart';

void main() {
  group('FeatureFlag.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'abc123',
        'key': 'show_expense_trends_chart',
        'description': 'Show expense trends chart on dashboard',
        'category': 'dashboard',
        'user_toggleable': true,
        'value': false,
      };

      final flag = FeatureFlag.fromJson(json);

      expect(flag.id, 'abc123');
      expect(flag.key, 'show_expense_trends_chart');
      expect(flag.description, 'Show expense trends chart on dashboard');
      expect(flag.category, 'dashboard');
      expect(flag.userToggleable, isTrue);
      expect(flag.value, isFalse);
    });

    test('copyWith updates only value field', () {
      const flag = FeatureFlag(
        id: 'abc123',
        key: 'flag_a',
        description: 'desc',
        category: 'cat',
        userToggleable: true,
        value: false,
      );

      final updated = flag.copyWith(value: true);

      expect(updated.value, isTrue);
      expect(updated.id, 'abc123');
      expect(updated.key, 'flag_a');
      expect(updated.userToggleable, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test — verify it fails**

```bash
cd /Users/vipulchaudhary/Personal/Square/square_app && flutter test test/features/feature_flags/feature_flag_model_test.dart
```

Expected: error — `package:square_app/features/feature_flags/data/feature_flag_model.dart` not found.

- [ ] **Step 3: Create the model**

Create `square_app/lib/features/feature_flags/data/feature_flag_model.dart`:

```dart
class FeatureFlag {
  final String id;
  final String key;
  final String description;
  final String category;
  final bool userToggleable;
  final bool value;

  const FeatureFlag({
    required this.id,
    required this.key,
    required this.description,
    required this.category,
    required this.userToggleable,
    required this.value,
  });

  factory FeatureFlag.fromJson(Map<String, dynamic> json) => FeatureFlag(
        id: json['id'] as String,
        key: json['key'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        userToggleable: json['user_toggleable'] as bool,
        value: json['value'] as bool,
      );

  FeatureFlag copyWith({bool? value}) => FeatureFlag(
        id: id,
        key: key,
        description: description,
        category: category,
        userToggleable: userToggleable,
        value: value ?? this.value,
      );
}
```

- [ ] **Step 4: Run test — verify it passes**

```bash
cd /Users/vipulchaudhary/Personal/Square/square_app && flutter test test/features/feature_flags/feature_flag_model_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/vipulchaudhary/Personal/Square
git add square_app/lib/features/feature_flags/data/feature_flag_model.dart \
        square_app/test/features/feature_flags/feature_flag_model_test.dart
git commit -m "feat: add FeatureFlag model with fromJson and copyWith"
```

---

## Task 7: Flutter — FeatureFlagsRepository

**Files:**
- Create: `square_app/lib/features/feature_flags/data/feature_flags_repository.dart`

- [ ] **Step 1: Create the repository**

Create `square_app/lib/features/feature_flags/data/feature_flags_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:square_app/core/constants/api_constants.dart';
import 'feature_flag_model.dart';

class FeatureFlagsRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<List<FeatureFlag>> getFlags(String token) async {
    final response = await _dio.get(
      '/users/me/flags',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List)
        .map((e) => FeatureFlag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FeatureFlag>> updateFlag(String token, String id, bool value) async {
    final response = await _dio.patch(
      '/users/me/flags',
      data: {id: value},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List)
        .map((e) => FeatureFlag.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd /Users/vipulchaudhary/Personal/Square/square_app && flutter analyze lib/features/feature_flags/data/feature_flags_repository.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/vipulchaudhary/Personal/Square
git add square_app/lib/features/feature_flags/data/feature_flags_repository.dart
git commit -m "feat: add FeatureFlagsRepository with getFlags and updateFlag"
```

---

## Task 8: Flutter — FeatureFlagsNotifier + provider

**Files:**
- Create: `square_app/lib/features/feature_flags/presentation/feature_flags_provider.dart`

- [ ] **Step 1: Create the provider file**

Create `square_app/lib/features/feature_flags/presentation/feature_flags_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/feature_flag_model.dart';
import '../data/feature_flags_repository.dart';

final featureFlagsRepositoryProvider =
    Provider((_) => FeatureFlagsRepository());

class FeatureFlagsNotifier extends AsyncNotifier<List<FeatureFlag>> {
  @override
  Future<List<FeatureFlag>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return ref.read(featureFlagsRepositoryProvider).getFlags(token);
  }

  /// Returns the resolved boolean for a flag by key.
  /// Defaults to false when flags are loading or the key is not found.
  bool flagValue(String key) {
    final flags = state.valueOrNull;
    if (flags == null) return false;
    for (final f in flags) {
      if (f.key == key) return f.value;
    }
    return false;
  }

  /// Optimistically toggles a flag, rolling back on API error.
  Future<void> toggle(String id, bool value) async {
    final previous = state;
    state = AsyncData(
      state.value!.map((f) => f.id == id ? f.copyWith(value: value) : f).toList(),
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final updated =
          await ref.read(featureFlagsRepositoryProvider).updateFlag(token, id, value);
      state = AsyncData(updated);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final featureFlagsProvider =
    AsyncNotifierProvider<FeatureFlagsNotifier, List<FeatureFlag>>(
  FeatureFlagsNotifier.new,
);
```

- [ ] **Step 2: Verify it compiles**

```bash
cd /Users/vipulchaudhary/Personal/Square/square_app && flutter analyze lib/features/feature_flags/presentation/feature_flags_provider.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/vipulchaudhary/Personal/Square
git add square_app/lib/features/feature_flags/presentation/feature_flags_provider.dart
git commit -m "feat: add FeatureFlagsNotifier with flagValue and optimistic toggle"
```

---

## Task 9: Flutter — Update dashboard to use live flags

**Files:**
- Modify: `square_app/lib/features/dashboard/presentation/dashboard_provider.dart`
- Modify: `square_app/lib/features/dashboard/presentation/dashboard_screen.dart`

- [ ] **Step 1: Update dashboard_provider.dart**

Replace the entire file `square_app/lib/features/dashboard/presentation/dashboard_provider.dart` with:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../feature_flags/presentation/feature_flags_provider.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_model.dart';

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardData?>(
  DashboardNotifier.new,
);

class DashboardNotifier extends AsyncNotifier<DashboardData?> {
  @override
  Future<DashboardData?> build() async {
    // Wait for flags — rebuilds automatically when flags change.
    final flags = await ref.watch(featureFlagsProvider.future);
    final showTrends =
        flags.any((f) => f.key == 'show_expense_trends_chart' && f.value);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    return ref
        .read(dashboardRepositoryProvider)
        .getDashboardData(token, includeTrends: showTrends);
  }
}
```

- [ ] **Step 2: Update dashboard_screen.dart — replace static flag reference**

In `square_app/lib/features/dashboard/presentation/dashboard_screen.dart`, make two changes:

**a) Remove the feature_flags import (line 8):**

Delete this line:
```dart
import '../../../../core/config/feature_flags.dart';
```

**b) Inside the `build` method of `_DashboardScreenState`, add this line right after `final isDark = ...` (line 33):**

```dart
final showTrends = ref
    .watch(featureFlagsProvider)
    .valueOrNull
    ?.any((f) => f.key == 'show_expense_trends_chart' && f.value) ??
    false;
```

**c) Add the import for feature_flags_provider at the top:**

```dart
import '../../feature_flags/presentation/feature_flags_provider.dart';
```

**d) Replace the static flag check (line 213):**

Change:
```dart
if (FeatureFlags.showExpenseTrendsChart) ...[
```

To:
```dart
if (showTrends) ...[
```

- [ ] **Step 3: Verify compilation**

```bash
cd /Users/vipulchaudhary/Personal/Square/square_app && flutter analyze lib/features/dashboard/
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/vipulchaudhary/Personal/Square
git add square_app/lib/features/dashboard/presentation/dashboard_provider.dart \
        square_app/lib/features/dashboard/presentation/dashboard_screen.dart
git commit -m "feat: dashboard reads show_expense_trends_chart from live feature flags"
```

---

## Task 10: Flutter — FeaturesSettingsScreen

**Files:**
- Create: `square_app/lib/features/feature_flags/presentation/features_settings_screen.dart`

- [ ] **Step 1: Create the screen**

Create `square_app/lib/features/feature_flags/presentation/features_settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:square_app/core/theme/app_colors.dart';
import '../data/feature_flag_model.dart';
import 'feature_flags_provider.dart';

class FeaturesSettingsScreen extends ConsumerWidget {
  const FeaturesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(featureFlagsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Features'),
        backgroundColor: Colors.transparent,
      ),
      body: flagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load features',
            style: TextStyle(
              color: isDark ? AppColors.slate[400] : AppColors.slate[500],
            ),
          ),
        ),
        data: (flags) {
          final userFlags = flags.where((f) => f.userToggleable).toList();

          if (userFlags.isEmpty) {
            return Center(
              child: Text(
                'No configurable features',
                style: TextStyle(
                  color: isDark ? AppColors.slate[400] : AppColors.slate[500],
                ),
              ),
            );
          }

          final byCategory = <String, List<FeatureFlag>>{};
          for (final f in userFlags) {
            byCategory.putIfAbsent(f.category, () => []).add(f);
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: byCategory.entries.expand((entry) {
              return [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                ...entry.value.map(
                  (flag) => SwitchListTile(
                    title: Text(
                      flag.description,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.slate[800],
                      ),
                    ),
                    value: flag.value,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) =>
                        ref.read(featureFlagsProvider.notifier).toggle(flag.id, val),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ];
            }).toList(),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd /Users/vipulchaudhary/Personal/Square/square_app && flutter analyze lib/features/feature_flags/presentation/features_settings_screen.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/vipulchaudhary/Personal/Square
git add square_app/lib/features/feature_flags/presentation/features_settings_screen.dart
git commit -m "feat: add FeaturesSettingsScreen with grouped toggleable flags"
```

---

## Task 11: Flutter — Wire navigation

**Files:**
- Modify: `square_app/lib/core/router.dart`
- Modify: `square_app/lib/features/profile/presentation/profile_screen.dart`

- [ ] **Step 1: Add the /profile/features route to router.dart**

In `square_app/lib/core/router.dart`:

**a) Add import at top:**
```dart
import '../../features/feature_flags/presentation/features_settings_screen.dart';
```

**b) Convert `/profile` from a flat `GoRoute` to one with a sub-route.**

Replace:
```dart
GoRoute(
  path: '/profile',
  builder: (context, state) => const ProfileScreen(),
),
```

With:
```dart
GoRoute(
  path: '/profile',
  builder: (context, state) => const ProfileScreen(),
  routes: [
    GoRoute(
      path: 'features',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FeaturesSettingsScreen(),
    ),
  ],
),
```

- [ ] **Step 2: Add "Features" option to profile_screen.dart**

In `square_app/lib/features/profile/presentation/profile_screen.dart`:

**a) Add import at top:**
```dart
import 'package:lucide_icons/lucide_icons.dart'; // already present
// add:
import '../../../../core/config/feature_flags.dart'; // REMOVE this if present — won't be needed
```

Actually just add GoRouter push — `go_router` is already imported.

**b) Add a new `_buildProfileOption` call inside the `GlassContainer > Column > children` list, after the "Settings" option (after line 101):**

```dart
_buildProfileOption(
  context,
  icon: LucideIcons.toggleLeft,
  title: 'Features',
  onTap: () => context.push('/profile/features'),
),
```

The full `GlassContainer` children list after the change:
```dart
GlassContainer(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [
      _buildProfileOption(
        context,
        icon: LucideIcons.user,
        title: 'Personal Information',
        onTap: () {},
      ),
      _buildProfileOption(
        context,
        icon: LucideIcons.settings,
        title: 'Settings',
        onTap: () {},
      ),
      _buildProfileOption(
        context,
        icon: LucideIcons.toggleLeft,
        title: 'Features',
        onTap: () => context.push('/profile/features'),
      ),
      _buildProfileOption(
        context,
        icon: LucideIcons.bell,
        title: 'Notifications',
        onTap: () {},
      ),
      _buildProfileOption(
        context,
        icon: LucideIcons.shield,
        title: 'Privacy & Security',
        onTap: () {},
      ),
    ],
  ),
),
```

- [ ] **Step 3: Verify compilation**

```bash
cd /Users/vipulchaudhary/Personal/Square/square_app && flutter analyze lib/core/router.dart lib/features/profile/presentation/profile_screen.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/vipulchaudhary/Personal/Square
git add square_app/lib/core/router.dart \
        square_app/lib/features/profile/presentation/profile_screen.dart
git commit -m "feat: add /profile/features route and Features option in profile screen"
```

---

## Task 12: Cleanup and verify

**Files:**
- Delete: `square_app/lib/core/config/feature_flags.dart`

- [ ] **Step 1: Delete the old static feature flags file**

```bash
rm /Users/vipulchaudhary/Personal/Square/square_app/lib/core/config/feature_flags.dart
```

- [ ] **Step 2: Verify no remaining references**

```bash
cd /Users/vipulchaudhary/Personal/Square/square_app && grep -r "feature_flags.dart\|FeatureFlags\." lib/
```

Expected: no output.

- [ ] **Step 3: Full project analysis**

```bash
cd /Users/vipulchaudhary/Personal/Square/square_app && flutter analyze lib/
```

Expected: no errors.

- [ ] **Step 4: Run all Flutter tests**

```bash
cd /Users/vipulchaudhary/Personal/Square/square_app && flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Run all backend tests**

```bash
cd /Users/vipulchaudhary/Personal/Square/backend && go test ./...
```

Expected: all tests pass.

- [ ] **Step 6: Final commit**

```bash
cd /Users/vipulchaudhary/Personal/Square
git add square_app/lib/core/config/
git commit -m "chore: remove static FeatureFlags class, now served from MongoDB per-user"
```

---

## Manual end-to-end test checklist

After all tasks complete, verify the following manually in the running app:

1. **Flag defaults**: Open the app, go to Profile → Features. The "Show expense trends chart on dashboard" toggle is OFF (matches `default_value: false` in the registry).
2. **Toggle on**: Enable the toggle. The PATCH request succeeds, and navigating to Dashboard shows the expense trends chart.
3. **Toggle off**: Disable the toggle. Dashboard no longer shows the chart.
4. **Persistence**: Kill and reopen the app. The flag state persists (stored in MongoDB, fetched fresh on login).
5. **Admin override**: In MongoDB, set `db.users.updateOne({email:"..."}, {$set: {"feature_flags.<objectid_hex>": true}})`. Restart the app — the flag respects the admin-set value.
