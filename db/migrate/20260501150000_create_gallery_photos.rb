# frozen_string_literal: true

class CreateGalleryPhotos < ActiveRecord::Migration[6.1]
  def change
    create_table :gallery_photos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :caption

      t.timestamps
    end
  end
end
