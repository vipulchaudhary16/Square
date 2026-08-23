module Api
  module V1
    class GroupInvitesController < ApplicationController
      before_action :set_invite
      before_action :require_owner!

      def revoke
        @invite.revoke!
        render json: @invite.api_json
      end

      private

      def set_invite
        @invite = GroupInvite.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Invite not found" }, status: :not_found
      end

      def require_owner!
        return if @invite && @invite.group.created_by_id == current_user.id

        render json: { error: "Only the group admin can manage invitations" }, status: :forbidden
      end
    end
  end
end
