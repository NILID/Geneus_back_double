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

      expect(payload.photo_tags.map(&:person_name)).to include('New Relative')
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
