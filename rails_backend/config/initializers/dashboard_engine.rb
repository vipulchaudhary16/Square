Rails.application.config.after_initialize do
  Dashboard.expense_model    = Expense
  Dashboard.income_model     = Income
  Dashboard.investment_model = Investment
  Dashboard.loan_model       = Loan
end
