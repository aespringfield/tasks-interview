require "rails_helper"

RSpec.describe Task, type: :model do
  it "has a valid factory" do
    expect(build(:task)).to be_valid
  end

  it "requires a title" do
    task = build(:task, title: nil)
    expect(task).not_to be_valid
    expect(task.errors[:title]).to include("can't be blank")
  end

  it "is valid without an assignee" do
    expect(build(:task, assignee: nil)).to be_valid
  end

  it "can belong to an assignee" do
    user = create(:user)
    expect(build(:task, assignee: user).assignee).to eq(user)
  end
end
