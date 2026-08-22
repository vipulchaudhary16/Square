FactoryBot.define do
  factory :group do
    association :created_by, factory: :user
    name { "Test Group" }
    description { "" }

    transient do
      members { [] }
    end

    after(:create) do |group, evaluator|
      GroupMembership.find_or_create_by!(group: group, user: group.created_by)
      evaluator.members.each { |u| GroupMembership.find_or_create_by!(group: group, user: u) }
    end
  end
end
