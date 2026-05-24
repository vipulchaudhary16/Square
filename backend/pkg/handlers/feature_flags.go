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
