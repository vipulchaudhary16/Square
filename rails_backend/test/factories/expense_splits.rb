FactoryBot.define do
  factory :expense_split do
    association :expense
    association :user
    amount { 50.0 }
  end
end
