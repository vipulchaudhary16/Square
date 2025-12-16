package handlers

import (
	"time"

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

	// Filters
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

	now := time.Now()
	currentYear, currentMonth, _ := now.Date()
	currentLocation := now.Location()

	startOfCurrentMonth := time.Date(currentYear, currentMonth, 1, 0, 0, 0, 0, currentLocation)
	startOfNextMonth := startOfCurrentMonth.AddDate(0, 1, 0)

	startOfLastMonth := startOfCurrentMonth.AddDate(0, -1, 0)

	getDailyExpenses := func(startDate, endDate time.Time) map[int]float64 {
		filter := bson.M{
			"$and": []bson.M{
				expenseFilter,
				{"date": bson.M{"$gte": startDate, "$lt": endDate}},
			},
		}

		pipeline := []bson.M{
			{"$match": filter},
			{"$group": bson.M{
				"_id":   bson.M{"$dayOfMonth": "$date"},
				"total": bson.M{"$sum": "$amount"},
			}},
		}

		cursor, err := db.DB.Collection("expenses").Aggregate(ctx, pipeline)
		if err != nil {
			return map[int]float64{}
		}

		var results []struct {
			Day   int     `bson:"_id"`
			Total float64 `bson:"total"`
		}
		if err = cursor.All(ctx, &results); err != nil {
			return map[int]float64{}
		}

		dailyMap := make(map[int]float64)
		for _, r := range results {
			dailyMap[r.Day] = r.Total
		}
		return dailyMap
	}

	currentMonthExpenses := getDailyExpenses(startOfCurrentMonth, startOfNextMonth)
	lastMonthExpenses := getDailyExpenses(startOfLastMonth, startOfCurrentMonth)

	var graphData []map[string]interface{}
	daysInMonth := 31

	for day := 1; day <= daysInMonth; day++ {
		cmVal := currentMonthExpenses[day]
		lmVal := lastMonthExpenses[day]
		graphData = append(graphData, map[string]interface{}{
			"day":           day,
			"current_month": cmVal,
			"last_month":    lmVal,
		})
	}

	return c.JSON(fiber.Map{
		"total_expenses":  totalExpenses,
		"total_income":    totalIncome,
		"total_invested":  totalInvested,
		"recent_expenses": recentExpenses,
		"lent_amount":     lentAmount,
		"borrowed_amount": borrowedAmount,
		"expense_graph":   graphData,
	})
}
