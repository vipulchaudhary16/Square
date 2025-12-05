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
	
	db.Connect()

	userIDStr := "692dc240cb7a14e30e499b9c"
	userID, err := primitive.ObjectIDFromHex(userIDStr)
	if err != nil {
		log.Fatal(err)
	}

	categories := []string{"Food", "Transport", "Entertainment", "Utilities", "Shopping", "Health", "Travel"}
	descriptions := []string{"Lunch", "Dinner", "Uber", "Movie", "Groceries", "Gym", "Flight", "Coffee", "Books", "Gas"}

	var expenses []interface{}

	
	for i := 0; i < 50; i++ {
		
		daysAgo := rand.Intn(730)
		date := time.Now().AddDate(0, 0, -daysAgo)

		amount := 50.0 + rand.Float64()*450.0 

		expense := models.Expense{
			ID:          primitive.NewObjectID(),
			Description: descriptions[rand.Intn(len(descriptions))],
			Amount:      amount,
			Category:    categories[rand.Intn(len(categories))],
			Date:        date,
			PayerID:     userID,
			GroupID:     nil, 
			Participants: []primitive.ObjectID{userID},
			CreatedAt:   time.Now(),
		}
		expenses = append(expenses, expense)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	_, err = db.DB.Collection("expenses").InsertMany(ctx, expenses)
	if err != nil {
		log.Fatal(err)
	}

	
	
	var incomes []interface{}
	incomeSources := []string{"Salary", "Freelance", "Dividends", "Bonus", "Rental Income"}
	incomeCategories := []string{"Primary Job", "Side Hustle", "Investments", "Real Estate"}

	for i := 0; i < 20; i++ {
		daysAgo := rand.Intn(365)
		date := time.Now().AddDate(0, 0, -daysAgo)
		amount := 1000.0 + rand.Float64()*4000.0

		income := models.Income{
			ID:          primitive.NewObjectID(),
			UserID:      userID,
			Source:      incomeSources[rand.Intn(len(incomeSources))],
			Amount:      amount,
			Category:    incomeCategories[rand.Intn(len(incomeCategories))],
			Date:        date,
			Description: "Monthly income",
			CreatedAt:   time.Now(),
		}
		incomes = append(incomes, income)
	}

	if len(incomes) > 0 {
		_, err = db.DB.Collection("incomes").InsertMany(ctx, incomes)
		if err != nil {
			log.Printf("Error seeding incomes: %v", err)
		} else {
			fmt.Println("Successfully inserted 20 dummy incomes!")
		}
	}

	
	var investments []interface{}
	invTypes := []models.InvestmentType{models.InvestmentStock, models.InvestmentCrypto, models.InvestmentMutualFund, models.InvestmentRealEstate, models.InvestmentOther}
	invNames := []string{"Apple Stock", "Bitcoin", "Vanguard ETF", "Rental Property", "Gold"}

	for i := 0; i < 10; i++ {
		daysAgo := rand.Intn(365)
		date := time.Now().AddDate(0, 0, -daysAgo)
		invested := 500.0 + rand.Float64()*9500.0
		current := invested * (0.8 + rand.Float64()*0.4) 

		investment := models.Investment{
			ID:             primitive.NewObjectID(),
			UserID:         userID,
			Name:           invNames[rand.Intn(len(invNames))],
			Type:           invTypes[rand.Intn(len(invTypes))],
			AmountInvested: invested,
			CurrentValue:   current,
			Date:           date,
			Description:    "Long term hold",
			CreatedAt:      time.Now(),
		}
		investments = append(investments, investment)
	}

	if len(investments) > 0 {
		_, err = db.DB.Collection("investments").InsertMany(ctx, investments)
		if err != nil {
			log.Printf("Error seeding investments: %v", err)
		} else {
			fmt.Println("Successfully inserted 10 dummy investments!")
		}
	}

	
	var loans []interface{}
	loanTypes := []models.LoanType{models.LoanLent, models.LoanBorrowed}
	loanStatuses := []models.LoanStatus{models.LoanStatusPending, models.LoanStatusPaid}
	counterparties := []string{"Alice", "Bob", "Charlie", "David", "Eve"}

	for i := 0; i < 10; i++ {
		daysAgo := rand.Intn(180)
		date := time.Now().AddDate(0, 0, -daysAgo)
		amount := 50.0 + rand.Float64()*950.0

		loan := models.Loan{
			ID:               primitive.NewObjectID(),
			UserID:           userID,
			CounterpartyName: counterparties[rand.Intn(len(counterparties))],
			Type:             loanTypes[rand.Intn(len(loanTypes))],
			Amount:           amount,
			Date:             date,
			Status:           loanStatuses[rand.Intn(len(loanStatuses))],
			Description:      "Personal loan",
			CreatedAt:        time.Now(),
		}
		loans = append(loans, loan)
	}

	if len(loans) > 0 {
		_, err = db.DB.Collection("loans").InsertMany(ctx, loans)
		if err != nil {
			log.Printf("Error seeding loans: %v", err)
		} else {
			fmt.Println("Successfully inserted 10 dummy loans!")
		}
	}
}
