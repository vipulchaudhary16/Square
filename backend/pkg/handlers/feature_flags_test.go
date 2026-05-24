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
