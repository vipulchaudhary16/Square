package handlers

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/codewithvipul/expense-tracker/backend/pkg/db"
	"github.com/codewithvipul/expense-tracker/backend/pkg/models"
	"github.com/gofiber/fiber/v2"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func CreateExpense(c *fiber.Ctx) error {
	var input struct {
		Description   string             `json:"description"`
		Amount        float64            `json:"amount"`
		Category      string             `json:"category"`
		Date          time.Time          `json:"date"`
		GroupID       string             `json:"group_id"`
		SplitType     string             `json:"split_type"`
		Participants  []string           `json:"participants"`
		Splits        map[string]float64 `json:"splits"`
		AddToPersonal bool               `json:"add_to_personal"`
	}

	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	userID := c.Locals("user_id").(string)
	payerID, _ := primitive.ObjectIDFromHex(userID)

	expense := models.Expense{
		ID:          primitive.NewObjectID(),
		Description: input.Description,
		Amount:      input.Amount,
		Category:    input.Category,
		Date:        input.Date,
		PayerID:     payerID,
		CreatedAt:   time.Now(),
		SplitType:   models.SplitType(input.SplitType),
	}

	if input.GroupID != "" {
		groupID, err := primitive.ObjectIDFromHex(input.GroupID)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid group ID"})
		}
		expense.GroupID = &groupID

		var participants []primitive.ObjectID
		for _, p := range input.Participants {
			pID, err := primitive.ObjectIDFromHex(p)
			if err == nil {
				participants = append(participants, pID)
			}
		}
		expense.Participants = participants
	}

	expense.Splits = make(map[string]float64)

	if len(expense.Participants) > 0 {
		switch expense.SplitType {
		case models.SplitEqual:
			splitAmount := expense.Amount / float64(len(expense.Participants))
			for _, p := range expense.Participants {
				expense.Splits[p.Hex()] = splitAmount
			}
		case models.SplitExact:
			var totalSplit float64
			filteredSplits := make(map[string]float64)
			participantSet := make(map[string]bool)
			for _, p := range expense.Participants {
				participantSet[p.Hex()] = true
			}

			for id, amount := range input.Splits {
				if participantSet[id] {
					totalSplit += amount
					filteredSplits[id] = amount
				}
			}
			if totalSplit != expense.Amount {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Split amounts do not match total expense amount"})
			}
			expense.Splits = filteredSplits

		case models.SplitPercent:
			var totalPercent float64
			filteredSplits := make(map[string]float64)
			participantSet := make(map[string]bool)
			for _, p := range expense.Participants {
				participantSet[p.Hex()] = true
			}

			for id, percent := range input.Splits {
				if participantSet[id] {
					totalPercent += percent
					filteredSplits[id] = (expense.Amount * percent) / 100
				}
			}
			if totalPercent != 100 {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Split percentages must equal 100"})
			}
			expense.Splits = filteredSplits

		default:

			splitAmount := expense.Amount / float64(len(expense.Participants))
			for _, p := range expense.Participants {
				expense.Splits[p.Hex()] = splitAmount
			}
		}
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	_, err := db.DB.Collection("expenses").InsertOne(ctx, expense)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not create expense"})
	}

	if input.AddToPersonal {
		userShare := 0.0
		if share, ok := expense.Splits[userID]; ok {
			userShare = share
		}

		if userShare > 0 {
			personalExpense := models.Expense{
				ID:           primitive.NewObjectID(),
				Description:  fmt.Sprintf("Personal share: %s", input.Description),
				Amount:       userShare,
				Category:     input.Category,
				Date:         input.Date,
				PayerID:      payerID,
				GroupID:      nil,
				Participants: []primitive.ObjectID{payerID},
				CreatedAt:    time.Now(),
			}

			db.DB.Collection("expenses").InsertOne(ctx, personalExpense)
		}
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"message": "Expense created", "expense": expense})
}

