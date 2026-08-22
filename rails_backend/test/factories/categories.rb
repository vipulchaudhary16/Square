FactoryBot.define do
  factory :category do
    association :user
    sequence(:name) { |n| "Category #{n}" }
    applies_to { ["expense"] }
    color { "#FF5733" }
    is_standard { false }
  end
end
