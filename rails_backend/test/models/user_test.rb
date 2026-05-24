require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "can set and retrieve mobile_number" do
    user = create(:user, mobile_number: "+91 98765 43210")
    user.reload
    assert_equal "+91 98765 43210", user.mobile_number
  end

  test "mobile_number defaults to nil" do
    user = create(:user)
    assert_nil user.mobile_number
  end
end