func GetExpenses(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	objID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := db.GetContext()
	defer cancel()

	filter := bson.M{
		"$or": []bson.M{
			{"payer_id": objID},
			{"participants": objID},
		},
	}

	if c.Query("personal_only") == "true" {
		filter["group_id"] = nil
	}

	if category := c.Query("category"); category != "" && category != "All" {
		filter["category"] = category
	}

	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")

	if startDateStr != "" || endDateStr != "" {
		dateFilter := bson.M{}
		if startDateStr != "" {
			startDate, err := time.Parse(time.RFC3339, startDateStr)
			if err == nil {
				dateFilter["$gte"] = startDate
			}
		}
		if endDateStr != "" {
			endDate, err := time.Parse(time.RFC3339, endDateStr)
			if err == nil {
				dateFilter["$lte"] = endDate
			}
		}
		if len(dateFilter) > 0 {
			filter["date"] = dateFilter
		}
	}

	page := c.QueryInt("page", 1)
	limit := c.QueryInt("limit", 0)

	sortBy := c.Query("sort_by", "date")
	if sortBy == "" {
		sortBy = "date"
	}
	sortOrder := c.Query("sort_order", "desc")
	sortValue := -1
	if sortOrder == "asc" {
		sortValue = 1
	}

	pipeline := []bson.M{
		{"$match": filter},
		{"$sort": bson.M{sortBy: sortValue}},
		{"$lookup": bson.M{
			"from":         "groups",
			"localField":   "group_id",
			"foreignField": "_id",
			"as":           "group_data",
		}},
		{"$lookup": bson.M{
			"from":         "users",
			"localField":   "payer_id",
			"foreignField": "_id",
			"as":           "payer_data",
		}},
		{"$addFields": bson.M{
			"group_name": bson.M{"$arrayElemAt": []interface{}{"$group_data.name", 0}},
			"payer_name": bson.M{
				"$let": bson.M{
					"vars": bson.M{
						"user": bson.M{"$arrayElemAt": []interface{}{"$payer_data", 0}},
					},
					"in": bson.M{
						"$cond": bson.M{
							"if":   bson.M{"$eq": []interface{}{bson.M{"$trim": bson.M{"input": bson.M{"$concat": []interface{}{"$$user.first_name", " ", "$$user.last_name"}}}}, ""}},
							"then": "$$user.username",
							"else": bson.M{"$trim": bson.M{"input": bson.M{"$concat": []interface{}{"$$user.first_name", " ", "$$user.last_name"}}}},
						},
					},
				},
			},
		}},
		{"$project": bson.M{
			"group_data": 0,
			"payer_data": 0,
		}},
	}

	if limit > 0 {
		skip := (page - 1) * limit
		pipeline = append(pipeline, bson.M{
			"$facet": bson.M{
				"metadata": []bson.M{{"$count": "total"}},
				"data":     []bson.M{{"$skip": skip}, {"$limit": limit}},
			},
		})
	} else {

	}

	cursor, err := db.DB.Collection("expenses").Aggregate(ctx, pipeline)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not fetch expenses"})
	}

	if limit > 0 {
		var result []struct {
			Metadata []struct {
				Total int `bson:"total"`
			} `bson:"metadata"`
			Data []bson.M `bson:"data"`
		}

		if err = cursor.All(ctx, &result); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Error parsing expenses"})
		}

		if len(result) > 0 {
			total := 0
			if len(result[0].Metadata) > 0 {
				total = result[0].Metadata[0].Total
			}
			return c.JSON(fiber.Map{
				"data":  result[0].Data,
				"total": total,
				"page":  page,
				"limit": limit,
			})
		}
		return c.JSON(fiber.Map{
			"data":  []bson.M{},
			"total": 0,
			"page":  page,
			"limit": limit,
		})
	}

	var expenses []bson.M
	if err = cursor.All(ctx, &expenses); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Error parsing expenses"})
	}
	return c.JSON(expenses)
}

