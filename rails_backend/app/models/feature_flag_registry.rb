class FeatureFlagRegistry < ApplicationRecord
  has_many :user_feature_flags, dependent: :destroy
  validates :key, presence: true, uniqueness: true
end
