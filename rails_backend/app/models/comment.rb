class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user
  validates :text, presence: true

  def api_json
    { id: id.to_s, user_id: user_id.to_s, text: text, created_at: created_at.iso8601 }
  end
end
