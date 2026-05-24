class User < ApplicationRecord
  has_secure_password

  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :created_groups, class_name: "Group", foreign_key: :created_by_id, dependent: :destroy
  has_many :expenses_paid, class_name: "Expense", foreign_key: :payer_id, dependent: :destroy
  has_many :expense_participants, dependent: :destroy
  has_many :participated_expenses, through: :expense_participants, source: :expense
  has_many :incomes, dependent: :destroy
  has_many :investments, dependent: :destroy
  has_many :loans, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :user_feature_flags, dependent: :destroy
  has_many :feature_flag_registries, through: :user_feature_flags
  has_many :comments, dependent: :destroy
  has_many :activity_logs, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :owned_contacts, class_name: "Contact", foreign_key: :owner_user_id, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, allow_nil: true

  before_validation :set_username_from_email, on: :create

  scope :search_by_query, ->(q) {
    where("email ILIKE :q OR username ILIKE :q", q: "%#{sanitize_sql_like(q)}%").limit(10)
  }

  def display_name
    name = "#{first_name} #{last_name}".strip
    name.blank? ? username : name
  end

  private

  def set_username_from_email
    self.username = email.split("@").first if username.blank? && email.present?
  end
end
