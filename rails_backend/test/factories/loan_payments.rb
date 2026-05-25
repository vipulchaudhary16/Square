FactoryBot.define do
  factory :loan_payment do
    association :loan
    amount  { 1000.00 }
    paid_at { Time.current }
    note    { nil }
  end
end
