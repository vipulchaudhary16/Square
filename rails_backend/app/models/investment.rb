class Investment < ApplicationRecord
  include Trackable

  TYPES          = %w[STOCK CRYPTO MUTUAL_FUND REAL_ESTATE OTHER].freeze
  TRACKED_FIELDS = %i[name investment_type amount_invested current_value date description].freeze

  belongs_to :user
  belongs_to :category, optional: true
  has_many :activity_logs, as: :loggable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy

  validates :name, :investment_type, :date, presence: true
  validates :amount_invested, :current_value, numericality: { greater_than_or_equal_to: 0 }
  validates :investment_type, inclusion: { in: TYPES }

  def self.create_for_user!(user:, params:)
    category = user.categories.find_by(id: params[:category_id])
    user.investments.create!(params.permit(*TRACKED_FIELDS, :category_id).merge(category_id: category&.id))
  end

  def apply_updates!(params, current_user:)
    changes = track_changes(params, TRACKED_FIELDS)
    if update(params.permit(*TRACKED_FIELDS, :category_id))
      ActivityLog.record!(loggable: self, user: current_user, action: "UPDATE", details: changes.join(", ")) if changes.any?
      true
    else
      false
    end
  end

  def api_json
    { id: id.to_s, user_id: user_id.to_s, name: name, type: investment_type,
      amount_invested: amount_invested.to_f, current_value: current_value.to_f,
      date: date.iso8601, description: description,
      category_id: category_id.to_s, category_name: category&.name || "",
      created_at: created_at.iso8601 }
  end
end
