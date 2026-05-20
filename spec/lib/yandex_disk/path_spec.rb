# frozen_string_literal: true

require 'rails_helper'
require 'yandex_disk/path'

RSpec.describe YandexDisk::Path do
  describe '.build' do
    it 'builds app folder paths' do
      expect(described_class.build(app_folder: true, folder: 'geneus', key: 'blobs/x'))
        .to eq('app:/geneus/blobs/x')
    end

    it 'builds nested app subfolders for avatars and photos' do
      expect(described_class.build(app_folder: true, folder: 'geneus/avatars', key: 'blobs/x'))
        .to eq('app:/geneus/avatars/blobs/x')
      expect(described_class.build(app_folder: true, folder: 'photos', key: 'blobs/y'))
        .to eq('app:/photos/blobs/y')
    end

    it 'builds app root path when folder is empty' do
      expect(described_class.build(app_folder: true, folder: '', key: 'blobs/x'))
        .to eq('app:/blobs/x')
    end

    it 'builds full disk paths in legacy mode' do
      expect(described_class.build(app_folder: false, folder: 'geneus', key: 'blobs/x'))
        .to eq('/geneus/blobs/x')
    end

    it 'rejects path traversal in app paths' do
      expect do
        described_class.app_path('geneus', '../outside')
      end.to raise_error(ArgumentError, /invalid app folder path/)
    end
  end
end
