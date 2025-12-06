package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type User struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Username  string             `json:"username" bson:"username"`
	FirstName string             `json:"first_name" bson:"first_name"`
	LastName  string             `json:"last_name" bson:"last_name"`
	Email     string             `json:"email" bson:"email"`
	Password  string             `json:"-" bson:"password,omitempty"`
	OTP       string             `json:"-" bson:"otp,omitempty"`
	OTPExpiry time.Time          `json:"-" bson:"otp_expiry,omitempty"`
	ResetToken       string    `json:"-" bson:"reset_token,omitempty"`
	ResetTokenExpiry time.Time `json:"-" bson:"reset_token_expiry,omitempty"`
}

type Group struct {
	ID          primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	Name        string               `json:"name" bson:"name"`
	Description string               `json:"description" bson:"description"`
	Members     []primitive.ObjectID `json:"members" bson:"members"`
	CreatedBy   primitive.ObjectID   `json:"created_by" bson:"created_by"`
	CreatedAt   time.Time            `json:"created_at" bson:"created_at"`
}

type GroupInvite struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	GroupID   primitive.ObjectID `json:"group_id" bson:"group_id"`
	Email     string             `json:"email" bson:"email"`
	Token     string             `json:"token" bson:"token"`
	Status    string             `json:"status" bson:"status"` 
	ExpiresAt time.Time          `json:"expires_at" bson:"expires_at"`
}

type SplitType string

const (
	SplitEqual   SplitType = "EQUAL"
	SplitExact   SplitType = "EXACT"
	SplitPercent SplitType = "PERCENT"
)

type Expense struct {
	ID           primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	Description  string               `json:"description" bson:"description"`
	Amount       float64              `json:"amount" bson:"amount"`
	Category     string               `json:"category" bson:"category"`
	Date         time.Time            `json:"date" bson:"date"`
	PayerID      primitive.ObjectID   `json:"payer_id" bson:"payer_id"`
	GroupID      *primitive.ObjectID  `json:"group_id,omitempty" bson:"group_id,omitempty"`
	SplitType    SplitType            `json:"split_type,omitempty" bson:"split_type,omitempty"`
	Participants []primitive.ObjectID `json:"participants,omitempty" bson:"participants,omitempty"`
	Splits       map[string]float64   `json:"splits,omitempty" bson:"splits,omitempty"`
	CreatedAt    time.Time            `json:"created_at" bson:"created_at"`
}

type ActivityLog struct {
	ID           primitive.ObjectID  `json:"id" bson:"_id,omitempty"`
	ExpenseID    *primitive.ObjectID `json:"expense_id,omitempty" bson:"expense_id,omitempty"`
	IncomeID     *primitive.ObjectID `json:"income_id,omitempty" bson:"income_id,omitempty"`
	LoanID       *primitive.ObjectID `json:"loan_id,omitempty" bson:"loan_id,omitempty"`
	InvestmentID *primitive.ObjectID `json:"investment_id,omitempty" bson:"investment_id,omitempty"`
	UserID       primitive.ObjectID  `json:"user_id" bson:"user_id"`
	Action       string              `json:"action" bson:"action"`
	Details      string              `json:"details" bson:"details"`
	CreatedAt    time.Time           `json:"created_at" bson:"created_at"`
}

type Comment struct {
	ID           primitive.ObjectID  `json:"id" bson:"_id,omitempty"`
	ExpenseID    *primitive.ObjectID `json:"expense_id,omitempty" bson:"expense_id,omitempty"`
	IncomeID     *primitive.ObjectID `json:"income_id,omitempty" bson:"income_id,omitempty"`
	LoanID       *primitive.ObjectID `json:"loan_id,omitempty" bson:"loan_id,omitempty"`
	InvestmentID *primitive.ObjectID `json:"investment_id,omitempty" bson:"investment_id,omitempty"`
	UserID       primitive.ObjectID  `json:"user_id" bson:"user_id"`
	Text         string              `json:"text" bson:"text"`
	CreatedAt    time.Time           `json:"created_at" bson:"created_at"`
}

type Budget struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID    primitive.ObjectID `json:"user_id" bson:"user_id"`
	Category  string             `json:"category" bson:"category"`
	Amount    float64            `json:"amount" bson:"amount"`
	Month     string             `json:"month" bson:"month"` 
	CreatedAt time.Time          `json:"created_at" bson:"created_at"`
}
