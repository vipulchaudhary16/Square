ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "factory_bot_rails"

Shoulda::Matchers.configure do |config|
  config.integrate { |with| with.test_framework(:minitest).library(:rails) }
end

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  fixtures :none
end

class ActionDispatch::IntegrationTest
  include FactoryBot::Syntax::Methods

  def auth_header(user)
    token = JwtService.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
  end
end
