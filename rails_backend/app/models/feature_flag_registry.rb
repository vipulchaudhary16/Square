class FeatureFlagRegistry < ApplicationRecord
  class NotFoundError < StandardError; end
  class NotToggleableError < StandardError; end

  has_many :user_feature_flags, dependent: :destroy
  validates :key, presence: true, uniqueness: true

  def self.flags_for(user)
    overrides = user.user_feature_flags.index_by(&:feature_flag_registry_id)
    all.map do |entry|
      override = overrides[entry.id]
      {
        id:              entry.id.to_s,
        key:             entry.key,
        description:     entry.description || "",
        category:        entry.category || "",
        user_toggleable: entry.user_toggleable,
        value:           override ? override.value : entry.default_value
      }
    end
  end
end
