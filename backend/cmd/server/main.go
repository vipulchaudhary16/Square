package main

import (
	"log"
	"os"

	"github.com/codewithvipul/expense-tracker/backend/pkg/db"
	"github.com/codewithvipul/expense-tracker/backend/pkg/handlers"
	"github.com/codewithvipul/expense-tracker/backend/pkg/middleware"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	db.Connect()

	app := fiber.New()

	app.Use(cors.New())

	api := app.Group("/api")

	
	api.Post("/auth/signup", handlers.Signup)
	api.Post("/auth/login", handlers.Login)
        api.Post("/auth/forgot-password", handlers.ForgotPassword)
        api.Post("/auth/reset-password", handlers.ResetPassword)
	api.Get("/auth/me", middleware.Protected(), handlers.GetMe)

	
	api.Post("/expenses", middleware.Protected(), handlers.CreateExpense)
	api.Get("/expenses", middleware.Protected(), handlers.GetExpenses)
	api.Get("/expenses/:id", middleware.Protected(), handlers.GetExpenseDetails)
	api.Put("/expenses/:id", middleware.Protected(), handlers.UpdateExpense)
	api.Delete("/expenses/:id", middleware.Protected(), handlers.DeleteExpense)
	api.Post("/expenses/:id/comments", middleware.Protected(), handlers.AddComment)

	
	api.Post("/groups", middleware.Protected(), handlers.CreateGroup)
	api.Get("/groups", middleware.Protected(), handlers.GetUserGroups)
	api.Get("/groups/:id", middleware.Protected(), handlers.GetGroupDetails)
	api.Post("/groups/:id/invite", middleware.Protected(), handlers.InviteUser)
	api.Post("/groups/join", middleware.Protected(), handlers.JoinGroup)
	api.Post("/groups/:id/members", middleware.Protected(), handlers.AddMemberToGroup)
	api.Get("/groups/:id/expenses", middleware.Protected(), handlers.GetGroupExpenses)

	
	api.Get("/users/search", middleware.Protected(), handlers.SearchUsers)

	
	api.Post("/incomes", middleware.Protected(), handlers.CreateIncome)
	api.Get("/incomes", middleware.Protected(), handlers.GetIncomes)
	api.Get("/incomes/:id", middleware.Protected(), handlers.GetIncomeDetails)
	api.Put("/incomes/:id", middleware.Protected(), handlers.UpdateIncomeWithLog)
	api.Delete("/incomes/:id", middleware.Protected(), handlers.DeleteIncome)
	api.Post("/incomes/:id/comments", middleware.Protected(), handlers.AddIncomeComment)

	
	api.Post("/investments", middleware.Protected(), handlers.CreateInvestment)
	api.Get("/investments", middleware.Protected(), handlers.GetInvestments)
	api.Get("/investments/:id", middleware.Protected(), handlers.GetInvestmentDetails)
	api.Put("/investments/:id", middleware.Protected(), handlers.UpdateInvestmentWithLog)
	api.Delete("/investments/:id", middleware.Protected(), handlers.DeleteInvestment)
	api.Post("/investments/:id/comments", middleware.Protected(), handlers.AddInvestmentComment)

	
	api.Post("/loans", middleware.Protected(), handlers.CreateLoan)
	api.Get("/loans", middleware.Protected(), handlers.GetLoans)
	api.Get("/loans/:id", middleware.Protected(), handlers.GetLoanDetails)
	api.Put("/loans/:id", middleware.Protected(), handlers.UpdateLoanWithLog)
	api.Delete("/loans/:id", middleware.Protected(), handlers.DeleteLoan)
	api.Post("/loans/:id/comments", middleware.Protected(), handlers.AddLoanComment)

	
	api.Post("/budgets", middleware.Protected(), handlers.CreateBudget)
	api.Get("/budgets", middleware.Protected(), handlers.GetBudgets)
	api.Put("/budgets/:id", middleware.Protected(), handlers.UpdateBudget)
	api.Delete("/budgets/:id", middleware.Protected(), handlers.DeleteBudget)

	
	api.Get("/dashboard", middleware.Protected(), handlers.GetDashboardData)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Fatal(app.Listen(":" + port))
}
