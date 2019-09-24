class NanoElement < ApplicationRecord
  belongs_to :nano_material

  enum confirm_toxicology_notified: { yes: 'yes', no: 'no', not_sure: 'not sure' }

  def self.purposes
    %w(colorant preservative uv_filter other).freeze
  end

  validates :purposes, presence: true, on: :select_purposes
  validates :purposes, array: { presence: true, inclusion: { in: NanoElement.purposes } }

  def display_name
    [iupac_name, inci_name, inn_name, xan_name, cas_number, ec_number, einecs_number, elincs_number]
      .reject(&:blank?).join(', ')
  end

  def incomplete?
    purposes.nil?
  end

  def non_standard?
    purposes.present? && purposes.include?("other")
  end
end
