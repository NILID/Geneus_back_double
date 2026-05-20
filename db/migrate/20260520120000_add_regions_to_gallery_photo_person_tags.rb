# frozen_string_literal: true

class AddRegionsToGalleryPhotoPersonTags < ActiveRecord::Migration[6.1]
  def change
    change_table :gallery_photo_person_tags, bulk: true do |t|
      t.decimal :region_x, precision: 8, scale: 6
      t.decimal :region_y, precision: 8, scale: 6
      t.decimal :region_width, precision: 8, scale: 6
      t.decimal :region_height, precision: 8, scale: 6
    end
  end
end
