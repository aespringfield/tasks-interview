class Task < ApplicationRecord
  belongs_to :assignee, class_name: "User", optional: true

  validates :title, presence: true
  validate :assignee_exists

  private

  def assignee_exists
    errors.add(:assignee, "must exist") if assignee_id.present? && !User.exists?(assignee_id)
  end
end
