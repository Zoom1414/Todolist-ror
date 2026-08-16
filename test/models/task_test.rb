require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "new task defaults to pending" do
    task = Task.new(title: "Read Ruby book")

    assert task.valid?
    assert_equal false, task.check
  end
end
