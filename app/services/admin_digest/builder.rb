# frozen_string_literal: true

module AdminDigest
  class Builder
    def self.call(now: Time.current)
      new(now: now).call
    end

    def initialize(now: Time.current)
      @now = now
      @today = now.in_time_zone.to_date
      @from = @now - LOOKBACK
    end

    def call
      audits = load_audits
      users_by_id = users_by_id_for(audits)
      people_by_id, photos_by_id, tags_by_id, facts_by_id = load_records(audits)

      birthdays = birthday_items
      new_people = person_create_items(audits, people_by_id, users_by_id)
      updated_people = person_update_items(audits, people_by_id, users_by_id)
      photos = photo_items(audits, photos_by_id, users_by_id)
      photo_tags = photo_tag_items(audits, tags_by_id, users_by_id)
      facts = fact_items(audits, facts_by_id, users_by_id)

      Payload.new(
        period: Period.new(from: @from, to: @now),
        generated_at: @now,
        frontend_base: Geneus::AppUrls.frontend_base,
        birthdays: birthdays,
        new_people: new_people,
        updated_people: updated_people,
        photos: photos,
        photo_tags: photo_tags,
        facts: facts,
        counts: Counts.new(
          birthdays: birthdays.size,
          new_people: new_people.size,
          updated_people: updated_people.size,
          photos: photos.size,
          photo_tags: photo_tags.size,
          facts: facts.size
        )
      )
    end

    private

    def load_audits
      Audited::Audit
        .where(auditable_type: AUDITABLE_TYPES)
        .where(action: %w[create update])
        .where('audits.created_at >= ?', @from)
        .where('audits.created_at <= ?', @now)
        .order(created_at: :desc)
        .to_a
    end

    def users_by_id_for(audits)
      ids = audits.map(&:user_id).compact.uniq
      User.where(id: ids).index_by(&:id)
    end

    def load_records(audits)
      grouped = audits.group_by(&:auditable_type)
      people_ids = ids_for(grouped, 'Person')
      photo_ids = ids_for(grouped, 'GalleryPhoto')
      tag_ids = ids_for(grouped, 'GalleryPhotoPersonTag')
      fact_ids = ids_for(grouped, 'PersonFact')

      people = Person.where(id: people_ids).includes(avatar_attachment: :blob).index_by(&:id)
      photos = GalleryPhoto.where(id: photo_ids).includes(:user, image_attachment: :blob).index_by(&:id)
      tags = GalleryPhotoPersonTag
             .where(id: tag_ids)
             .includes(:person, gallery_photo: { image_attachment: :blob })
             .index_by(&:id)
      facts = PersonFact.where(id: fact_ids).includes(:person, :user).index_by(&:id)

      extra_people_ids = tags.values.map(&:person_id) + facts.values.map(&:person_id) - people.keys
      if extra_people_ids.any?
        people.merge!(Person.where(id: extra_people_ids).includes(avatar_attachment: :blob).index_by(&:id))
      end

      extra_photo_ids = tags.values.map(&:gallery_photo_id) - photos.keys
      if extra_photo_ids.any?
        photos.merge!(
          GalleryPhoto.where(id: extra_photo_ids).includes(image_attachment: :blob).index_by(&:id)
        )
      end

      [people, photos, tags, facts]
    end

    def ids_for(grouped, type)
      Array(grouped[type]).map(&:auditable_id).uniq
    end

    def birthday_items
      until_date = @today >> 1
      days_future = (until_date - @today).to_i
      rows = PersonUpcomingBirthdays.call(
        reference_date: @today,
        days_past: 0,
        days_future: days_future,
        living_only: true
      )
      rows.map do |row|
        BirthdayItem.new(
          person: row.person,
          name: Format.person_name(row.person),
          days_offset: row.days_offset,
          occurrence_date: row.occurrence_date,
          age: row.age,
          url: Geneus::AppUrls.person_url(row.person),
          avatar_url: Geneus::BlobPublicPath.absolute_url(row.person.avatar)
        )
      end
    end

    def person_create_items(audits, people_by_id, users_by_id)
      audits.filter_map do |audit|
        next unless audit.auditable_type == 'Person' && audit.action == 'create'

        person = people_by_id[audit.auditable_id]
        next if person.blank?

        PersonCreateItem.new(
          person: person,
          name: Format.person_name(person),
          occurred_at: audit.created_at,
          url: Geneus::AppUrls.person_url(person),
          avatar_url: Geneus::BlobPublicPath.absolute_url(person.avatar),
          actor_email: users_by_id[audit.user_id]&.email
        )
      end
    end

    def person_update_items(audits, people_by_id, users_by_id)
      audits.filter_map do |audit|
        next unless audit.auditable_type == 'Person' && audit.action == 'update'

        person = people_by_id[audit.auditable_id]
        next if person.blank?

        changes = Format.person_changes(audit.audited_changes)
        next if changes.blank?

        PersonUpdateItem.new(
          person: person,
          name: Format.person_name(person),
          occurred_at: audit.created_at,
          url: Geneus::AppUrls.person_url(person),
          avatar_url: Geneus::BlobPublicPath.absolute_url(person.avatar),
          actor_email: users_by_id[audit.user_id]&.email,
          changes: changes
        )
      end
    end

    def photo_items(audits, photos_by_id, users_by_id)
      audits.filter_map do |audit|
        next unless audit.auditable_type == 'GalleryPhoto' && audit.action == 'create'

        photo = photos_by_id[audit.auditable_id]
        next if photo.blank?

        PhotoItem.new(
          photo: photo,
          caption: Format.photo_caption(photo),
          occurred_at: audit.created_at,
          url: Geneus::AppUrls.media_url,
          image_url: Geneus::BlobPublicPath.absolute_url(photo.image),
          actor_email: users_by_id[audit.user_id]&.email,
          action: audit.action
        )
      end
    end

    def photo_tag_items(audits, tags_by_id, users_by_id)
      audits.filter_map do |audit|
        next unless audit.auditable_type == 'GalleryPhotoPersonTag'
        next unless %w[create update].include?(audit.action)

        tag = tags_by_id[audit.auditable_id]
        next if tag.blank?

        person = tag.person
        photo = tag.gallery_photo
        next if person.blank? || photo.blank?

        PhotoTagItem.new(
          person_name: Format.person_name(person),
          photo_caption: Format.photo_caption(photo),
          occurred_at: audit.created_at,
          person_url: Geneus::AppUrls.person_url(person),
          photo_url: Geneus::AppUrls.media_url,
          image_url: Geneus::BlobPublicPath.absolute_url(photo.image),
          actor_email: users_by_id[audit.user_id]&.email,
          action: audit.action
        )
      end
    end

    def fact_items(audits, facts_by_id, users_by_id)
      audits.filter_map do |audit|
        next unless audit.auditable_type == 'PersonFact'
        next unless %w[create update].include?(audit.action)

        fact = facts_by_id[audit.auditable_id]
        next if fact.blank?

        person = fact.person
        next if person.blank?

        FactItem.new(
          person_name: Format.person_name(person),
          body: fact.body.to_s.strip.truncate(400),
          occurred_at: audit.created_at,
          url: Geneus::AppUrls.person_facts_url(person),
          actor_email: users_by_id[audit.user_id]&.email,
          action: audit.action
        )
      end
    end
  end
end
