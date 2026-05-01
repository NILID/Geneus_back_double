# frozen_string_literal: true

class GalleryPhoto < ApplicationRecord
  belongs_to :user

  has_one_attached :image

  ALLOWED_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  MAX_SIZE = 15.megabytes

  validate :image_must_exist
  validate :acceptable_image, if: -> { image.attached? }

  private

  def image_must_exist
    errors.add(:image, 'нужно выбрать файл') unless image.attached?
  end

  def acceptable_image
    unless ALLOWED_TYPES.include?(image.content_type)
      errors.add(:image, 'должен быть JPEG, PNG, WebP или GIF')
    end
    return if errors.any?

    errors.add(:image, 'слишком большой (максимум 15 МБ)') if image.byte_size > MAX_SIZE
  end
end
