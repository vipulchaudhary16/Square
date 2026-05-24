FactoryBot.define do
  factory :contact do
    association :owner, factory: :user
    linked_user { nil }
    name  { Faker::Name.full_name }
    phone { nil }
    email { nil }
  end
end
