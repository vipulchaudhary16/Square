require "test_helper"

class LoanTest < ActiveSupport::TestCase
  test "valid loan saves" do
    lender = create(:user)
    contact = create(:contact, owner: lender)
    loan = Loan.new(
      lender_user_id: lender.id,
      contact_id: contact.id,
      amount: 5000,
      date: Time.current,
      status: "PENDING",
      interest_mode: "none"
    )
    assert loan.valid?
  end

  test "requires due_date when interest_mode is penalty" do
    lender = create(:user)
    contact = create(:contact, owner: lender)
    loan = Loan.new(
      lender_user_id: lender.id,
      contact_id: contact.id,
      amount: 5000,
      date: Time.current,
      status: "PENDING",
      interest_mode: "penalty"
    )
    assert_not loan.valid?
    assert_includes loan.errors[:due_date], "can't be blank"
  end

  test "due_date not required for interest_mode none" do
    lender = create(:user)
    contact = create(:contact, owner: lender)
    loan = Loan.new(
      lender_user_id: lender.id, contact_id: contact.id,
      amount: 5000, date: Time.current, status: "PENDING", interest_mode: "none"
    )
    assert loan.valid?
  end

  test "for_user scope returns loans where user is lender" do
    lender = create(:user)
    contact = create(:contact, owner: lender)
    loan = create(:loan, lender: lender, contact: contact)
    assert_includes Loan.for_user(lender.id), loan
  end

  test "for_user scope returns loans where user is borrower" do
    lender = create(:user)
    borrower = create(:user)
    contact = create(:contact, owner: lender, linked_user: borrower)
    loan = create(:loan, lender: lender, borrower: borrower, contact: contact)
    assert_includes Loan.for_user(borrower.id), loan
  end

  test "lender_for? returns true when user is the lender" do
    lender = create(:user)
    contact = create(:contact, owner: lender)
    loan = create(:loan, lender: lender, contact: contact)
    assert loan.lender_for?(lender.id)
  end

  test "lender_for? returns false when user is the borrower" do
    lender = create(:user)
    borrower = create(:user)
    contact = create(:contact, owner: lender, linked_user: borrower)
    loan = create(:loan, lender: lender, borrower: borrower, contact: contact)
    assert_not loan.lender_for?(borrower.id)
  end

  test "for_user scope does not return loans for unrelated user" do
    lender = create(:user)
    contact = create(:contact, owner: lender)
    create(:loan, lender: lender, contact: contact)
    unrelated = create(:user)
    assert_empty Loan.for_user(unrelated.id)
  end

  test "contact must belong to the lender" do
    lender = create(:user)
    other_user = create(:user)
    wrong_contact = create(:contact, owner: other_user)
    loan = Loan.new(
      lender_user_id: lender.id,
      contact_id: wrong_contact.id,
      amount: 5000,
      date: Time.current,
      status: "PENDING",
      interest_mode: "none"
    )
    assert_not loan.valid?
    assert_includes loan.errors[:contact], "must belong to the lender"
  end
end
