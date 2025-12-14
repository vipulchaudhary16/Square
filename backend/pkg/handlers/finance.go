package handlers

import (

	"strings"
	"time"

	"github.com/codewithvipul/expense-tracker/backend/pkg/db"
	"github.com/codewithvipul/expense-tracker/backend/pkg/models"
	"github.com/gofiber/fiber/v2"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func GetIncomes(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	objID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := db.GetContext()
	defer cancel()

	filter := bson.M{"user_id": objID}

	page := c.QueryInt("page", 1)
	limit := c.QueryInt("limit", 0)

	total, err := db.DB.Collection("incomes").CountDocuments(ctx, filter)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not count incomes"})
	}

	sortBy := c.Query("sort_by", "date")
	if sortBy == "" {
		sortBy = "date"
	}
	sortOrder := c.Query("sort_order", "desc")
	sortValue := -1
	if sortOrder == "asc" {
		sortValue = 1
	}

	opts := options.Find().SetSort(bson.D{{Key: sortBy, Value: sortValue}})
	if limit > 0 {
		skip := (page - 1) * limit
		opts.SetSkip(int64(skip))
		opts.SetLimit(int64(limit))
	}

	cursor, err := db.DB.Collection("incomes").Find(ctx, filter, opts)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not fetch incomes"})
	}

	var incomes []models.Income
	if err = cursor.All(ctx, &incomes); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Error parsing incomes"})
	}

	if c.Query("page") == "" && c.Query("limit") == "" {
		return c.JSON(incomes)
	}

	return c.JSON(fiber.Map{
		"data":  incomes,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

func CreateIncome(c *fiber.Ctx) error {
	var input struct {
		Source      string  `json:"source"`
		Amount      float64 `json:"amount"`
		Category    string  `json:"category"`
		Date        string  `json:"date"`
		Description string  `json:"description"`
	}

	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	date, err := time.Parse("2006-01-02", input.Date)
	if err != nil {
		// Try parsing as ISO string if simple date fails
		date, err = time.Parse(time.RFC3339, input.Date)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid date format"})
		}
	}

	userID := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	income := models.Income{
		ID:          primitive.NewObjectID(),
		UserID:      userObjID,
		Source:      input.Source,
		Amount:      input.Amount,
		Category:    input.Category,
		Date:        date,
		Description: input.Description,
		CreatedAt:   time.Now(),
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	_, err = db.DB.Collection("incomes").InsertOne(ctx, income)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not create income"})
	}

	return c.Status(fiber.StatusCreated).JSON(income)
}

func UpdateIncome(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var input struct {
		Source      string  `json:"source"`
		Amount      float64 `json:"amount"`
		Category    string  `json:"category"`
		Date        string  `json:"date"`
		Description string  `json:"description"`
	}

	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	date, err := time.Parse("2006-01-02", input.Date)
	if err != nil {
		date, err = time.Parse(time.RFC3339, input.Date)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid date format"})
		}
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	update := bson.M{
		"$set": bson.M{
			"source":      input.Source,
			"amount":      input.Amount,
			"category":    input.Category,
			"date":        date,
			"description": input.Description,
		},
	}

	_, err = db.DB.Collection("incomes").UpdateOne(ctx, bson.M{"_id": objID}, update)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not update income"})
	}

	return c.JSON(fiber.Map{"message": "Income updated"})
}

func DeleteIncome(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	_, err = db.DB.Collection("incomes").DeleteOne(ctx, bson.M{"_id": objID})
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not delete income"})
	}

	db.DB.Collection("activity_logs").DeleteMany(ctx, bson.M{"income_id": objID})
	db.DB.Collection("comments").DeleteMany(ctx, bson.M{"income_id": objID})

	return c.JSON(fiber.Map{"message": "Income deleted"})
}

