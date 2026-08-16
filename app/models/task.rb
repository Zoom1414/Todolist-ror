class Task < ApplicationRecord
  validates :title, presence: true, length: { minimum: 2, maximum: 140 }
  validates :check, inclusion: { in: [true, false] }, allow_nil: true

  before_validation :normalize_title
  before_validation :set_default_status
  before_validation :set_default_due_date

  scope :pending, -> { where(check: false) }
  scope :done, -> { where(check: true) }

  def created_time
    created_at&.in_time_zone("Asia/Bangkok")&.strftime("%d %b %Y • %H:%M") || "—"
  end

  def due_date_text
    return "No due date" if due_date.blank?

    due_date.in_time_zone("Asia/Bangkok").strftime("%d %b %Y")
  end

  def done_time
    updated_at&.in_time_zone("Asia/Bangkok")&.strftime("%d %b %Y • %H:%M") || "—"
  end

  def status_text
    if check
      "Done #{done_time}"
    else
      "Due #{due_date_text} • Created #{created_time}"
    end
  end

  private

  def normalize_title
    self.title = title.to_s.strip
  end

  def set_default_status
    self.check = false if check.nil?
  end

  def set_default_due_date
    self.due_date = Date.today + 7.days if due_date.blank?
  end
end
