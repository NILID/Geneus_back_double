# frozen_string_literal: true

class GalleryPhotoPersonTag < ApplicationRecord
  audited

  belongs_to :gallery_photo
  belongs_to :person

  validates :person_id, uniqueness: { scope: :gallery_photo_id }
  validate :region_fields_consistent

  def region?
    region_x.present? && region_y.present? && region_width.present? && region_height.present?
  end

  private

  def region_fields_consistent
    fields = [region_x, region_y, region_width, region_height]
    return if fields.all?(&:blank?)

    unless fields.all?(&:present?)
      errors.add(:base, 'координаты области должны быть указаны полностью или не указаны')
      return
    end

    x = region_x.to_f
    y = region_y.to_f
    w = region_width.to_f
    h = region_height.to_f

    unless x.between?(0, 1) && y.between?(0, 1) && w.positive? && h.positive? && (x + w) <= 1.000001 && (y + h) <= 1.000001
      errors.add(:base, 'координаты области должны быть в диапазоне 0–1')
    end
  end
end
