# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Geneus::BlobPublicPath do
  let(:person) { create(:person) }

  before do
    person.avatar.attach(
      io: File.open(Rails.root.join('spec/fixtures/files/1x1.png')),
      filename: '1x1.png',
      content_type: 'image/png'
    )
  end

  describe '.path' do
    it 'uses Active Storage proxy route, not redirect' do
      path = described_class.path(person.avatar)
      expect(path).to include('/rails/active_storage/blobs/proxy/')
      expect(path).not_to include('/blobs/redirect/')
    end
  end
end