func GetGroupExpenses(c *fiber.Ctx) error {
	groupId := c.Params("id")
	groupObjID, err := primitive.ObjectIDFromHex(groupId)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid group ID"})
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	andConditions := []bson.M{
		{"group_id": groupObjID},
	}

	if category := c.Query("category"); category != "" && category != "All" {
		andConditions = append(andConditions, bson.M{"category": category})
	}

	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")

	if startDateStr != "" || endDateStr != "" {
		dateFilter := bson.M{}
		if startDateStr != "" {
			if startDate, err := time.Parse(time.RFC3339, startDateStr); err == nil {
				dateFilter["$gte"] = startDate
			}
		}
		if endDateStr != "" {
			if endDate, err := time.Parse(time.RFC3339, endDateStr); err == nil {
				dateFilter["$lte"] = endDate
			}
		}
		if len(dateFilter) > 0 {
			andConditions = append(andConditions, bson.M{"date": dateFilter})
		}
	}

	searchQuery := c.Query("search")
	if searchQuery != "" {
		var amountSearch float64
		var isAmount bool
		if _, err := fmt.Sscanf(searchQuery, "%f", &amountSearch); err == nil {
			isAmount = true
		}

		searchOr := []bson.M{
			{"description": bson.M{"$regex": primitive.Regex{Pattern: searchQuery, Options: "i"}}},
		}
		if isAmount {
			searchOr = append(searchOr, bson.M{"amount": amountSearch})
		}
		andConditions = append(andConditions, bson.M{"$or": searchOr})
	}

	filter := bson.M{"$and": andConditions}

	pipeline := []bson.M{
		{"$match": filter},
		{"$sort": bson.M{"date": -1}},
		{"$lookup": bson.M{
			"from":         "groups",
			"localField":   "group_id",
			"foreignField": "_id",
			"as":           "group_data",
		}},
		{"$lookup": bson.M{
			"from":         "users",
			"localField":   "payer_id",
			"foreignField": "_id",
			"as":           "payer_data",
		}},
		{"$addFields": bson.M{
			"group_name": bson.M{"$arrayElemAt": []interface{}{"$group_data.name", 0}},
			"payer_name": bson.M{
				"$let": bson.M{
					"vars": bson.M{
						"user": bson.M{"$arrayElemAt": []interface{}{"$payer_data", 0}},
					},
					"in": bson.M{
						"$cond": bson.M{
							"if":   bson.M{"$eq": []interface{}{bson.M{"$trim": bson.M{"input": bson.M{"$concat": []interface{}{"$$user.first_name", " ", "$$user.last_name"}}}}, ""}},
							"then": "$$user.username",
							"else": bson.M{"$trim": bson.M{"input": bson.M{"$concat": []interface{}{"$$user.first_name", " ", "$$user.last_name"}}}},
						},
					},
				},
			},
		}},
		{"$project": bson.M{
			"group_data": 0,
			"payer_data": 0,
		}},
	}

	cursor, err := db.DB.Collection("expenses").Aggregate(ctx, pipeline)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not fetch expenses"})
	}

	var expenses []bson.M
	if err = cursor.All(ctx, &expenses); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Error parsing expenses"})
	}

	return c.JSON(expenses)
}

func GetExpenseDetails(c *fiber.Ctx) error {
	expenseId := c.Params("id")
	expenseObjID, err := primitive.ObjectIDFromHex(expenseId)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid expense ID"})
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	var expense models.Expense
	err = db.DB.Collection("expenses").FindOne(ctx, bson.M{"_id": expenseObjID}).Decode(&expense)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Expense not found"})
	}

	var logs []models.ActivityLog
	cursor, err := db.DB.Collection("activity_logs").Find(ctx, bson.M{"expense_id": expenseObjID})
	if err == nil {
		cursor.All(ctx, &logs)
	}

	var comments []models.Comment
	cursor, err = db.DB.Collection("comments").Find(ctx, bson.M{"expense_id": expenseObjID})
	if err == nil {
		cursor.All(ctx, &comments)
	}

	userIDs := make(map[string]bool)
	userIDs[expense.PayerID.Hex()] = true
	for _, log := range logs {
		userIDs[log.UserID.Hex()] = true
	}
	for _, comment := range comments {
		userIDs[comment.UserID.Hex()] = true
	}
	for userID := range expense.Splits {
		userIDs[userID] = true
	}

	var uniqueIDs []primitive.ObjectID
	for id := range userIDs {
		objID, err := primitive.ObjectIDFromHex(id)
		if err == nil {
			uniqueIDs = append(uniqueIDs, objID)
		}
	}

	var users []models.User
	userMap := make(map[string]string)
	if len(uniqueIDs) > 0 {
		cursor, err := db.DB.Collection("users").Find(ctx, bson.M{"_id": bson.M{"$in": uniqueIDs}})
		if err == nil {
			cursor.All(ctx, &users)
			for _, user := range users {
				name := user.FirstName + " " + user.LastName
				if name == " " {
					name = user.Username
				}
				userMap[user.ID.Hex()] = name
			}
		}
	}

	return c.JSON(fiber.Map{
		"expense":  expense,
		"logs":     logs,
		"comments": comments,
		"users":    userMap,
	})
}

type ExpenseUpdateInput struct {
	Description  string             `json:"description"`
	Amount       float64            `json:"amount"`
	Category     string             `json:"category"`
	Date         time.Time          `json:"date"`
	SplitType    string             `json:"split_type"`
	Participants []string           `json:"participants"`
	Splits       map[string]float64 `json:"splits"`
}

