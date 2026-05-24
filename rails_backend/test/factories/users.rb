FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    password   { "password123" }
    mobile_number { nil }
  end
end