func GetIncomeDetails(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	var income models.Income
	if err := db.DB.Collection("incomes").FindOne(ctx, bson.M{"_id": objID}).Decode(&income); err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Income not found"})
	}

	var logs []models.ActivityLog
	cursor, err := db.DB.Collection("activity_logs").Find(ctx, bson.M{"income_id": objID})
	if err == nil {
		cursor.All(ctx, &logs)
	}

	var comments []models.Comment
	cursor, err = db.DB.Collection("comments").Find(ctx, bson.M{"income_id": objID})
	if err == nil {
		cursor.All(ctx, &comments)
	}

	userIDs := make(map[string]bool)
	userIDs[income.UserID.Hex()] = true
	for _, log := range logs {
		userIDs[log.UserID.Hex()] = true
	}
	for _, comment := range comments {
		userIDs[comment.UserID.Hex()] = true
	}

	var uniqueIDs []primitive.ObjectID
	for uid := range userIDs {
		oid, _ := primitive.ObjectIDFromHex(uid)
		uniqueIDs = append(uniqueIDs, oid)
	}

	userMap := make(map[string]string)
	if len(uniqueIDs) > 0 {
		cursor, err := db.DB.Collection("users").Find(ctx, bson.M{"_id": bson.M{"$in": uniqueIDs}})
		if err == nil {
			var users []models.User
			cursor.All(ctx, &users)
			for _, u := range users {
				name := u.FirstName + " " + u.LastName
				if name == " " {
					name = u.Username
				}
				userMap[u.ID.Hex()] = name
			}
		}
	}

	return c.JSON(fiber.Map{
		"income":   income,
		"logs":     logs,
		"comments": comments,
		"users":    userMap,
	})
}

func UpdateIncomeWithLog(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var input struct {
		Source      string  `json:"source"`
		Amount      float64 `json:"amount"`
		Category    string  `json:"category"`
		Date        string  `json:"date"`
		Description string  `json:"description"`
	}

	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	date, err := time.Parse("2006-01-02", input.Date)
	if err != nil {
		date, err = time.Parse(time.RFC3339, input.Date)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid date format"})
		}
	}

	userID := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := db.GetContext()
	defer cancel()

	var existing models.Income
	if err := db.DB.Collection("incomes").FindOne(ctx, bson.M{"_id": objID}).Decode(&existing); err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Income not found"})
	}

	var changes []string
	if existing.Source != input.Source {
		changes = append(changes, "Changed source")
	}
	if existing.Amount != input.Amount {
		changes = append(changes, "Changed amount")
	}
	if existing.Category != input.Category {
		changes = append(changes, "Changed category")
	}
	if !existing.Date.Equal(date) {
		changes = append(changes, "Changed date")
	}

	update := bson.M{
		"$set": bson.M{
			"source":      input.Source,
			"amount":      input.Amount,
			"category":    input.Category,
			"date":        date,
			"description": input.Description,
		},
	}

	_, err = db.DB.Collection("incomes").UpdateOne(ctx, bson.M{"_id": objID}, update)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not update income"})
	}

	if len(changes) > 0 {
		log := models.ActivityLog{
			ID:        primitive.NewObjectID(),
			IncomeID:  &objID,
			UserID:    userObjID,
			Action:    "UPDATE",
			Details:   "Updated income: " + strings.Join(changes, ", "),
			CreatedAt: time.Now(),
		}
		db.DB.Collection("activity_logs").InsertOne(ctx, log)
	}

	return c.JSON(fiber.Map{"message": "Income updated"})
}

func AddIncomeComment(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var input struct {
		Text string `json:"text"`
	}
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	userID := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := db.GetContext()
	defer cancel()

	comment := models.Comment{
		ID:        primitive.NewObjectID(),
		IncomeID:  &objID,
		UserID:    userObjID,
		Text:      input.Text,
		CreatedAt: time.Now(),
	}

	if _, err := db.DB.Collection("comments").InsertOne(ctx, comment); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not add comment"})
	}

	log := models.ActivityLog{
		ID:        primitive.NewObjectID(),
		IncomeID:  &objID,
		UserID:    userObjID,
		Action:    "COMMENT",
		Details:   "Added a comment",
		CreatedAt: time.Now(),
	}
	db.DB.Collection("activity_logs").InsertOne(ctx, log)

	return c.Status(fiber.StatusCreated).JSON(comment)
}

