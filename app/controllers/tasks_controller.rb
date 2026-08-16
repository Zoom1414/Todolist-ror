class TasksController < ApplicationController
  before_action :load_counts_and_tasks, only: [:index, :create, :toggle, :destroy]

  def index
    @task = Task.new
    @filter = params[:status].presence || "all"
    @search = params[:search].presence || ""
    load_counts_and_tasks
  end

  def create
    @task = Task.new(task_params)

    respond_to do |format|
      if @task.save
        @task = Task.new
        @filter = params[:status].presence || "all"
        @search = params[:search].presence || ""
        load_counts_and_tasks

        format.html { redirect_to tasks_path(status: @filter, search: @search), notice: "Task added successfully." }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("flash-messages", partial: "tasks/flash"),
            turbo_stream.update("task-form", partial: "tasks/form", locals: { task: @task }),
            turbo_stream.update("task-summary", partial: "tasks/summary", locals: { total_count: @total_count, done_count: @done_count, pending_count: @pending_count }),
            turbo_stream.update("task-list-container", partial: "tasks/list", locals: { tasks: @tasks, filter: @filter, search: @search }),
            turbo_stream.update("todo-count", "#{@total_count} tasks")
          ]
        end
      else
        @filter = params[:status].presence || "all"
        @search = params[:search].presence || ""
        format.html { render :index, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("task-form", partial: "tasks/form", locals: { task: @task })
          ], status: :unprocessable_entity
        end
      end
    end
  end

  def toggle
    @task = Task.find(params[:id])
    @task.update!(check: !@task.check)
    @filter = params[:status].presence || "all"
    @search = params[:search].presence || ""

    respond_to do |format|
      format.html { redirect_to tasks_path(status: @filter, search: @search), notice: "Task updated successfully." }
      format.turbo_stream do
        load_counts_and_tasks
        render turbo_stream: [
          turbo_stream.update("flash-messages", partial: "tasks/flash"),
          turbo_stream.update("task-form", partial: "tasks/form", locals: { task: Task.new }),
          turbo_stream.update("task-summary", partial: "tasks/summary", locals: { total_count: @total_count, done_count: @done_count, pending_count: @pending_count }),
          turbo_stream.update("task-list-container", partial: "tasks/list", locals: { tasks: @tasks, filter: @filter, search: @search }),
          turbo_stream.update("todo-count", "#{@total_count} tasks")
        ]
      end
    end
  end

  def destroy
    @task = Task.find(params[:id])
    @task.destroy
    @filter = params[:status].presence || "all"
    @search = params[:search].presence || ""

    respond_to do |format|
      format.html { redirect_to tasks_path(status: @filter, search: @search), notice: "Task deleted successfully." }
      format.turbo_stream do
        load_counts_and_tasks
        render turbo_stream: [
          turbo_stream.update("flash-messages", partial: "tasks/flash"),
          turbo_stream.update("task-form", partial: "tasks/form", locals: { task: Task.new }),
          turbo_stream.update("task-summary", partial: "tasks/summary", locals: { total_count: @total_count, done_count: @done_count, pending_count: @pending_count }),
          turbo_stream.update("task-list-container", partial: "tasks/list", locals: { tasks: @tasks, filter: @filter, search: @search }),
          turbo_stream.update("todo-count", "#{@total_count} tasks")
        ]
      end
    end
  end

  def edit
    @task = Task.find(params[:id])
    @filter = params[:status].presence || "all"
  end

  def update
    @task = Task.find(params[:id])
    @filter = params[:status].presence || "all"
    @search = params[:search].presence || ""

    respond_to do |format|
      if @task.update(task_params)
        load_counts_and_tasks

        format.html { redirect_to tasks_path(status: @filter, search: @search), notice: "Task updated successfully." }
        format.turbo_stream do
          flash.now[:notice] = "Task updated successfully."
          render turbo_stream: [
            turbo_stream.update("flash-messages", partial: "tasks/flash"),
            turbo_stream.update("task-list-container", partial: "tasks/list", locals: { tasks: @tasks, filter: @filter, search: @search }),
            turbo_stream.update("task-summary", partial: "tasks/summary", locals: { total_count: @total_count, done_count: @done_count, pending_count: @pending_count })
          ]
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("edit-form-#{@task.id}", partial: "tasks/edit_form", locals: { task: @task, filter: @filter })
          ], status: :unprocessable_entity
        end
      end
    end
  end

  private

  def load_counts_and_tasks
    @filter = params[:status].presence || "all"
    @search = params[:search].presence || ""
    @all_tasks = Task.order(created_at: :desc)
    @tasks = @all_tasks.dup
    @tasks = @tasks.where(check: false) if @filter == "pending"
    @tasks = @tasks.where(check: true) if @filter == "done"
    if @search.present?
      search_term = "%#{Task.sanitize_sql_like(@search.downcase)}%"
      @tasks = @tasks.where("LOWER(title) LIKE ?", search_term)
    end
    @task ||= Task.new
    @total_count = @all_tasks.count
    @done_count = @all_tasks.where(check: true).count
    @pending_count = @all_tasks.where(check: false).count
  end

  def task_params
    params.require(:task).permit(:title, :check, :due_date)
  end
end
