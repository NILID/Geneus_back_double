# frozen_string_literal: true

require 'rails_helper'
require 'active_storage/service/yandex_disk_service'

RSpec.describe ActiveStorage::Service::YandexDiskService do
  let(:api_client) { instance_double(YandexDisk::ApiClient) }

  before do
    allow(YandexDisk::ApiClient).to receive(:new).and_return(api_client)
    allow(api_client).to receive(:ensure_folder!)
    allow(api_client).to receive(:upload)
    allow(api_client).to receive(:download_url)
  end

  context 'app folder mode (default)' do
    subject(:service) do
      described_class.new(access_token: 'token', folder: 'geneus', app_folder: true)
    end

    it 'creates client in app_folder mode' do
      service
      expect(YandexDisk::ApiClient).to have_received(:new).with(
        access_token: 'token',
        app_folder: true
      )
    end

    it 'ensures subfolder under app:/' do
      service
      expect(api_client).to have_received(:ensure_folder!).with('app:/geneus')
    end

    it 'uploads under app:/' do
      io = StringIO.new('data')
      service.upload('blobs/abc', io)
      expect(api_client).to have_received(:upload).with(io, 'app:/geneus/blobs/abc')
    end

    it 'uploads avatars under app:/geneus/avatars when folder is nested' do
      avatars = described_class.new(access_token: 'token', folder: 'geneus/avatars', app_folder: true)
      io = StringIO.new('data')
      avatars.upload('blobs/abc', io)
      expect(api_client).to have_received(:upload).with(io, 'app:/geneus/avatars/blobs/abc')
    end
  end

  context 'legacy full disk mode' do
    subject(:service) do
      described_class.new(access_token: 'token', folder: 'geneus', app_folder: false)
    end

    it 'creates client without app_folder flag' do
      service
      expect(YandexDisk::ApiClient).to have_received(:new).with(
        access_token: 'token',
        app_folder: false
      )
    end

    it 'ensures absolute folder' do
      service
      expect(api_client).to have_received(:ensure_folder!).with('/geneus')
    end

    it 'uploads to absolute path' do
      io = StringIO.new('data')
      service.upload('blobs/abc', io)
      expect(api_client).to have_received(:upload).with(io, '/geneus/blobs/abc')
    end
  end
end
