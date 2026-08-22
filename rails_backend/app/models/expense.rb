class Expense < ApplicationRecord
  include Trackable

  SPLIT_TYPES    = %w[EQUAL EXACT PERCENT].freeze
  TRACKED_FIELDS = %i[description amount date split_type].freeze

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
    s = s.where(group_id: params[:group_id]) if params[:group_id].present?
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

  def self.for_index(user, params)
    accessible_to(user).with_filters(params).with_sort(params)
      .includes(:payer, :group, :category, :expense_splits, :expense_participants)
  end

  def self.create_with_splits!(user:, params:)
    category = user.categories.find_by(id: params[:category_id]) ||
               user.categories.find_by(name: "General")

    participant_ids   = params[:participants] || [user.id.to_s]
    raw_splits        = params[:splits]&.to_unsafe_h || {}
    splits_calculated = ExpenseSplitCalculator.calculate(
      params[:amount].to_f, params[:split_type], participant_ids, raw_splits
    )

    expense = new(
      description: params[:description],
      amount:      params[:amount],
      category_id: category.id,
      date:        params[:date] || Time.current,
      payer_id:    user.id,
      group_id:    params[:group_id],
      split_type:  params[:split_type] || "EQUAL"
    )

    transaction do
      expense.save!
      participant_ids.each { |uid| ExpenseParticipant.create!(expense: expense, user_id: uid) }
      splits_calculated.each { |uid, amt| ExpenseSplit.create!(expense: expense, user_id: uid, amount: amt) }
      ActivityLog.record!(loggable: expense, user: user, action: "CREATE", details: "Expense created: #{expense.description}")
    end

    expense
  end

  def apply_updates!(params, current_user:)
    changes = track_changes(params, TRACKED_FIELDS)

    if params[:category_id].present?
      new_cat = current_user.categories.find_by(id: params[:category_id])
      if new_cat && new_cat.id != category_id
        changes << "category: #{category.name} → #{new_cat.name}"
        self.category_id = new_cat.id
      end
    end

    TRACKED_FIELDS.each do |field|
      next unless params[field].present?
      assign_attributes(field => params[field])
    end

    if save
      ActivityLog.record!(loggable: self, user: current_user, action: "UPDATE", details: changes.join(", ")) if changes.any?
      true
    else
      false
    end
  end

  def split_for(user_id)
    split = expense_splits.find { |s| s.user_id == user_id }
    return split.amount.to_f if split
    return 0.0 unless expense_participants.any? { |p| p.user_id == user_id }
    amount / expense_participants.size.to_f
  end

  # Matches the shape GroupsController#group_expenses has always returned.
  def group_summary_json
    {
      id:            id.to_s,
      description:   description,
      amount:        amount.to_f,
      category_id:   category_id.to_s,
      category_name: category&.name || "",
      category_color: category&.color,
      date:          date.iso8601,
      payer_id:      payer_id.to_s,
      payer_name:    payer.display_name,
      group_id:      group_id&.to_s,
      split_type:    split_type,
      participants:  expense_participants.map { |p| p.user_id.to_s },
      splits:        expense_splits.each_with_object({}) { |s, h| h[s.user_id.to_s] = s.amount.to_f }
    }
  end

  def api_json
    {
      id:            id.to_s,
      description:   description,
      amount:        amount.to_f,
      category_id:   category_id.to_s,
      category_name: category&.name || "",
      category_color: category&.color,
      date:          date.iso8601,
      payer_id:      payer_id.to_s,
      payer_name:    payer.display_name,
      group_id:      group_id&.to_s,
      group_name:    group&.name,
      split_type:    split_type,
      participants:  expense_participants.map { |p| p.user_id.to_s },
      splits:        expense_splits.each_with_object({}) { |s, h| h[s.user_id.to_s] = s.amount.to_f },
      created_at:    created_at.iso8601
    }
  end
end
