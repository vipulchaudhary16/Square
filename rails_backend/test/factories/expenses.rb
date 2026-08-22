FactoryBot.define do
  factory :expense do
    association :payer, factory: :user
    category { association(:category, user: payer) }
    group { nil }
    description { "Test expense" }
    amount { 100.0 }
    date { Time.current }
    split_type { "EQUAL" }
  end
end