func GetInvestments(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	objID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := db.GetContext()
	defer cancel()

	filter := bson.M{"user_id": objID}

	page := c.QueryInt("page", 1)
	limit := c.QueryInt("limit", 0)

	total, err := db.DB.Collection("investments").CountDocuments(ctx, filter)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not count investments"})
	}

	sortBy := c.Query("sort_by", "date")
	if sortBy == "" {
		sortBy = "date"
	}
	sortOrder := c.Query("sort_order", "desc")
	sortValue := -1
	if sortOrder == "asc" {
		sortValue = 1
	}

	opts := options.Find().SetSort(bson.D{{Key: sortBy, Value: sortValue}})
	if limit > 0 {
		skip := (page - 1) * limit
		opts.SetSkip(int64(skip))
		opts.SetLimit(int64(limit))
	}

	cursor, err := db.DB.Collection("investments").Find(ctx, filter, opts)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not fetch investments"})
	}

	var investments []models.Investment
	if err = cursor.All(ctx, &investments); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Error parsing investments"})
	}

	if c.Query("page") == "" && c.Query("limit") == "" {
		return c.JSON(investments)
	}

	return c.JSON(fiber.Map{
		"data":  investments,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

func CreateInvestment(c *fiber.Ctx) error {
	var input struct {
		Name           string                `json:"name"`
		Type           models.InvestmentType `json:"type"`
		AmountInvested float64               `json:"amount_invested"`
		CurrentValue   float64               `json:"current_value"`
		Date           string                `json:"date"`
		Description    string                `json:"description"`
	}

	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	date, err := time.Parse("2006-01-02", input.Date)
	if err != nil {
		date, err = time.Parse(time.RFC3339, input.Date)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid date format"})
		}
	}

	userID := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	investment := models.Investment{
		ID:             primitive.NewObjectID(),
		UserID:         userObjID,
		Name:           input.Name,
		Type:           input.Type,
		AmountInvested: input.AmountInvested,
		CurrentValue:   input.CurrentValue,
		Date:           date,
		Description:    input.Description,
		CreatedAt:      time.Now(),
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	_, err = db.DB.Collection("investments").InsertOne(ctx, investment)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not create investment"})
	}

	return c.Status(fiber.StatusCreated).JSON(investment)
}

func UpdateInvestment(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var input struct {
		Name           string                `json:"name"`
		Type           models.InvestmentType `json:"type"`
		AmountInvested float64               `json:"amount_invested"`
		CurrentValue   float64               `json:"current_value"`
		Date           string                `json:"date"`
		Description    string                `json:"description"`
	}

	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	date, err := time.Parse("2006-01-02", input.Date)
	if err != nil {
		date, err = time.Parse(time.RFC3339, input.Date)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid date format"})
		}
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	update := bson.M{
		"$set": bson.M{
			"name":            input.Name,
			"type":            input.Type,
			"amount_invested": input.AmountInvested,
			"current_value":   input.CurrentValue,
			"date":            date,
			"description":     input.Description,
		},
	}

	_, err = db.DB.Collection("investments").UpdateOne(ctx, bson.M{"_id": objID}, update)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not update investment"})
	}

	return c.JSON(fiber.Map{"message": "Investment updated"})
}

func DeleteInvestment(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	_, err = db.DB.Collection("investments").DeleteOne(ctx, bson.M{"_id": objID})
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not delete investment"})
	}

	db.DB.Collection("activity_logs").DeleteMany(ctx, bson.M{"investment_id": objID})
	db.DB.Collection("comments").DeleteMany(ctx, bson.M{"investment_id": objID})

	return c.JSON(fiber.Map{"message": "Investment deleted"})
}

