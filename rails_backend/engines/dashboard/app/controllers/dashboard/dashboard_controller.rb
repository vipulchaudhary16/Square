module Dashboard
  class DashboardController < ::ApplicationController
    def show
      include_trends = params[:include_trends] != "false"
      render json: Summary.new(current_user, include_trends: include_trends).as_json
    end
  end
end
