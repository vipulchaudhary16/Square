package handlers

import (



	"github.com/codewithvipul/expense-tracker/backend/pkg/db"
	"github.com/codewithvipul/expense-tracker/backend/pkg/models"
	"github.com/gofiber/fiber/v2"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func SearchUsers(c *fiber.Ctx) error {
	query := c.Query("q")
	if query == "" {
		return c.JSON([]models.User{})
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	
	filter := bson.M{
		"$or": []bson.M{
			{"email": bson.M{"$regex": query, "$options": "i"}},
			{"username": bson.M{"$regex": query, "$options": "i"}},
		},
	}

	
	opts := options.Find().SetLimit(10)

	cursor, err := db.DB.Collection("users").Find(ctx, filter, opts)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Search failed"})
	}

	var users []models.User
	if err = cursor.All(ctx, &users); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Error parsing users"})
	}

	
	if users == nil {
		users = []models.User{}
	}

	return c.JSON(users)
}
