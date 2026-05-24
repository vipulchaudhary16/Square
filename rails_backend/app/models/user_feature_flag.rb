class UserFeatureFlag < ApplicationRecord
  belongs_to :user
  belongs_to :feature_flag_registry
  validates :feature_flag_registry_id, uniqueness: { scope: :user_id }
end