func UpdateExpenseWithLog(ctx context.Context, expenseID primitive.ObjectID, input ExpenseUpdateInput, userID primitive.ObjectID) error {

	var existingExpense models.Expense
	err := db.DB.Collection("expenses").FindOne(ctx, bson.M{"_id": expenseID}).Decode(&existingExpense)
	if err != nil {
		return err
	}

	userIDsToFetch := make(map[string]bool)

	var changes []string
	if existingExpense.Description != input.Description {
		changes = append(changes, fmt.Sprintf("Changed description from '%s' to '%s'", existingExpense.Description, input.Description))
	}
	if existingExpense.Amount != input.Amount {
		changes = append(changes, fmt.Sprintf("Changed amount from %.2f to %.2f", existingExpense.Amount, input.Amount))
	}
	if existingExpense.Category != input.Category {
		changes = append(changes, fmt.Sprintf("Changed category from '%s' to '%s'", existingExpense.Category, input.Category))
	}
	if !existingExpense.Date.Equal(input.Date) {
		changes = append(changes, fmt.Sprintf("Changed date from %s to %s", existingExpense.Date.Format("2006-01-02"), input.Date.Format("2006-01-02")))
	}
	if string(existingExpense.SplitType) != input.SplitType {
		changes = append(changes, fmt.Sprintf("Changed split type from %s to %s", existingExpense.SplitType, input.SplitType))
	}

	existingParticipants := make(map[string]bool)
	for _, p := range existingExpense.Participants {
		existingParticipants[p.Hex()] = true
	}
	newParticipants := make(map[string]bool)
	for _, p := range input.Participants {
		newParticipants[p] = true
	}

	var addedParticipants []string
	for p := range newParticipants {
		if !existingParticipants[p] {
			addedParticipants = append(addedParticipants, p)
			userIDsToFetch[p] = true
		}
	}
	var removedParticipants []string
	for p := range existingParticipants {
		if !newParticipants[p] {
			removedParticipants = append(removedParticipants, p)
			userIDsToFetch[p] = true
		}
	}

	var splitChanges []string

	for uid, amount := range input.Splits {
		oldAmount, exists := existingExpense.Splits[uid]
		if !exists {

			if input.SplitType == string(models.SplitExact) || input.SplitType == string(models.SplitPercent) {
				splitChanges = append(splitChanges, uid)
				userIDsToFetch[uid] = true
			}
		} else if oldAmount != amount {
			splitChanges = append(splitChanges, uid)
			userIDsToFetch[uid] = true
		}
	}

	userNames := make(map[string]string)
	if len(userIDsToFetch) > 0 {
		var ids []primitive.ObjectID
		for id := range userIDsToFetch {
			oid, err := primitive.ObjectIDFromHex(id)
			if err == nil {
				ids = append(ids, oid)
			}
		}
		if len(ids) > 0 {
			cursor, err := db.DB.Collection("users").Find(ctx, bson.M{"_id": bson.M{"$in": ids}})
			if err == nil {
				var users []models.User
				if err = cursor.All(ctx, &users); err == nil {
					for _, u := range users {
						name := u.FirstName + " " + u.LastName
						if strings.TrimSpace(name) == "" {
							name = u.Username
						}
						userNames[u.ID.Hex()] = name
					}
				}
			}
		}
	}

	if len(addedParticipants) > 0 {
		var names []string
		for _, id := range addedParticipants {
			name := userNames[id]
			if name == "" {
				name = "User"
			}
			names = append(names, name)
		}
		changes = append(changes, fmt.Sprintf("Added participants: %s", strings.Join(names, ", ")))
	}
	if len(removedParticipants) > 0 {
		var names []string
		for _, id := range removedParticipants {
			name := userNames[id]
			if name == "" {
				name = "User"
			}
			names = append(names, name)
		}
		changes = append(changes, fmt.Sprintf("Removed participants: %s", strings.Join(names, ", ")))
	}

	for _, uid := range splitChanges {
		name := userNames[uid]
		if name == "" {
			name = "User"
		}
		oldAmount := existingExpense.Splits[uid]
		newAmount := input.Splits[uid]
		changes = append(changes, fmt.Sprintf("Changed split for %s from %.2f to %.2f", name, oldAmount, newAmount))
	}

	details := "Updated expense details"
	if len(changes) > 0 {
		details = strings.Join(changes, ", ")
	}

	finalSplits := make(map[string]float64)
	if len(input.Participants) > 0 {
		switch models.SplitType(input.SplitType) {
		case models.SplitEqual:
			splitAmount := input.Amount / float64(len(input.Participants))
			for _, p := range input.Participants {
				finalSplits[p] = splitAmount
			}
		case models.SplitExact:
			var totalSplit float64
			participantSet := make(map[string]bool)
			for _, p := range input.Participants {
				participantSet[p] = true
			}

			for p, amount := range input.Splits {
				if participantSet[p] {
					totalSplit += amount
					finalSplits[p] = amount
				}
			}
			if totalSplit < input.Amount-0.01 || totalSplit > input.Amount+0.01 {
				return fmt.Errorf("split mismatch: Split amounts (%.2f) do not match total (%.2f)", totalSplit, input.Amount)
			}
		case models.SplitPercent:
			var totalPercent float64
			participantSet := make(map[string]bool)
			for _, p := range input.Participants {
				participantSet[p] = true
			}

			for userID, percent := range input.Splits {
				if participantSet[userID] {
					totalPercent += percent
					finalSplits[userID] = (input.Amount * percent) / 100
				}
			}
			if totalPercent < 99.9 || totalPercent > 100.1 {
				return fmt.Errorf("split mismatch: Split percentages (%.2f) must equal 100", totalPercent)
			}
		default:
			splitAmount := input.Amount / float64(len(input.Participants))
			for _, p := range input.Participants {
				finalSplits[p] = splitAmount
			}
		}
	}

	update := bson.M{
		"description": input.Description,
		"amount":      input.Amount,
		"category":    input.Category,
		"date":        input.Date,
		"split_type":  input.SplitType,
		"splits":      finalSplits,
	}

	var participants []primitive.ObjectID
	for _, p := range input.Participants {
		pID, err := primitive.ObjectIDFromHex(p)
		if err == nil {
			participants = append(participants, pID)
		}
	}
	update["participants"] = participants

	_, err = db.DB.Collection("expenses").UpdateOne(ctx, bson.M{"_id": expenseID}, bson.M{"$set": update})
	if err != nil {
		return err
	}

	log := models.ActivityLog{
		ID:        primitive.NewObjectID(),
		ExpenseID: &expenseID,
		UserID:    userID,
		Action:    "UPDATE",
		Details:   details,
		CreatedAt: time.Now(),
	}
	_, err = db.DB.Collection("activity_logs").InsertOne(ctx, log)
	return err
}