func GetInvestmentDetails(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	var investment models.Investment
	if err := db.DB.Collection("investments").FindOne(ctx, bson.M{"_id": objID}).Decode(&investment); err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Investment not found"})
	}

	var logs []models.ActivityLog
	cursor, err := db.DB.Collection("activity_logs").Find(ctx, bson.M{"investment_id": objID})
	if err == nil {
		cursor.All(ctx, &logs)
	}

	var comments []models.Comment
	cursor, err = db.DB.Collection("comments").Find(ctx, bson.M{"investment_id": objID})
	if err == nil {
		cursor.All(ctx, &comments)
	}

	userIDs := make(map[string]bool)
	userIDs[investment.UserID.Hex()] = true
	for _, log := range logs {
		userIDs[log.UserID.Hex()] = true
	}
	for _, comment := range comments {
		userIDs[comment.UserID.Hex()] = true
	}

	var uniqueIDs []primitive.ObjectID
	for uid := range userIDs {
		oid, _ := primitive.ObjectIDFromHex(uid)
		uniqueIDs = append(uniqueIDs, oid)
	}

	userMap := make(map[string]string)
	if len(uniqueIDs) > 0 {
		cursor, err := db.DB.Collection("users").Find(ctx, bson.M{"_id": bson.M{"$in": uniqueIDs}})
		if err == nil {
			var users []models.User
			cursor.All(ctx, &users)
			for _, u := range users {
				name := u.FirstName + " " + u.LastName
				if name == " " {
					name = u.Username
				}
				userMap[u.ID.Hex()] = name
			}
		}
	}

	return c.JSON(fiber.Map{
		"investment": investment,
		"logs":       logs,
		"comments":   comments,
		"users":      userMap,
	})
}

func UpdateInvestmentWithLog(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var input struct {
		Name           string                `json:"name"`
		Type           models.InvestmentType `json:"type"`
		AmountInvested float64               `json:"amount_invested"`
		CurrentValue   float64               `json:"current_value"`
		Date           string                `json:"date"`
		Description    string                `json:"description"`
	}

	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	date, err := time.Parse("2006-01-02", input.Date)
	if err != nil {
		date, err = time.Parse(time.RFC3339, input.Date)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid date format"})
		}
	}

	userID := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := db.GetContext()
	defer cancel()

	var existing models.Investment
	if err := db.DB.Collection("investments").FindOne(ctx, bson.M{"_id": objID}).Decode(&existing); err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Investment not found"})
	}

	var changes []string
	if existing.Name != input.Name {
		changes = append(changes, "Changed name")
	}
	if existing.AmountInvested != input.AmountInvested {
		changes = append(changes, "Changed invested amount")
	}
	if existing.CurrentValue != input.CurrentValue {
		changes = append(changes, "Changed current value")
	}

	update := bson.M{
		"$set": bson.M{
			"name":            input.Name,
			"type":            input.Type,
			"amount_invested": input.AmountInvested,
			"current_value":   input.CurrentValue,
			"date":            date,
			"description":     input.Description,
		},
	}

	_, err = db.DB.Collection("investments").UpdateOne(ctx, bson.M{"_id": objID}, update)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not update investment"})
	}

	if len(changes) > 0 {
		log := models.ActivityLog{
			ID:           primitive.NewObjectID(),
			InvestmentID: &objID,
			UserID:       userObjID,
			Action:       "UPDATE",
			Details:      "Updated investment: " + strings.Join(changes, ", "),
			CreatedAt:    time.Now(),
		}
		db.DB.Collection("activity_logs").InsertOne(ctx, log)
	}

	return c.JSON(fiber.Map{"message": "Investment updated"})
}

func AddInvestmentComment(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var input struct {
		Text string `json:"text"`
	}
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	userID := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := db.GetContext()
	defer cancel()

	comment := models.Comment{
		ID:           primitive.NewObjectID(),
		InvestmentID: &objID,
		UserID:       userObjID,
		Text:         input.Text,
		CreatedAt:    time.Now(),
	}

	if _, err := db.DB.Collection("comments").InsertOne(ctx, comment); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not add comment"})
	}

	log := models.ActivityLog{
		ID:           primitive.NewObjectID(),
		InvestmentID: &objID,
		UserID:       userObjID,
		Action:       "COMMENT",
		Details:      "Added a comment",
		CreatedAt:    time.Now(),
	}
	db.DB.Collection("activity_logs").InsertOne(ctx, log)

	return c.Status(fiber.StatusCreated).JSON(comment)
}

