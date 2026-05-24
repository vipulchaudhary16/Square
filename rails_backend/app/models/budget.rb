class Budget < ApplicationRecord
  belongs_to :user
  belongs_to :category
  validates :category_id, :amount, :month, presence: true
  validates :month, format: { with: /\A\d{4}-\d{2}\z/, message: "must be YYYY-MM" }
  validates :category_id, uniqueness: { scope: [:user_id, :month] }
  validates :amount, numericality: { greater_than: 0 }
end
