import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { Dashboard } from './modules/dashboard/components/Dashboard'
import { Layout } from './modules/common/components/Layout'
import Auth from './modules/auth/pages/Auth'
import ForgotPassword from './modules/auth/pages/ForgotPassword'
import ResetPassword from './modules/auth/pages/ResetPassword'
import Landing from './modules/common/pages/Landing'
import { AddExpensePage } from './modules/expense/pages/AddExpensePage'
import { GroupsPage } from './modules/expense/pages/GroupsPage'
import ReportsPage from './modules/report/pages/ReportsPage'
import { GroupDetailsPage } from './modules/expense/pages/GroupDetailsPage'
import ExpenseDetailsPage from './modules/expense/pages/ExpenseDetailsPage'
import { JoinGroupPage } from './modules/expense/pages/JoinGroupPage'
import IncomePage from './modules/income/pages/IncomePage'
import IncomeDetailsPage from './modules/income/pages/IncomeDetailsPage'
import InvestmentsPage from './modules/investment/pages/InvestmentsPage'
import InvestmentDetailsPage from './modules/investment/pages/InvestmentDetailsPage'
import LoansPage from './modules/loan/pages/LoansPage'
import LoanDetailsPage from './modules/loan/pages/LoanDetailsPage'
import { BudgetPage } from './modules/expense/pages/BudgetPage'
import { TransactionsPage } from './modules/common/pages/TransactionsPage'
import { CreateEntityPage } from './modules/common/pages/CreateEntityPage'
import './index.css'

import { ThemeProvider } from './context/ThemeContext'

function App() {
    const isAuthenticated = !!localStorage.getItem('token');

    return (
        <ThemeProvider>
            <Router>
                <Routes>
                    {}
                    <Route path="/" element={!isAuthenticated ? <Landing /> : <Navigate to="/dashboard" />} />
                    <Route path="/auth" element={!isAuthenticated ? <Auth /> : <Navigate to="/dashboard" />} />
                    <Route path="/auth/forgot-password" element={!isAuthenticated ? <ForgotPassword /> : <Navigate to="/dashboard" />} />
                    <Route path="/auth/reset-password" element={!isAuthenticated ? <ResetPassword /> : <Navigate to="/dashboard" />} />

                    {}
                    <Route element={<Layout />}>
                        <Route path="/dashboard" element={<Dashboard />} />
                        <Route path="/expenses" element={<AddExpensePage />} />
                        <Route path="/expenses/:id" element={<ExpenseDetailsPage />} />
                        <Route path="/income" element={<IncomePage />} />
                        <Route path="/income/:id" element={<IncomeDetailsPage />} />
                        <Route path="/groups" element={<GroupsPage />} />
                        <Route path="/groups/:id" element={<GroupDetailsPage />} />
                        <Route path="/reports" element={<ReportsPage />} />
                        <Route path="/investments" element={<InvestmentsPage />} />
                        <Route path="/investments/:id" element={<InvestmentDetailsPage />} />
                        <Route path="/loans" element={<LoansPage />} />
                        <Route path="/loans/:id" element={<LoanDetailsPage />} />
                        <Route path="/budgets" element={<BudgetPage />} />
                        <Route path="/transactions" element={<TransactionsPage />} />
                        <Route path="/join" element={<JoinGroupPage />} />
                        <Route path="/new/:type" element={<CreateEntityPage />} />
                    </Route>
                </Routes>
            </Router>
        </ThemeProvider>
    )
}

export default App
