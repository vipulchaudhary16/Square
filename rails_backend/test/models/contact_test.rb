require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "valid contact saves" do
    owner = create(:user)
    contact = Contact.new(owner_user_id: owner.id, name: "Rahul")
    assert contact.valid?
  end

  test "requires name" do
    owner = create(:user)
    contact = Contact.new(owner_user_id: owner.id)
    assert_not contact.valid?
    assert_includes contact.errors[:name], "can't be blank"
  end

  test "requires owner_user_id" do
    contact = Contact.new(name: "Rahul")
    assert_not contact.valid?
  end

  test "on_platform? returns true when linked_user_id set" do
    owner = create(:user)
    linked = create(:user)
    contact = create(:contact, owner: owner, linked_user: linked)
    assert contact.on_platform?
  end

  test "on_platform? returns false when no linked_user_id" do
    contact = create(:contact)
    assert_not contact.on_platform?
  end

  test "search finds contacts by name" do
    owner = create(:user)
    rahul = create(:contact, owner: owner, name: "Rahul Sharma")
    _other = create(:contact, owner: owner, name: "Priya")

    results = Contact.search_for(owner.id, "rahul")
    assert_includes results[:contacts].map(&:id), rahul.id
  end

  test "search finds platform users not yet in contacts" do
    owner = create(:user)
    platform_user = create(:user, username: "neha123", email: "neha@example.com")

    results = Contact.search_for(owner.id, "neha")
    assert_includes results[:platform_users].map(&:id), platform_user.id
  end
end
