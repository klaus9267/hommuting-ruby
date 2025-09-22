class Address < ApplicationRecord
  belongs_to :property

  validates :property_id, presence: true

  scope :by_local2, ->(local2) { where(local2: local2) }
  scope :by_region, ->(region) { where("local1 ILIKE ? OR local2 ILIKE ?", "%#{region}%", "%#{region}%") }

  def full_location
    [local1, local2, local3].compact.join(' ')
  end

  def short_location
    [local2, local3].compact.join(' ')
  end
end