func GetLoans(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	objID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := db.GetContext()
	defer cancel()

	filter := bson.M{"user_id": objID}

	page := c.QueryInt("page", 1)
	limit := c.QueryInt("limit", 0)

	total, err := db.DB.Collection("loans").CountDocuments(ctx, filter)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not count loans"})
	}

	sortBy := c.Query("sort_by", "date")
	if sortBy == "" {
		sortBy = "date"
	}
	sortOrder := c.Query("sort_order", "desc")
	sortValue := -1
	if sortOrder == "asc" {
		sortValue = 1
	}

	opts := options.Find().SetSort(bson.D{{Key: sortBy, Value: sortValue}})
	if limit > 0 {
		skip := (page - 1) * limit
		opts.SetSkip(int64(skip))
		opts.SetLimit(int64(limit))
	}

	cursor, err := db.DB.Collection("loans").Find(ctx, filter, opts)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not fetch loans"})
	}

	var loans []models.Loan
	if err = cursor.All(ctx, &loans); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Error parsing loans"})
	}

	if c.Query("page") == "" && c.Query("limit") == "" {
		return c.JSON(loans)
	}

	return c.JSON(fiber.Map{
		"data":  loans,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

func CreateLoan(c *fiber.Ctx) error {
	var input struct {
		CounterpartyName string            `json:"counterparty_name"`
		Type             models.LoanType   `json:"type"`
		Amount           float64           `json:"amount"`
		Date             string            `json:"date"`
		DueDate          string            `json:"due_date"`
		Status           models.LoanStatus `json:"status"`
		Description      string            `json:"description"`
	}

	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	date, err := time.Parse("2006-01-02", input.Date)
	if err != nil {
		date, err = time.Parse(time.RFC3339, input.Date)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid date format"})
		}
	}

	var dueDate time.Time
	if input.DueDate != "" {
		dueDate, err = time.Parse("2006-01-02", input.DueDate)
		if err != nil {
			dueDate, err = time.Parse(time.RFC3339, input.DueDate)
			if err != nil {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid due date format"})
			}
		}
	}

	userID := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	loan := models.Loan{
		ID:               primitive.NewObjectID(),
		UserID:           userObjID,
		CounterpartyName: input.CounterpartyName,
		Type:             input.Type,
		Amount:           input.Amount,
		Date:             date,
		DueDate:          dueDate,
		Status:           models.LoanStatusPending,
		Description:      input.Description,
		CreatedAt:        time.Now(),
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	_, err = db.DB.Collection("loans").InsertOne(ctx, loan)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not create loan"})
	}

	return c.Status(fiber.StatusCreated).JSON(loan)
}

func UpdateLoan(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var input struct {
		CounterpartyName string            `json:"counterparty_name"`
		Type             models.LoanType   `json:"type"`
		Amount           float64           `json:"amount"`
		Date             string            `json:"date"`
		DueDate          string            `json:"due_date"`
		Status           models.LoanStatus `json:"status"`
		Description      string            `json:"description"`
	}

	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	date, err := time.Parse("2006-01-02", input.Date)
	if err != nil {
		date, err = time.Parse(time.RFC3339, input.Date)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid date format"})
		}
	}

	var dueDate time.Time
	if input.DueDate != "" {
		dueDate, err = time.Parse("2006-01-02", input.DueDate)
		if err != nil {
			dueDate, err = time.Parse(time.RFC3339, input.DueDate)
			if err != nil {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid due date format"})
			}
		}
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	update := bson.M{
		"$set": bson.M{
			"counterparty_name": input.CounterpartyName,
			"type":              input.Type,
			"amount":            input.Amount,
			"date":              date,
			"due_date":          dueDate,
			"status":            input.Status,
			"description":       input.Description,
		},
	}

	_, err = db.DB.Collection("loans").UpdateOne(ctx, bson.M{"_id": objID}, update)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not update loan"})
	}

	return c.JSON(fiber.Map{"message": "Loan updated"})
}

func DeleteLoan(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	_, err = db.DB.Collection("loans").DeleteOne(ctx, bson.M{"_id": objID})
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not delete loan"})
	}

	db.DB.Collection("activity_logs").DeleteMany(ctx, bson.M{"loan_id": objID})
	db.DB.Collection("comments").DeleteMany(ctx, bson.M{"loan_id": objID})

	return c.JSON(fiber.Map{"message": "Loan deleted"})
}

