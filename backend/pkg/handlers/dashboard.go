package handlers

import (



	"github.com/codewithvipul/expense-tracker/backend/pkg/db"
	"github.com/gofiber/fiber/v2"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func GetDashboardData(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	objID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := db.GetContext()
	defer cancel()

	
	incomeFilter := bson.M{"user_id": objID}

	
	investmentFilter := bson.M{"user_id": objID}

	
	
	lentFilter := bson.M{
		"user_id": objID,
		"type":    "LENT",
		"status":  "PENDING",
	}
	
	borrowedFilter := bson.M{
		"user_id": objID,
		"type":    "BORROWED",
		"status":  "PENDING",
	}

	
	getSum := func(collection string, filter bson.M, field string) float64 {
		pipeline := []bson.M{
			{"$match": filter},
			{"$group": bson.M{"_id": nil, "total": bson.M{"$sum": "$" + field}}},
		}
		cursor, err := db.DB.Collection(collection).Aggregate(ctx, pipeline)
		if err != nil {
			return 0
		}
		var result []struct {
			Total float64 `bson:"total"`
		}
		if err = cursor.All(ctx, &result); err != nil || len(result) == 0 {
			return 0
		}
		return result[0].Total
	}

	
	
	
	expenseFilter := bson.M{
		"$or": []bson.M{
			{"payer_id": objID},
			{"participants": objID},
		},
	}
	totalExpenses := getSum("expenses", expenseFilter, "amount")
	totalIncome := getSum("incomes", incomeFilter, "amount")
	totalInvested := getSum("investments", investmentFilter, "current_value")
	lentAmount := getSum("loans", lentFilter, "amount")
	borrowedAmount := getSum("loans", borrowedFilter, "amount")

	
	recentExpensesPipeline := []bson.M{
		{"$match": expenseFilter},
		{"$sort": bson.M{"date": -1}},
		{"$limit": 5},
		{"$lookup": bson.M{
			"from":         "groups",
			"localField":   "group_id",
			"foreignField": "_id",
			"as":           "group_data",
		}},
		{"$addFields": bson.M{
			"group_name": bson.M{"$arrayElemAt": []interface{}{"$group_data.name", 0}},
		}},
		{"$project": bson.M{
			"group_data": 0,
		}},
	}

	var recentExpenses []bson.M
	cursor, err := db.DB.Collection("expenses").Aggregate(ctx, recentExpensesPipeline)
	if err == nil {
		cursor.All(ctx, &recentExpenses)
	}
	if recentExpenses == nil {
		recentExpenses = []bson.M{}
	}

	return c.JSON(fiber.Map{
		"total_expenses":  totalExpenses,
		"total_income":    totalIncome,
		"total_invested":  totalInvested,
		"recent_expenses": recentExpenses,
		"lent_amount":     lentAmount,
		"borrowed_amount": borrowedAmount,
	})
}
