class ApartmentDetail < ApplicationRecord
  belongs_to :property

  validates :property_id, presence: true
  validates :area_danji_id, :area_danji_name, presence: true
  validates :tran_type, inclusion: { in: %w[매매 전세 월세 신축분양] }
  validates :item_type, inclusion: { in: %w[아파트 빌라 오피스텔] }

  scope :by_danji, ->(danji_id) { where(area_danji_id: danji_id) }
  scope :by_tran_type, ->(type) { where(tran_type: type) }
  scope :by_item_type, ->(type) { where(item_type: type) }
  scope :price_range, -> { where(is_price_range: true) }
  scope :exact_price, -> { where(is_price_range: false) }

  def room_title_korean
    room_type_title&.dig('ko') || room_type_title&.values&.first
  end

  def size_in_pyeong
    return nil unless size_contract_m2

    (size_contract_m2 / 3.3058).round(1)
  end

  def danji_location
    "#{area_danji_name} #{dong}".strip
  end
end