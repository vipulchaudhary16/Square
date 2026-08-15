class Budget < ApplicationRecord
  belongs_to :user
  belongs_to :category
  validates :category_id, :amount, :month, presence: true
  validates :month, format: { with: /\A\d{4}-\d{2}\z/, message: "must be YYYY-MM" }
  validates :category_id, uniqueness: { scope: [:user_id, :month] }
  validates :amount, numericality: { greater_than: 0 }

  def self.create_for_user!(user:, params:)
    category = user.categories.find_by(id: params[:category_id]) ||
               user.categories.find_by(name: "General")
    user.budgets.create!(category_id: category.id, amount: params[:amount], month: params[:month])
  end

  def api_json
    { id: id.to_s, user_id: user_id.to_s,
      category_id: category_id.to_s, category_name: category&.name || "",
      amount: amount.to_f, month: month, created_at: created_at.iso8601 }
  end
end
