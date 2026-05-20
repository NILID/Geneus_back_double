# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Geneus::ActiveStorageServices do
  around do |example|
    previous = ENV['YANDEX_DISK_TOKEN']
    ENV.delete('YANDEX_DISK_TOKEN')
    example.run
  ensure
    if previous
      ENV['YANDEX_DISK_TOKEN'] = previous
    else
      ENV.delete('YANDEX_DISK_TOKEN')
    end
  end

  describe '.avatar' do
    it 'uses test service in test env' do
      expect(described_class.avatar).to eq(:test)
    end
  end

  describe '.gallery' do
    it 'uses test service in test env' do
      expect(described_class.gallery).to eq(:test)
    end
  end

  describe 'service resolution (development-like)' do
    it 'maps avatars and photos to separate local/yandex services' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))

      expect(described_class.avatar).to eq(:local_avatars)
      expect(described_class.gallery).to eq(:local_photos)

      ENV['YANDEX_DISK_TOKEN'] = 'secret'
      expect(described_class.avatar).to eq(:yandex_disk_avatars)
      expect(described_class.gallery).to eq(:yandex_disk_photos)
    end
  end
end
