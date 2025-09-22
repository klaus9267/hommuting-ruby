class PropertyImage < ApplicationRecord
  belongs_to :property

  validates :property_id, presence: true
  validates :thumbnail_url, presence: true, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])

  validate :image_urls_format

  before_save :clean_image_urls

  def has_images?
    image_urls.present? && image_urls.any?
  end

  def image_count
    image_urls&.size || 0
  end

  private

  def image_urls_format
    return if image_urls.blank?

    image_urls.each do |url|
      unless url.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))
        errors.add(:image_urls, "Invalid URL format: #{url}")
      end
    end
  end

  def clean_image_urls
    self.image_urls = image_urls&.compact&.uniq || []
  end
end