class Expense < ApplicationRecord
  SPLIT_TYPES = %w[EQUAL EXACT PERCENT].freeze

  belongs_to :payer, class_name: "User"
  belongs_to :group, optional: true
  belongs_to :category
  has_many :expense_participants, dependent: :destroy
  has_many :participants, through: :expense_participants, source: :user
  has_many :expense_splits, dependent: :destroy
  has_many :activity_logs, as: :loggable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy

  validates :description, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :split_type, inclusion: { in: SPLIT_TYPES }, allow_nil: true

  scope :accessible_to, ->(user) {
    joins("LEFT JOIN expense_participants ep ON ep.expense_id = expenses.id")
      .where("expenses.payer_id = :uid OR ep.user_id = :uid", uid: user.id)
      .distinct
  }

  scope :with_filters, ->(params) {
    s = all
    s = s.where(group_id: nil) if params[:personal_only] == "true"
    s = s.where(category_id: params[:category_id]) if params[:category_id].present?
    s = s.where("date >= ?", params[:start_date]) if params[:start_date].present?
    s = s.where("date <= ?", params[:end_date]) if params[:end_date].present?
    s = s.where("description ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:search])}%") if params[:search].present?
    s
  }

  scope :with_sort, ->(params) {
    col   = %w[date amount].include?(params[:sort_by]) ? params[:sort_by] : "date"
    order = params[:sort_order] == "asc" ? :asc : :desc
    reorder(col => order)
  }
end
