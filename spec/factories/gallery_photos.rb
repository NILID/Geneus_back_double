# frozen_string_literal: true

FactoryBot.define do
  factory :gallery_photo do
    user
    caption { 'Test shot' }

    after(:build) do |photo|
      photo.image.attach(
        io: StringIO.new(File.binread(Rails.root.join('spec/fixtures/files/1x1.png'))),
        filename: '1x1.png',
        content_type: 'image/png'
      )
    end
  end
end
