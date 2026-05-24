class Income < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :activity_logs, as: :loggable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  validates :source, :amount, :date, presence: true
  validates :amount, numericality: { greater_than: 0 }
end
