package handlers

import (
	"context"
	"crypto/rand"
	"fmt"
	"math/big"
	"net/smtp"
	"os"
	"time"

	"github.com/codewithvipul/expense-tracker/backend/pkg/db"
	"github.com/codewithvipul/expense-tracker/backend/pkg/models"
	"github.com/gofiber/fiber/v2"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func CreateGroup(c *fiber.Ctx) error {
	userId := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userId)

	var input models.Group
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	input.ID = primitive.NewObjectID()
	input.CreatedBy = userObjID
	input.CreatedAt = time.Now()
	input.Members = []primitive.ObjectID{userObjID}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := db.DB.Collection("groups").InsertOne(ctx, input)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not create group"})
	}

	return c.Status(fiber.StatusCreated).JSON(input)
}

func GetUserGroups(c *fiber.Ctx) error {
	userId := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userId)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	cursor, err := db.DB.Collection("groups").Find(ctx, bson.M{"members": userObjID})
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not fetch groups"})
	}

	var groups []models.Group
	if err = cursor.All(ctx, &groups); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Error parsing groups"})
	}

	return c.JSON(groups)
}

func GetGroupDetails(c *fiber.Ctx) error {
	groupId := c.Params("id")
	groupObjID, err := primitive.ObjectIDFromHex(groupId)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid group ID"})
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var group models.Group
	err = db.DB.Collection("groups").FindOne(ctx, bson.M{"_id": groupObjID}).Decode(&group)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Group not found"})
	}

	
	var members []models.User
	cursor, err := db.DB.Collection("users").Find(ctx, bson.M{"_id": bson.M{"$in": group.Members}})
	if err == nil {
		cursor.All(ctx, &members)
	}

	
	var expenses []models.Expense
	expCursor, err := db.DB.Collection("expenses").Find(ctx, bson.M{"group_id": groupObjID})
	if err == nil {
		expCursor.All(ctx, &expenses)
	}

	
	netBalances := make(map[primitive.ObjectID]float64)

	for _, expense := range expenses {
		payerID := expense.PayerID
		amount := expense.Amount

		
		netBalances[payerID] += amount

		
		if expense.SplitType == models.SplitEqual || expense.SplitType == "" {
			
			count := len(expense.Participants)
			if count > 0 {
				share := amount / float64(count)
				for _, participantID := range expense.Participants {
					netBalances[participantID] -= share
				}
			}
		} else {
			
			for userIDStr, splitVal := range expense.Splits {
				uid, _ := primitive.ObjectIDFromHex(userIDStr)
				share := splitVal
				if expense.SplitType == models.SplitPercent {
					share = (splitVal / 100.0) * amount
				}
				netBalances[uid] -= share
			}
		}
	}

	type Debt struct {
		From   primitive.ObjectID `json:"from"`
		To     primitive.ObjectID `json:"to"`
		Amount float64            `json:"amount"`
	}
	var debts []Debt

	var debtors []primitive.ObjectID
	var creditors []primitive.ObjectID

	
	for userID, balance := range netBalances {
		
		balance = float64(int(balance*100)) / 100.0
		netBalances[userID] = balance

		if balance < -0.01 {
			debtors = append(debtors, userID)
		} else if balance > 0.01 {
			creditors = append(creditors, userID)
		}
	}

	
	i, j := 0, 0
	for i < len(debtors) && j < len(creditors) {
		debtor := debtors[i]
		creditor := creditors[j]

		debtorBal := -netBalances[debtor] 
		creditorBal := netBalances[creditor]

		amount := debtorBal
		if creditorBal < amount {
			amount = creditorBal
		}
		
		
		amount = float64(int(amount*100)) / 100.0

		if amount > 0 {
			debts = append(debts, Debt{From: debtor, To: creditor, Amount: amount})
		}

		netBalances[debtor] += amount
		netBalances[creditor] -= amount

		
		if -netBalances[debtor] < 0.01 {
			i++
		}
		if netBalances[creditor] < 0.01 {
			j++
		}
	}

	return c.JSON(fiber.Map{
		"group":   group,
		"members": members,
		"debts":   debts,
	})
}

func InviteUser(c *fiber.Ctx) error {
	groupId := c.Params("id")
	groupObjID, err := primitive.ObjectIDFromHex(groupId)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid group ID"})
	}

	var input struct {
		Email string `json:"email"`
	}
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	
	token, _ := generateOTP() 
	
	invite := models.GroupInvite{
		ID:        primitive.NewObjectID(),
		GroupID:   groupObjID,
		Email:     input.Email,
		Token:     token,
		Status:    "PENDING",
		ExpiresAt: time.Now().Add(48 * time.Hour),
	}

	_, err = db.DB.Collection("group_invites").InsertOne(ctx, invite)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not create invite"})
	}

	
	link := fmt.Sprintf("http://localhost:5173/join?token=%s", token)
	body := fmt.Sprintf("You have been invited to join a group. Click here to join: %s", link)
	
	
	
	
	
	
	
	
	if err := sendGroupEmail(input.Email, "Group Invitation", body); err != nil {
		fmt.Println("Failed to send email:", err)
	}

	return c.JSON(fiber.Map{"message": "Invitation sent"})
}

func JoinGroup(c *fiber.Ctx) error {
	userId := c.Locals("user_id").(string)
	userObjID, _ := primitive.ObjectIDFromHex(userId)

	var input struct {
		Token string `json:"token"`
	}
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var invite models.GroupInvite
	err := db.DB.Collection("group_invites").FindOne(ctx, bson.M{"token": input.Token, "status": "PENDING"}).Decode(&invite)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid or expired invite"})
	}

	if time.Now().After(invite.ExpiresAt) {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invite expired"})
	}

	
	_, err = db.DB.Collection("groups").UpdateOne(ctx, bson.M{"_id": invite.GroupID}, bson.M{"$addToSet": bson.M{"members": userObjID}})
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not join group"})
	}

	
	db.DB.Collection("group_invites").UpdateOne(ctx, bson.M{"_id": invite.ID}, bson.M{"$set": bson.M{"status": "ACCEPTED"}})

	return c.JSON(fiber.Map{"message": "Joined group successfully", "group_id": invite.GroupID})
}

func sendGroupEmail(to, subject, body string) error {
	from := os.Getenv("SMTP_EMAIL")
	password := os.Getenv("SMTP_PASSWORD")
	host := "smtp.gmail.com"
	port := "587"

	auth := smtp.PlainAuth("", from, password, host)

	msg := []byte(fmt.Sprintf("To: %s\r\nSubject: %s\r\n\r\n%s", to, subject, body))

	return smtp.SendMail(host+":"+port, auth, from, []string{to}, msg)
}

func AddMemberToGroup(c *fiber.Ctx) error {
	groupId := c.Params("id")
	groupObjID, err := primitive.ObjectIDFromHex(groupId)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid group ID"})
	}

	var input struct {
		UserID string `json:"user_id"`
	}
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	userObjID, err := primitive.ObjectIDFromHex(input.UserID)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"})
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	
	var user models.User
	err = db.DB.Collection("users").FindOne(ctx, bson.M{"_id": userObjID}).Decode(&user)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
	}

	
	_, err = db.DB.Collection("groups").UpdateOne(ctx, bson.M{"_id": groupObjID}, bson.M{"$addToSet": bson.M{"members": userObjID}})
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not add member"})
	}

	return c.JSON(fiber.Map{"message": "Member added successfully", "user": user})
}

func generateOTP() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n), nil
}
