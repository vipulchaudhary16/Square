require "dashboard/engine"

module Dashboard
  mattr_accessor :expense_model,    default: nil
  mattr_accessor :income_model,     default: nil
  mattr_accessor :investment_model, default: nil
  mattr_accessor :loan_model,       default: nil
end
