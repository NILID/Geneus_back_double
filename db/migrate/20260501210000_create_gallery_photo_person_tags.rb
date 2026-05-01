# frozen_string_literal: true

class CreateGalleryPhotoPersonTags < ActiveRecord::Migration[6.1]
  def change
    create_table :gallery_photo_person_tags do |t|
      t.references :gallery_photo, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true

      t.timestamps
    end

    add_index :gallery_photo_person_tags,
              %i[gallery_photo_id person_id],
              unique: true,
              name: 'index_gallery_photo_person_tags_unique_pair'
  end
end
