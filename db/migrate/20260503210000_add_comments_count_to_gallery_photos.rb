# frozen_string_literal: true

class AddCommentsCountToGalleryPhotos < ActiveRecord::Migration[6.1]
  def change
    add_column :gallery_photos, :comments_count, :integer, null: false, default: 0
  end
end
