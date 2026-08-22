class Income < ApplicationRecord
  include Trackable

  TRACKED_FIELDS = %i[source amount category_id date description].freeze

  belongs_to :user
  belongs_to :category
  has_many :activity_logs, as: :loggable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  validates :source, :amount, :date, presence: true
  validates :amount, numericality: { greater_than: 0 }

  scope :with_filters, ->(params) {
    s = all
    s = s.where(category_id: params[:category_id]) if params[:category_id].present?
    s = s.where("date >= ?", params[:start_date]) if params[:start_date].present?
    s = s.where("date <= ?", params[:end_date]) if params[:end_date].present?
    s = s.where("source ILIKE ? OR description ILIKE ?",
                "%#{ActiveRecord::Base.sanitize_sql_like(params[:search])}%",
                "%#{ActiveRecord::Base.sanitize_sql_like(params[:search])}%") if params[:search].present?
    s
  }

  scope :with_sort, ->(params) {
    col   = %w[date amount].include?(params[:sort_by]) ? params[:sort_by] : "date"
    order = params[:sort_order] == "asc" ? :asc : :desc
    reorder(col => order)
  }

  def self.for_index(user, params)
    user.incomes.with_filters(params).with_sort(params).includes(:category)
  end

  def self.create_for_user!(user:, params:)
    category = user.categories.find_by(id: params[:category_id]) ||
               user.categories.find_by(name: "General")
    user.incomes.create!(
      source:      params[:source],
      amount:      params[:amount],
      category_id: category.id,
      date:        params[:date],
      description: params[:description]
    )
  end

  def apply_updates!(params, current_user:)
    changes = track_changes(params, TRACKED_FIELDS)
    attrs   = params.permit(*TRACKED_FIELDS).to_h.select { |k, _| params[k].present? }

    if update(attrs)
      ActivityLog.record!(loggable: self, user: current_user, action: "UPDATE", details: changes.join(", ")) if changes.any?
      true
    else
      false
    end
  end

  def api_json
    { id: id.to_s, user_id: user_id.to_s, source: source, amount: amount.to_f,
      category_id: category_id.to_s, category_name: category&.name || "", category_color: category&.color,
      date: date.iso8601, description: description, created_at: created_at.iso8601 }
  end
end