func GetLoanDetails(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	ctx, cancel := db.GetContext()
	defer cancel()

	var loan models.Loan
	if err := db.DB.Collection("loans").FindOne(ctx, bson.M{"_id": objID}).Decode(&loan); err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Loan not found"})
	}

	var logs []models.ActivityLog
	cursor, err := db.DB.Collection("activity_logs").Find(ctx, bson.M{"loan_id": objID})
	if err == nil {
		cursor.All(ctx, &logs)
	}

	var comments []models.Comment
	cursor, err = db.DB.Collection("comments").Find(ctx, bson.M{"loan_id": objID})
	if err == nil {
		cursor.All(ctx, &comments)
	}

	userIDs := make(map[string]bool)
	userIDs[loan.UserID.Hex()] = true
	for _, log := range logs {
		userIDs[log.UserID.Hex()] = true
	}
	for _, comment := range comments {
		userIDs[comment.UserID.Hex()] = true
	}

	var uniqueIDs []primitive.ObjectID
	for uid := range userIDs {
		oid, _ := primitive.ObjectIDFromHex(uid)
		uniqueIDs = append(uniqueIDs, oid)
	}

	userMap := make(map[string]string)
	if len(uniqueIDs) > 0 {
		cursor, err := db.DB.Collection("users").Find(ctx, bson.M{"_id": bson.M{"$in": uniqueIDs}})
		if err == nil {
			var users []models.User
			cursor.All(ctx, &users)
			for _, u := range users {
				name := u.FirstName + " " + u.LastName
				if name == " " {
					name = u.Username
				}
				userMap[u.ID.Hex()] = name
			}
		}
	}

	return c.JSON(fiber.Map{
		"loan":     loan,
		"logs":     logs,
		"comments": comments,
		"users":    userMap,
	})
}

func UpdateLoanWithLog(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var input models.Loan
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	userID := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := db.GetContext()
	defer cancel()

	var existing models.Loan
	if err := db.DB.Collection("loans").FindOne(ctx, bson.M{"_id": objID}).Decode(&existing); err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Loan not found"})
	}

	var changes []string
	if existing.CounterpartyName != input.CounterpartyName {
		changes = append(changes, "Changed person name")
	}
	if existing.Amount != input.Amount {
		changes = append(changes, "Changed amount")
	}
	if existing.Status != input.Status {
		changes = append(changes, "Changed status")
	}

	update := bson.M{
		"$set": bson.M{
			"counterparty_name": input.CounterpartyName,
			"type":              input.Type,
			"amount":            input.Amount,
			"date":              input.Date,
			"due_date":          input.DueDate,
			"status":            input.Status,
			"description":       input.Description,
		},
	}

	_, err = db.DB.Collection("loans").UpdateOne(ctx, bson.M{"_id": objID}, update)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not update loan"})
	}

	if len(changes) > 0 {
		log := models.ActivityLog{
			ID:        primitive.NewObjectID(),
			LoanID:    &objID,
			UserID:    userObjID,
			Action:    "UPDATE",
			Details:   "Updated loan: " + strings.Join(changes, ", "),
			CreatedAt: time.Now(),
		}
		db.DB.Collection("activity_logs").InsertOne(ctx, log)
	}

	return c.JSON(fiber.Map{"message": "Loan updated"})
}

func AddLoanComment(c *fiber.Ctx) error {
	id := c.Params("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var input struct {
		Text string `json:"text"`
	}
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	userID := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := db.GetContext()
	defer cancel()

	comment := models.Comment{
		ID:        primitive.NewObjectID(),
		LoanID:    &objID,
		UserID:    userObjID,
		Text:      input.Text,
		CreatedAt: time.Now(),
	}

	if _, err := db.DB.Collection("comments").InsertOne(ctx, comment); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not add comment"})
	}

	log := models.ActivityLog{
		ID:        primitive.NewObjectID(),
		LoanID:    &objID,
		UserID:    userObjID,
		Action:    "COMMENT",
		Details:   "Added a comment",
		CreatedAt: time.Now(),
	}
	db.DB.Collection("activity_logs").InsertOne(ctx, log)

	return c.Status(fiber.StatusCreated).JSON(comment)
}
