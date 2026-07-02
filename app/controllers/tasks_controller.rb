class TasksController < ApplicationController
  before_action :authenticate_user
  before_action :set_users, only: [:index, :edit, :create, :update]

  def index
    @tasks = Task.all.includes(:assignee)
  end

  def edit
    @task = Task.find(params[:id])
  end

  def create
    @task = Task.new(task_params)

    if @task.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("tasks", @task),
            turbo_stream.replace("new_task", partial: "task_form", locals: {task: Task.new})
          ]
        end
        format.html { redirect_to tasks_path }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("new_task", partial: "task_form", locals: {task: @task}),
            status: :unprocessable_content
        end
        format.html do
          @tasks = Task.all.includes(:assignee)
          render :index, status: :unprocessable_content
        end
      end
    end
  end

  def update
    @task = Task.find(params[:id])

    if @task.update(task_params)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@task, @task) }
        format.html { redirect_to tasks_path }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@task, partial: "task", locals: {task: @task}),
            status: :unprocessable_content
        end
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @task = Task.find(params[:id])
    @task.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@task) }
      format.html { redirect_to tasks_path }
    end
  end

  private

  def set_users
    @users = User.order(:name)
  end

  def task_params
    params.require(:task).permit(:title, :description, :complete, :assignee_id)
  end
end
