package handlers

import (

	"time"

	"github.com/codewithvipul/expense-tracker/backend/pkg/db"
	"github.com/codewithvipul/expense-tracker/backend/pkg/models"
	"github.com/gofiber/fiber/v2"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func CreateBudget(c *fiber.Ctx) error {
	var input struct {
		Category string  `json:"category"`
		Amount   float64 `json:"amount"`
		Month    string  `json:"month"` 
	}

	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	userID := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := db.GetContext()
	defer cancel()

	
	filter := bson.M{
		"user_id":  userObjID,
		"category": input.Category,
		"month":    input.Month,
	}
	count, _ := db.DB.Collection("budgets").CountDocuments(ctx, filter)
	if count > 0 {
		return c.Status(fiber.StatusConflict).JSON(fiber.Map{"error": "Budget for this category and month already exists"})
	}

	budget := models.Budget{
		ID:        primitive.NewObjectID(),
		UserID:    userObjID,
		Category:  input.Category,
		Amount:    input.Amount,
		Month:     input.Month,
		CreatedAt: time.Now(),
	}

	_, err := db.DB.Collection("budgets").InsertOne(ctx, budget)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not create budget"})
	}

	return c.Status(fiber.StatusCreated).JSON(budget)
}

func GetBudgets(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	month := c.Query("month") 

	ctx, cancel := db.GetContext()
	defer cancel()

	filter := bson.M{"user_id": userObjID}
	if month != "" {
		filter["month"] = month
	}

	cursor, err := db.DB.Collection("budgets").Find(ctx, filter)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not fetch budgets"})
	}

	var budgets []models.Budget
	if err = cursor.All(ctx, &budgets); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Error parsing budgets"})
	}

	return c.JSON(budgets)
}

func UpdateBudget(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var input struct {
		Amount float64 `json:"amount"`
	}
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	update := bson.M{"$set": bson.M{"amount": input.Amount}}
	_, err = db.DB.Collection("budgets").UpdateOne(ctx, bson.M{"_id": objID}, update)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not update budget"})
	}

	return c.JSON(fiber.Map{"message": "Budget updated"})
}

func DeleteBudget(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	_, err = db.DB.Collection("budgets").DeleteOne(ctx, bson.M{"_id": objID})
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not delete budget"})
	}

	return c.JSON(fiber.Map{"message": "Budget deleted"})
}
