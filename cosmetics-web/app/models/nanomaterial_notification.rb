class NanomaterialNotification < ApplicationRecord
  class AlreadySubmittedError < StandardError; end

  belongs_to :responsible_person

  validates :name, presence: true, on: :add_name

  validates :eu_notified, inclusion: { in: [true, false] }, on: :eu_notification

  validates :notified_to_eu_on, presence: true, on: :eu_notification, if: :eu_notified?
  validate :eu_notification_date_must_be_pre_brexit, on: :eu_notification, if: :eu_notified?

  validate :eu_notification_date_is_nil, on: :eu_notification, if: :eu_not_notified?

  validate :pdf_file_attached, on: :upload_file

  has_one_attached :file


  def submit!
    raise AlreadySubmittedError, "Nanomaterial previously notified, on #{submitted_at}" if submitted?

    self.submitted_at = DateTime.now
    save!
  end

  def submitted?
    submitted_at != nil
  end

  # Checks whether all validations have passed, but without adding error messages.
  # Used to determine whether user is changing an answer from Check your answers or not.
  def submittable?
    submittable = valid?(%i[add_name eu_notification upload_file])
    errors.clear
    submittable
  end

  def can_be_made_available_on_uk_market_from
    return nil unless submitted?

    availability_date =
      if eu_notified?
        if notified_to_eu_on <= (EU_EXIT_DATE - 6.months)
          notified_to_eu_on + 6.months
        else
          notified_to_eu_on + 7.months
        end
      else
        submitted_at.in_time_zone("London") + 6.months
      end

    (availability_date + 1.day).at_midnight
  end

  def can_be_made_available_on_uk_market?
    can_be_made_available_on_uk_market_from <= Time.zone.now
  end

private

  def eu_notification_date_must_be_pre_brexit
    if notified_to_eu_on && notified_to_eu_on > EU_EXIT_DATE
      errors.add(:notified_to_eu_on, I18n.t(:post_brexit_date_given, scope: %i[activerecord errors models nanomaterial_notification attributes notified_to_eu_on]))
    end
  end

  def eu_notification_date_is_nil
    if notified_to_eu_on != nil
      errors.add(:notified_to_eu_on, I18n.t(:date_specified_but_eu_not_notified, scope: %i[activerecord errors models nanomaterial_notification attributes notified_to_eu_on]))
    end
  end

  def pdf_file_attached
    if !file.attached?
      errors.add(:file, I18n.t(:missing, scope: %i[activerecord errors models nanomaterial_notification attributes file]))
    elsif file.blob.content_type != "application/pdf"
      file.purge
      errors.add(:file, I18n.t(:must_be_a_pdf, scope: %i[activerecord errors models nanomaterial_notification attributes file]))
    end
  end

  def eu_not_notified?
    eu_notified == false
  end
end
