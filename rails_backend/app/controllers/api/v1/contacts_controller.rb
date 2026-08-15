module Api
  module V1
    class ContactsController < ApplicationController
      def index
        render json: current_user.owned_contacts.includes(:linked_user).map(&:api_json)
      end

      def search
        query = params[:q].to_s.strip
        return render json: { contacts: [], platform_users: [] } if query.length < 2

        result = Contact.search_for(current_user.id, query)
        render json: {
          contacts:       result[:contacts].map(&:api_json),
          platform_users: result[:platform_users].map(&:platform_match_json)
        }
      end

      def create
        contact = current_user.owned_contacts.create!(contact_params)
        render json: contact.api_json, status: :created
      rescue ActiveRecord::RecordInvalid, ActiveRecord::InvalidForeignKey => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        contact = current_user.owned_contacts.find(params[:id])
        contact.update!(contact_params)
        render json: contact.api_json
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Contact not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def loans
        contact = current_user.owned_contacts.find(params[:id])
        result  = contact.loans_for(current_user)

        render json: {
          contact:     contact.api_json,
          loans:       result[:loans].map { |l| l.brief_json(current_user) },
          net_balance: result[:net_balance]
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Contact not found" }, status: :not_found
      end

      private

      def contact_params
        params.permit(:name, :phone, :email, :linked_user_id)
      end
    end
  end
end
