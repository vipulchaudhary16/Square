FactoryBot.define do
  factory :expense_participant do
    association :expense
    association :user
  end
end
