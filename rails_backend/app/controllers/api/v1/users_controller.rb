module Api
  module V1
    class UsersController < ApplicationController
      def search
        q = params[:q].to_s.strip
        users = q.length >= 2 ? User.search_by_query(q) : []
        render json: users.map(&:member_json)
      end

      def flags
        render json: FeatureFlagRegistry.flags_for(current_user)
      end

      def update_flags
        parsed = JSON.parse(request.body.read) rescue {}
        current_user.update_feature_flags!(parsed)
        render json: FeatureFlagRegistry.flags_for(current_user)
      rescue FeatureFlagRegistry::NotFoundError => e
        render json: { error: e.message }, status: :bad_request
      rescue FeatureFlagRegistry::NotToggleableError => e
        render json: { error: e.message }, status: :forbidden
      end
    end
  end
end
