# frozen_string_literal: true

class GalleryPhotoPersonTag < ApplicationRecord
  belongs_to :gallery_photo
  belongs_to :person

  validates :person_id, uniqueness: { scope: :gallery_photo_id }
end
