# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminDigest::Builder do
  include ActiveSupport::Testing::TimeHelpers

  let(:actor) { create(:user, :moderator, email: "mod-#{SecureRandom.hex(6)}@example.com") }

  def living_person(attrs = {})
    create(
      :person,
      {
        first_name: 'Anna',
        last_name: 'Ivanova',
        gender: 'female',
        date_of_death: nil
      }.merge(attrs)
    )
  end

  it 'collects last-month updates, diffs, and living birthdays for the next month' do
    travel_to Time.zone.parse('2026-08-20 12:00:00') do
      new_person = living_person(first_name: 'New', last_name: 'Relative')
      updated = living_person(first_name: 'Old', last_name: 'Name', bio: 'was')
      Audited.store[:audited_user] = actor
      begin
        updated.update!(last_name: 'Changed', bio: 'now')
      ensure
        Audited.store[:audited_user] = nil
      end

      birthday_soon = living_person(
        first_name: 'Soon',
        last_name: 'Birthday',
        date_of_birth: Date.new(1990, 9, 1)
      )
      living_person(
        first_name: 'Far',
        last_name: 'Away',
        date_of_birth: Date.new(1990, 10, 20)
      )
      living_person(
        first_name: 'Dead',
        last_name: 'Relative',
        date_of_birth: Date.new(1950, 9, 1),
        date_of_death: Date.new(2010, 1, 1)
      )
      living_person(
        first_name: 'Year',
        last_name: 'Only',
        date_of_birth: Date.new(1990, 9, 1),
        birth_date_year_only: true
      )

      photo = nil
      fact = nil
      Audited.store[:audited_user] = actor
      begin
        photo = create(:gallery_photo, user: actor, caption: 'Family picnic')
        photo.gallery_photo_person_tags.create!(person: new_person)
        fact = create(:person_fact, person: new_person, user: actor, body: 'Любил чай.')
      ensure
        Audited.store[:audited_user] = nil
      end

      payload = described_class.call

      expect(payload.counts.new_people).to be >= 1
      expect(payload.new_people.map(&:name)).to include('New Relative')

      update = payload.updated_people.find { |item| item.name == 'Old Changed' }
      expect(update).to be_present
      labels = update.changes.map(&:label)
      expect(labels).to include('Фамилия', 'Биография')
      last_name_change = update.changes.find { |c| c.label == 'Фамилия' }
      expect(last_name_change.old_value).to eq('Name')
      expect(last_name_change.new_value).to eq('Changed')
      expect(update.actor_email).to eq(actor.email)

      expect(payload.photos.map(&:caption)).to include('Family picnic')
      expect(payload.photos.first.image_url).to include('/rails/active_storage/blobs/proxy/')

      expect(payload.photo_tags.flat_map { |item| item.people.map(&:name) }).to include('New Relative')
      expect(payload.facts.map(&:body)).to include('Любил чай.')

      birthday_names = payload.birthdays.map(&:name)
      expect(birthday_names).to include('Soon Birthday')
      expect(birthday_names).not_to include('Far Away')
      expect(birthday_names).not_to include('Dead Relative')
      expect(birthday_names).not_to include('Year Only')

      soon = payload.birthdays.find { |item| item.name == 'Soon Birthday' }
      expect(soon.age).to eq(36)
      expect(soon.url).to include('/person/')
      expect(photo).to be_present
      expect(fact).to be_present
      expect(birthday_soon).to be_present
    end
  end

  it 'includes only uploaded photos, not caption or year updates' do
    travel_to Time.zone.parse('2026-08-20 12:00:00') do
      Audited.store[:audited_user] = actor
      begin
        create(:gallery_photo, user: actor, caption: 'New scan')
        updated = create(:gallery_photo, user: actor, caption: 'Old caption', taken_year: 1990)
        updated.update!(caption: 'New caption', taken_year: 1991)
      ensure
        Audited.store[:audited_user] = nil
      end

      photos = described_class.call.photos
      captions = photos.map(&:caption)
      expect(captions).to include('New scan', 'New caption')
      expect(captions.count { |c| c == 'New caption' }).to eq(1)
      expect(photos.map(&:action).uniq).to eq(['create'])
    end
  end

  it 'leaves photo captions blank instead of using a placeholder' do
    travel_to Time.zone.parse('2026-08-20 12:00:00') do
      person = living_person(first_name: 'No', last_name: 'Caption')
      Audited.store[:audited_user] = actor
      begin
        photo = create(:gallery_photo, user: actor, caption: '')
        photo.gallery_photo_person_tags.create!(person: person)
      ensure
        Audited.store[:audited_user] = nil
      end

      payload = described_class.call
      expect(payload.photos.map(&:caption)).to all(be_nil)
      expect(payload.photo_tags.map(&:photo_caption)).to all(be_nil)
    end
  end

  it 'omits birth and death coordinates from person change diffs' do
    travel_to Time.zone.parse('2026-08-20 12:00:00') do
      person = living_person(first_name: 'Map', last_name: 'Pin', location_of_birth: 'Москва')
      Audited.store[:audited_user] = actor
      begin
        person.update!(
          last_name: 'Moved',
          location_of_birth: 'Петербург',
          birth_latitude: 59.93,
          birth_longitude: 30.33,
          death_latitude: 55.75,
          death_longitude: 37.61
        )
      ensure
        Audited.store[:audited_user] = nil
      end

      update = described_class.call.updated_people.find { |item| item.name == 'Map Moved' }
      expect(update).to be_present
      labels = update.changes.map(&:label)
      expect(labels).to include('Фамилия', 'Место рождения')
      expect(labels).not_to include('Широта рождения', 'Долгота рождения', 'Широта смерти', 'Долгота смерти')
    end
  end

  it 'does not list a person update that only changed coordinates' do
    travel_to Time.zone.parse('2026-08-20 12:00:00') do
      person = living_person(first_name: 'Only', last_name: 'Coords')
      Audited.store[:audited_user] = actor
      begin
        person.update!(birth_latitude: 59.93, birth_longitude: 30.33)
      ensure
        Audited.store[:audited_user] = nil
      end

      expect(described_class.call.updated_people.map(&:name)).not_to include('Only Coords')
    end
  end

  it 'omits year-only date flags from person change diffs' do
    travel_to Time.zone.parse('2026-08-20 12:00:00') do
      person = living_person(
        first_name: 'Year',
        last_name: 'Flag',
        date_of_birth: Date.new(1950, 1, 1),
        date_of_death: Date.new(2010, 6, 1)
      )
      Audited.store[:audited_user] = actor
      begin
        person.update!(
          last_name: 'Shown',
          birth_date_year_only: true,
          death_date_year_only: true
        )
      ensure
        Audited.store[:audited_user] = nil
      end

      update = described_class.call.updated_people.find { |item| item.name == 'Year Shown' }
      expect(update).to be_present
      labels = update.changes.map(&:label)
      expect(labels).to include('Фамилия')
      expect(labels).not_to include('В дате рождения только год', 'В дате смерти только год')
    end
  end

  it 'does not list a person update that only changed year-only flags' do
    travel_to Time.zone.parse('2026-08-20 12:00:00') do
      person = living_person(first_name: 'Only', last_name: 'YearFlag', date_of_birth: Date.new(1960, 5, 1))
      Audited.store[:audited_user] = actor
      begin
        person.update!(birth_date_year_only: true)
      ensure
        Audited.store[:audited_user] = nil
      end

      expect(described_class.call.updated_people.map(&:name)).not_to include('Only YearFlag')
    end
  end

  it 'groups photo tags by photo and lists tagged people without dates' do
    travel_to Time.zone.parse('2026-08-20 12:00:00') do
      anna = living_person(first_name: 'Anna', last_name: 'Tagged')
      boris = living_person(first_name: 'Boris', last_name: 'Tagged')
      clara = living_person(first_name: 'Clara', last_name: 'Tagged')
      picnic = nil
      portrait = nil
      Audited.store[:audited_user] = actor
      begin
        picnic = create(:gallery_photo, user: actor, caption: 'Picnic')
        portrait = create(:gallery_photo, user: actor, caption: 'Portrait')
        picnic.gallery_photo_person_tags.create!(person: anna)
        picnic.gallery_photo_person_tags.create!(person: boris)
        portrait.gallery_photo_person_tags.create!(person: clara)
      ensure
        Audited.store[:audited_user] = nil
      end

      items = described_class.call.photo_tags
      expect(items.size).to eq(2)

      picnic_item = items.find { |item| item.photo_caption == 'Picnic' }
      expect(picnic_item.people.map(&:name)).to eq(['Anna Tagged', 'Boris Tagged'])

      portrait_item = items.find { |item| item.photo_caption == 'Portrait' }
      expect(portrait_item.people.map(&:name)).to eq(['Clara Tagged'])
    end
  end

  it 'does not include updates older than a month' do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      living_person(first_name: 'Ancient', last_name: 'Record')
    end

    travel_to Time.zone.parse('2026-08-20 12:00:00') do
      payload = described_class.call
      expect(payload.new_people.map(&:name)).not_to include('Ancient Record')
    end
  end
end
