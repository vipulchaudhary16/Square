require "test_helper"

class Api::V1::LoanRemindersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lender   = create(:user)
    @borrower = create(:user)
    @contact  = create(:contact, owner: @lender, linked_user: @borrower)
    @loan     = create(:loan, lender: @lender, borrower: @borrower, contact: @contact)
  end

  test "lender can create a reminder" do
    assert_difference("LoanReminder.count", 1) do
      post "/api/loans/#{@loan.id}/reminders",
           params: {
             remind_at:      3.days.from_now.iso8601,
             nudge_borrower: true,
             via_push:       true,
             via_email:      true
           }.to_json,
           headers: auth_header(@lender)
    end
    assert_response :created
    reminder = LoanReminder.last
    assert reminder.nudge_borrower
    assert_equal @lender.id, reminder.set_by_user_id
  end

  test "borrower cannot create a reminder" do
    post "/api/loans/#{@loan.id}/reminders",
         params: { remind_at: 1.day.from_now.iso8601 }.to_json,
         headers: auth_header(@borrower)
    assert_response :forbidden
  end

  test "unrelated user gets 404" do
    post "/api/loans/#{@loan.id}/reminders",
         params: { remind_at: 1.day.from_now.iso8601 }.to_json,
         headers: auth_header(create(:user))
    assert_response :not_found
  end

  test "remind_at is required" do
    post "/api/loans/#{@loan.id}/reminders",
         params: {}.to_json,
         headers: auth_header(@lender)
    assert_response :bad_request
  end
end
