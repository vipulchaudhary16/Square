package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"time"

	"github.com/codewithvipul/expense-tracker/backend/pkg/db"
	"github.com/codewithvipul/expense-tracker/backend/pkg/models"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

func main() {
	// Connect to DB
	db.Connect()

	// Specific User ID from request
	userIDStr := "6941b64ab02e0d642645ee86"
	userID, err := primitive.ObjectIDFromHex(userIDStr)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Seeding data for User: %s\n", userIDStr)

	categories := []string{"Food", "Transport", "Entertainment", "Utilities", "Shopping", "Health", "Travel"}
	descriptions := []string{"Lunch", "Dinner", "Uber", "Movie", "Groceries", "Gym", "Flight", "Coffee", "Books", "Gas"}

	var expenses []interface{}

	// Target Dates: Nov 2025 and Dec 2025
	// Today is assumed to be 17 Dec 2025 based on prompt.

	// 1. Generate for November 2025 (Last Month)
	// 30 days
	startNov := time.Date(2025, time.November, 1, 0, 0, 0, 0, time.Local)
	for i := 0; i < 40; i++ { // 40 expenses in Nov
		dayOffset := rand.Intn(30) // 0 to 29
		date := startNov.AddDate(0, 0, dayOffset)

		// Random time during the day
		date = date.Add(time.Duration(rand.Intn(24)) * time.Hour)

		amount := 50.0 + rand.Float64()*450.0

		expense := models.Expense{
			ID:           primitive.NewObjectID(),
			Description:  descriptions[rand.Intn(len(descriptions))] + " (Nov)",
			Amount:       amount,
			Category:     categories[rand.Intn(len(categories))],
			Date:         date,
			PayerID:      userID,
			GroupID:      nil,
			Participants: []primitive.ObjectID{userID},
			CreatedAt:    time.Now(),
		}
		expenses = append(expenses, expense)
	}

	// 2. Generate for December 2025 (This Month)
	// Up to 17th
	startDec := time.Date(2025, time.December, 1, 0, 0, 0, 0, time.Local)
	for i := 0; i < 25; i++ { // 25 expenses in Dec so far
		dayOffset := rand.Intn(17) // 0 to 16 (1st to 17th)
		date := startDec.AddDate(0, 0, dayOffset)

		// Random time
		date = date.Add(time.Duration(rand.Intn(24)) * time.Hour)

		amount := 50.0 + rand.Float64()*450.0

		expense := models.Expense{
			ID:           primitive.NewObjectID(),
			Description:  descriptions[rand.Intn(len(descriptions))] + " (Dec)",
			Amount:       amount,
			Category:     categories[rand.Intn(len(categories))],
			Date:         date,
			PayerID:      userID,
			GroupID:      nil,
			Participants: []primitive.ObjectID{userID},
			CreatedAt:    time.Now(),
		}
		expenses = append(expenses, expense)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if len(expenses) > 0 {
		_, err = db.DB.Collection("expenses").InsertMany(ctx, expenses)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Printf("Successfully inserted %d expenses for Nov/Dec 2025!\n", len(expenses))
	}
}