func UpdateExpense(c *fiber.Ctx) error {
	expenseId := c.Params("id")
	expenseObjID, err := primitive.ObjectIDFromHex(expenseId)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid expense ID"})
	}

	var input ExpenseUpdateInput
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	userID := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := db.GetContext()
	defer cancel()

	if err := UpdateExpenseWithLog(ctx, expenseObjID, input, userObjID); err != nil {
		if strings.Contains(err.Error(), "split mismatch") {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not update expense"})
	}

	return c.JSON(fiber.Map{"message": "Expense updated"})
}

func DeleteExpense(c *fiber.Ctx) error {
	expenseId := c.Params("id")
	expenseObjID, err := primitive.ObjectIDFromHex(expenseId)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid expense ID"})
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	_, err = db.DB.Collection("expenses").DeleteOne(ctx, bson.M{"_id": expenseObjID})
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not delete expense"})
	}

	db.DB.Collection("activity_logs").DeleteMany(ctx, bson.M{"expense_id": expenseObjID})
	db.DB.Collection("comments").DeleteMany(ctx, bson.M{"expense_id": expenseObjID})

	return c.JSON(fiber.Map{"message": "Expense deleted"})
}

func AddComment(c *fiber.Ctx) error {
	expenseId := c.Params("id")
	expenseObjID, err := primitive.ObjectIDFromHex(expenseId)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid expense ID"})
	}

	var input struct {
		Text string `json:"text"`
	}
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	userID := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	comment := models.Comment{
		ID:        primitive.NewObjectID(),
		ExpenseID: &expenseObjID,
		UserID:    userObjID,
		Text:      input.Text,
		CreatedAt: time.Now(),
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	_, err = db.DB.Collection("comments").InsertOne(ctx, comment)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not add comment"})
	}

	log := models.ActivityLog{
		ID:        primitive.NewObjectID(),
		ExpenseID: &expenseObjID,
		UserID:    userObjID,
		Action:    "COMMENT",
		Details:   "Added a comment",
		CreatedAt: time.Now(),
	}
	db.DB.Collection("activity_logs").InsertOne(ctx, log)

	return c.Status(fiber.StatusCreated).JSON(comment)
}
