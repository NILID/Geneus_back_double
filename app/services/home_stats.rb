# frozen_string_literal: true

class HomeStats
  def self.call
    {
      people_count: Person.count,
      gallery_photos_count: GalleryPhoto.count
    }
  end
end
