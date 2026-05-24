FactoryBot.define do
  factory :loan do
    association :lender, factory: :user
    borrower      { nil }
    contact       { association(:contact, owner: lender) }
    amount        { 5000.00 }
    date          { Time.current }
    due_date      { nil }
    status        { "PENDING" }
    confirmation_status { "pending" }
    interest_mode { "none" }
    description   { "Test loan" }
    category      { nil }
  end
end
