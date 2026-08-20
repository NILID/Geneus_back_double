# frozen_string_literal: true

module AdminDigest
  AUDITABLE_TYPES = %w[Person GalleryPhoto GalleryPhotoPersonTag PersonFact].freeze
  LOOKBACK = 1.month
  PHOTO_UPDATE_FIELDS = %w[caption taken_year].freeze

  Period = Struct.new(:from, :to, keyword_init: true)
  Counts = Struct.new(
    :birthdays,
    :new_people,
    :updated_people,
    :photos,
    :photo_tags,
    :facts,
    keyword_init: true
  )
  Payload = Struct.new(
    :period,
    :generated_at,
    :frontend_base,
    :birthdays,
    :new_people,
    :updated_people,
    :photos,
    :photo_tags,
    :facts,
    :counts,
    keyword_init: true
  )
  BirthdayItem = Struct.new(
    :person,
    :name,
    :days_offset,
    :occurrence_date,
    :age,
    :url,
    :avatar_url,
    keyword_init: true
  )
  PersonCreateItem = Struct.new(
    :person,
    :name,
    :occurred_at,
    :url,
    :avatar_url,
    :actor_email,
    keyword_init: true
  )
  PersonUpdateItem = Struct.new(
    :person,
    :name,
    :occurred_at,
    :url,
    :avatar_url,
    :actor_email,
    :changes,
    keyword_init: true
  )
  PhotoItem = Struct.new(
    :photo,
    :caption,
    :occurred_at,
    :url,
    :image_url,
    :actor_email,
    :action,
    keyword_init: true
  )
  PhotoTagItem = Struct.new(
    :person_name,
    :photo_caption,
    :occurred_at,
    :person_url,
    :photo_url,
    :image_url,
    :actor_email,
    :action,
    keyword_init: true
  )
  FactItem = Struct.new(
    :person_name,
    :body,
    :occurred_at,
    :url,
    :actor_email,
    :action,
    keyword_init: true
  )
  FieldChange = Struct.new(:label, :old_value, :new_value, keyword_init: true)
end
