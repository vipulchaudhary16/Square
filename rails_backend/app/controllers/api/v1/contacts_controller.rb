module Api
  module V1
    class ContactsController < ApplicationController
      def index
        render json: current_user.owned_contacts.includes(:linked_user).map { |c| serialize(c) }
      end

      def search
        query = params[:q].to_s.strip
        return render json: { contacts: [], platform_users: [] } if query.length < 2

        result = Contact.search_for(current_user.id, query)
        render json: {
          contacts:       result[:contacts].map { |c| serialize(c) },
          platform_users: result[:platform_users].map { |u| serialize_platform_user(u) }
        }
      end

      def create
        contact = current_user.owned_contacts.create!(contact_params)
        render json: serialize(contact), status: :created
      rescue ActiveRecord::RecordInvalid, ActiveRecord::InvalidForeignKey => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        contact = current_user.owned_contacts.find(params[:id])
        contact.update!(contact_params)
        render json: serialize(contact)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Contact not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def loans
        contact = current_user.owned_contacts.find(params[:id])
        loans   = Loan.for_user(current_user.id)
                      .where(contact_id: contact.id)
                      .includes(:contact, :category)
                      .order(date: :desc)

        active_loans = loans.reject { |l| l.status == "PAID" }

        render json: {
          contact:     serialize(contact),
          loans:       loans.map { |l| serialize_loan(l) },
          net_balance: net_balance(active_loans)
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Contact not found" }, status: :not_found
      end

      private

      def contact_params
        params.permit(:name, :phone, :email, :linked_user_id)
      end

      def serialize(c)
        {
          id:             c.id.to_s,
          name:           c.name,
          phone:          c.phone,
          email:          c.email,
          linked_user_id: c.linked_user_id&.to_s,
          on_platform:    c.on_platform?,
          created_at:     c.created_at.iso8601
        }
      end

      def serialize_platform_user(u)
        {
          id:            u.id.to_s,
          username:      u.username,
          name:          u.display_name,
          email:         u.email,
          mobile_number: u.mobile_number,
          on_platform:   true
        }
      end

      def serialize_loan(l)
        direction = l.lender_for?(current_user.id) ? "lent" : "borrowed"
        {
          id:            l.id.to_s,
          direction:     direction,
          amount:        l.amount.to_f,
          status:        l.status,
          date:          l.date.iso8601,
          due_date:      l.due_date&.iso8601,
          description:   l.description,
          category_name: l.category&.name || "",
          interest_mode: l.interest_mode
        }
      end

      def net_balance(loans)
        lent     = loans.select { |l| l.lender_for?(current_user.id) }.sum(&:amount).to_f
        borrowed = loans.reject { |l| l.lender_for?(current_user.id) }.sum(&:amount).to_f
        diff     = lent - borrowed
        {
          direction: diff >= 0 ? "owed_to_you" : "you_owe",
          amount:    diff.abs
        }
      end
    end
  end
end
