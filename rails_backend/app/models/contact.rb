class Contact < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: :owner_user_id
  belongs_to :linked_user, class_name: "User", foreign_key: :linked_user_id, optional: true

  validates :name, presence: true
  validates :owner_user_id, presence: true

  def on_platform?
    linked_user_id.present?
  end

  def self.search_for(owner_user_id, query)
    q = "%#{sanitize_sql_like(query.to_s.downcase)}%"

    contacts = where(owner_user_id: owner_user_id)
                 .where("LOWER(name) LIKE ? OR phone LIKE ? OR LOWER(email) LIKE ?", q, q, q)

    already_linked_ids = where(owner_user_id: owner_user_id)
                           .where.not(linked_user_id: nil)
                           .pluck(:linked_user_id)

    platform_users = User.where.not(id: [owner_user_id, *already_linked_ids])
                         .where("LOWER(username) LIKE ? OR mobile_number LIKE ? OR LOWER(email) LIKE ?", q, q, q)
                         .limit(5)

    { contacts: contacts, platform_users: platform_users }
  end

  # Loans between this contact and its owner, plus the net balance across
  # the still-open ones — used by the contact detail view.
  def loans_for(current_user)
    loans = Loan.for_user(current_user.id)
                .where(contact_id: id)
                .includes(:contact, :category)
                .order(date: :desc)
    active_loans = loans.reject { |l| l.status == "PAID" }

    { loans: loans, net_balance: Loan.net_balance_for(active_loans, current_user.id) }
  end

  def api_json
    {
      id:             id.to_s,
      name:           name,
      phone:          phone,
      email:          email,
      linked_user_id: linked_user_id&.to_s,
      on_platform:    on_platform?,
      created_at:     created_at.iso8601
    }
  end
end
