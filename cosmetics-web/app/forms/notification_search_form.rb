class NotificationSearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  extend CategoryHelper

  FILTER_BY_DATE_EXACT = "by_date_exact".freeze
  FILTER_BY_DATE_RANGE = "by_date_range".freeze

  CATEGORIES = get_main_categories.map { |c| get_category_name(c) }

  attribute :q
  attribute :category

  attribute :date_filter

  attribute :date_from, :govuk_date
  attribute :date_to, :govuk_date
  attribute :date_exact, :govuk_date

  validates :date_exact,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true,
            if: :date_exact?

  validates :date_from,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true,
            if: :date_range?

  validates :date_to,
            presence: true,
            real_date: true,
            complete_date: true,
            if: :date_range?

  validate :date_from_lower_then_date_to

  def date_from_for_search
    return unless valid?

    return date_exact if date_exact?
    return date_from if date_range?
  end

  def date_to_for_search
    return unless valid?

    return date_exact if date_exact?
    return date_to if date_range?
  end

  def [](field)
    public_send(field.to_sym)
  end

  def date_exact?
    date_filter == FILTER_BY_DATE_EXACT && date_exact.present?
  end

  def date_range?
    date_filter == FILTER_BY_DATE_RANGE && (date_from.present? || date_to.present?)
  end

  def date_from_lower_then_date_to
    if date_range? && date_from.is_a?(Date) && date_to.is_a?(Date) && (date_from > date_to)
      errors.add(:date_from, :date_from_is_later_than_date_to)
    end
  end
end