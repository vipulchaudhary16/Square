package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Income struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID      primitive.ObjectID `json:"user_id" bson:"user_id"`
	Source      string             `json:"source" bson:"source"`
	Amount      float64            `json:"amount" bson:"amount"`
	Category    string             `json:"category" bson:"category"`
	Date        time.Time          `json:"date" bson:"date"`
	Description string             `json:"description" bson:"description"`
	CreatedAt   time.Time          `json:"created_at" bson:"created_at"`
}

type InvestmentType string

const (
	InvestmentStock      InvestmentType = "STOCK"
	InvestmentCrypto     InvestmentType = "CRYPTO"
	InvestmentMutualFund InvestmentType = "MUTUAL_FUND"
	InvestmentRealEstate InvestmentType = "REAL_ESTATE"
	InvestmentOther      InvestmentType = "OTHER"
)

type Investment struct {
	ID             primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID         primitive.ObjectID `json:"user_id" bson:"user_id"`
	Name           string             `json:"name" bson:"name"`
	Type           InvestmentType     `json:"type" bson:"type"`
	AmountInvested float64            `json:"amount_invested" bson:"amount_invested"`
	CurrentValue   float64            `json:"current_value" bson:"current_value"`
	Date           time.Time          `json:"date" bson:"date"`
	Description    string             `json:"description" bson:"description"`
	CreatedAt      time.Time          `json:"created_at" bson:"created_at"`
}

type LoanType string
type LoanStatus string

const (
	LoanLent     LoanType = "LENT"
	LoanBorrowed LoanType = "BORROWED"

	LoanStatusPending LoanStatus = "PENDING"
	LoanStatusPaid    LoanStatus = "PAID"
)

type Loan struct {
	ID               primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	UserID           primitive.ObjectID `json:"user_id" bson:"user_id"`
	CounterpartyName string             `json:"counterparty_name" bson:"counterparty_name"`
	Type             LoanType           `json:"type" bson:"type"`
	Amount           float64            `json:"amount" bson:"amount"`
	Date             time.Time          `json:"date" bson:"date"`
	DueDate          time.Time          `json:"due_date,omitempty" bson:"due_date,omitempty"`
	Status           LoanStatus         `json:"status" bson:"status"`
	Description      string             `json:"description" bson:"description"`
	CreatedAt        time.Time          `json:"created_at" bson:"created_at"`
}
