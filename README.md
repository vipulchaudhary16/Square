# Square

**Square** is a modern, AI-powered expense tracker and bill splitter designed to help you manage your personal finances and share costs with friends effortlessly.

Built with a robust **Go** backend and a dynamic **React** frontend, Square combines performance with a premium user experience.

## 🚀 Features

-   **🤖 AI-Powered Insights**: Automatically categorize expenses and get personalized financial advice powered by Google Gemini.
-   **💰 Expense Tracking**: Easily log income, expenses, and investments. Keep your budget in check.
-   **⚖️ Smart Bill Splitting**: Create groups, split bills evenly or unequally, and track who owes what. settle debts with ease.
-   **📊 Visual Reports**: Interactive charts and graphs to visualize your spending habits and financial health.
-   **🎨 Modern UI/UX**: A sleek, responsive interface with Dark/Light mode support, built with Tailwind CSS and Framer Motion.
-   **🔒 Secure Authentication**: Robust user authentication to keep your financial data safe.

## 🛠️ Tech Stack

### Backend
-   **Language**: Go (Golang)
-   **Framework**: Fiber (v2)
-   **Database**: MongoDB
-   **Authentication**: JWT

### Frontend
-   **Framework**: React (v18)
-   **Build Tool**: Vite
-   **Language**: TypeScript
-   **Styling**: Tailwind CSS
-   **State Management**: React Query
-   **Charts**: Recharts
-   **Animations**: Framer Motion
-   **AI Integration**: Google Generative AI SDK

## 🏁 Getting Started

### Prerequisites
-   [Go](https://go.dev/dl/) (v1.21+)
-   [Node.js](https://nodejs.org/) (v18+)
-   [MongoDB](https://www.mongodb.com/try/download/community) (running locally or a cloud instance)

### Installation

1.  **Clone the repository**
    ```bash
    git clone git@github.com:vipulchaudhary16/Square.git
    cd Square
    ```

2.  **Backend Setup**
    ```bash
    cd backend
    # Create .env file
    cp .env.example .env # (Or create one manually)
    # Install dependencies
    go mod download
    # Run the server
    go run cmd/server/main.go
    ```
    *Note: Ensure your `.env` contains `MONGO_URI` and `PORT`.*

3.  **Frontend Setup**
    ```bash
    cd frontend
    # Install dependencies
    npm install
    # Create .env file and add your VITE_GEMINI_API_KEY
    echo "VITE_GEMINI_API_KEY=your_api_key_here" > .env
    # Run the development server
    npm run dev
    ```

## Task

1. Show/Hide password feature for login and register page
2. 

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.
