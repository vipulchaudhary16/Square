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
  has_many :lent_loans,     class_name: "Loan", foreign_key: :lender_user_id, dependent: :destroy
  has_many :borrowed_loans, class_name: "Loan", foreign_key: :borrower_user_id, dependent: :nullify
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

  def self.sign_up!(params)
    user = new(
      email:      params[:email],
      first_name: params[:first_name] || "",
      last_name:  params[:last_name]  || "",
      username:   params[:username],
      password:   params[:password]
    )
    CategorySeeder.seed(user) if user.save
    user
  end

  def self.authenticate_login(email:, password:)
    user = find_by("lower(email) = ?", email&.downcase)
    user if user&.authenticate(password)
  end

  def self.reset_password!(token:, new_password:)
    user = find_by(reset_token: token)
    raise ActiveRecord::RecordNotFound if user.nil? || user.reset_token_expiry < Time.current
    user.update!(password: new_password, reset_token: nil, reset_token_expiry: nil)
    user
  end

  def initiate_password_reset!
    token = SecureRandom.hex(32)
    update!(reset_token: token, reset_token_expiry: 1.hour.from_now)
    UserMailer.password_reset(self, token).deliver_later
  end

  def update_feature_flags!(parsed)
    registry = FeatureFlagRegistry.all.index_by { |r| r.id.to_s }
    parsed.each do |id_str, value|
      entry = registry[id_str.to_s]
      raise FeatureFlagRegistry::NotFoundError, "Flag not found: #{id_str}" unless entry
      raise FeatureFlagRegistry::NotToggleableError, "Flag not user-toggleable: #{entry.key}" unless entry.user_toggleable

      UserFeatureFlag.upsert(
        { user_id: id, feature_flag_registry_id: entry.id, value: value },
        unique_by: [:user_id, :feature_flag_registry_id],
        update_only: [:value]
      )
    end
  end

  def display_name
    name = "#{first_name} #{last_name}".strip
    name.blank? ? username : name
  end

  def self.display_name_map(user_ids)
    where(id: user_ids.uniq.compact).each_with_object({}) { |u, h| h[u.id.to_s] = u.display_name }
  end

  def api_json
    { id: id.to_s, username: username, email: email,
      first_name: first_name, last_name: last_name, created_at: created_at.iso8601 }
  end

  def member_json
    { id: id.to_s, username: username, email: email, first_name: first_name, last_name: last_name }
  end

  def platform_match_json
    { id: id.to_s, username: username, name: display_name, email: email,
      mobile_number: mobile_number, on_platform: true }
  end

  private

  def set_username_from_email
    self.username = email.split("@").first if username.blank? && email.present?
  end
end
