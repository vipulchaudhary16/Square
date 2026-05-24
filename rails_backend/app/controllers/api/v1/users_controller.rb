module Api
  module V1
    class UsersController < ApplicationController
      def search
        q = params[:q].to_s.strip
        users = q.length >= 2 ? User.search_by_query(q) : []
        render json: users.map { |u|
          { id: u.id.to_s, username: u.username, email: u.email, first_name: u.first_name, last_name: u.last_name }
        }
      end

      def flags
        registry  = FeatureFlagRegistry.all.to_a
        overrides = current_user.user_feature_flags.index_by(&:feature_flag_registry_id)
        flags = registry.map do |entry|
          override = overrides[entry.id]
          {
            id:              entry.id.to_s,
            key:             entry.key,
            description:     entry.description || "",
            category:        entry.category || "",
            user_toggleable: entry.user_toggleable,
            value:           override ? override.value : entry.default_value
          }
        end
        render json: flags
      end

      def update_flags
        updates = request.body.read
        parsed  = JSON.parse(updates) rescue {}

        registry = FeatureFlagRegistry.all.index_by { |r| r.id.to_s }

        parsed.each do |id_str, value|
          entry = registry[id_str.to_s]
          unless entry
            render json: { error: "Flag not found: #{id_str}" }, status: :bad_request and return
          end
          unless entry.user_toggleable
            render json: { error: "Flag not user-toggleable: #{entry.key}" }, status: :forbidden and return
          end
          UserFeatureFlag.upsert(
            { user_id: current_user.id, feature_flag_registry_id: entry.id, value: value },
            unique_by: [:user_id, :feature_flag_registry_id],
            update_only: [:value]
          )
        end

        flags
      end
    end
  end
end
