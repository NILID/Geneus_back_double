# frozen_string_literal: true

class AddTakenYearToGalleryPhotos < ActiveRecord::Migration[6.1]
  def change
    add_column :gallery_photos, :taken_year, :integer
  end
end
