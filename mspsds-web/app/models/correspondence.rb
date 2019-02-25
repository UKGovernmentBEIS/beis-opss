class Correspondence < ApplicationRecord
  include DateConcern
  belongs_to :investigation, optional: true

  before_validation :strip_whitespace, :trim_end_line

  validates :email_address, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP }, on: :context
  validates_presence_of :correspondence_date, on: :context
  validates_length_of :details, maximum: 50000

  def get_date_key
    :correspondence_date
  end

  has_many_attached :documents

  enum contact_method: {
    email: "Email",
    phone: "Phone call"
  }, _suffix: true

  def strip_whitespace
    changed.each do |attribute|
      if send(attribute).respond_to?(:strip)
        send("#{attribute}=", send(attribute).strip)
      end
    end
  end

  def can_be_displayed?
    return true if investigation.source&.is_a? ReportSource
    return true unless has_consumer_info
    return true if User.current.organisation == investigation&.source&.user&.organisation

    false
  end

private

  # Browsers treat end of line as one character when checking input length, but send it as \r\n, 2 characters
  # To keep max length consistent we need to reverse that
  def trim_end_line
    self.details = details.gsub("\r\n", "\n") if self.details
  end
end
