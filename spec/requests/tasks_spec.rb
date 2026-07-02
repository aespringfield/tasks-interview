require "rails_helper"

RSpec.describe "Tasks", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "GET /tasks" do
    it "shows each task's assignee" do
      assignee = create(:user, name: "Ada Lovelace")
      create(:task, title: "Book flights", assignee: assignee)

      get tasks_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Book flights")
      expect(response.body).to include("Ada Lovelace")
    end

    it "does not add a query per task for assignees" do
      create(:task, assignee: create(:user))
      baseline = count_queries { get tasks_path }

      create(:task, assignee: create(:user))
      create(:task, assignee: create(:user))
      with_more_tasks = count_queries { get tasks_path }

      expect(with_more_tasks).to eq(baseline)
    end
  end

  describe "POST /tasks" do
    it "creates a task with an assignee" do
      assignee = create(:user)

      expect {
        post tasks_path, params: {task: {title: "Write proposal", assignee_id: assignee.id}}
      }.to change(Task, :count).by(1)

      expect(response).to redirect_to(tasks_path)
      expect(Task.last.assignee).to eq(assignee)
    end

    it "re-renders the form with errors when title is blank" do
      expect {
        post tasks_path, params: {task: {title: ""}}
      }.not_to change(Task, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("can&#39;t be blank")
    end

    it "re-renders the form with errors when assignee_id does not exist" do
      expect {
        post tasks_path, params: {task: {title: "Write proposal", assignee_id: User.maximum(:id).to_i + 1}}
      }.not_to change(Task, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("must exist")
    end
  end

  describe "PATCH /tasks/:id" do
    it "toggles complete" do
      task = create(:task, complete: false)

      patch task_path(task), params: {task: {complete: true}}

      expect(response).to redirect_to(tasks_path)
      expect(task.reload).to be_complete
    end

    it "reassigns a task" do
      task = create(:task)
      new_assignee = create(:user)

      patch task_path(task), params: {task: {assignee_id: new_assignee.id}}

      expect(task.reload.assignee).to eq(new_assignee)
    end

    it "re-renders edit with errors when title is blanked out" do
      task = create(:task, title: "Original")

      patch task_path(task), params: {task: {title: ""}}

      expect(response).to have_http_status(:unprocessable_content)
      expect(task.reload.title).to eq("Original")
    end
  end

  describe "DELETE /tasks/:id" do
    it "removes the task" do
      task = create(:task)

      expect {
        delete task_path(task)
      }.to change(Task, :count).by(-1)

      expect(response).to redirect_to(tasks_path)
    end
  end

  describe "Turbo Stream responses" do
    it "appends the new task and resets the form on successful create" do
      post tasks_path, params: {task: {title: "Write proposal"}}, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include('action="append"', 'target="tasks"')
      expect(response.body).to include('action="replace"', 'target="new_task"')
    end

    it "replaces the new-task form with errors on failed create" do
      expect {
        post tasks_path, params: {task: {title: ""}}, as: :turbo_stream
      }.not_to change(Task, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('action="replace"', 'target="new_task"')
      expect(response.body).to include("can&#39;t be blank")
    end

    it "replaces the task row on successful update" do
      task = create(:task, complete: false)

      patch task_path(task), params: {task: {complete: true}}, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("action=\"replace\"", "target=\"#{ActionView::RecordIdentifier.dom_id(task)}\"")
      expect(task.reload).to be_complete
    end

    it "replaces the task row with errors on failed update" do
      task = create(:task, title: "Original")

      patch task_path(task), params: {task: {title: ""}}, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("can&#39;t be blank")
      expect(task.reload.title).to eq("Original")
    end

    it "removes the task row on successful destroy" do
      task = create(:task)

      delete task_path(task), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("action=\"remove\"", "target=\"#{ActionView::RecordIdentifier.dom_id(task)}\"")
    end
  end

  def count_queries
    count = 0
    callback = ->(*, payload) { count += 1 unless payload[:sql].match?(/SCHEMA|TRANSACTION/) }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
    count
  end
end
