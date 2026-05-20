# frozen_string_literal: true

require 'rails_helper'
require 'yandex_disk/api_client'

RSpec.describe YandexDisk::ApiClient do
  let(:token) { 'test-oauth-token' }
  let(:client) { described_class.new(access_token: token) }

  describe '#initialize' do
    it 'requires access_token' do
      expect { described_class.new(access_token: '') }.to raise_error(ArgumentError, /access_token/)
    end
  end

  describe 'app folder mode' do
    let(:client) { described_class.new(access_token: token, app_folder: true) }

    it 'rejects paths outside app:/' do
      expect { client.upload(StringIO.new('x'), '/geneus/file') }
        .to raise_error(ArgumentError, /invalid app folder path/)
    end
  end

  describe '#upload' do
    it 'requests upload href and PUTs file body' do
      upload_href = 'https://uploader.example/upload-target/abc'
      stub_request(:get, %r{cloud-api\.yandex\.net/v1/disk/resources/upload})
        .with(headers: { 'Authorization' => "OAuth #{token}" })
        .to_return(
          status: 200,
          body: { href: upload_href, method: 'PUT', templated: false }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      stub_request(:put, upload_href).to_return(status: 201)

      io = StringIO.new('image-bytes')
      client.upload(io, '/geneus/test-key')

      expect(WebMock).to have_requested(:put, upload_href).with(body: 'image-bytes')
    end
  end

  describe '#exists?' do
    it 'returns true when resource is found' do
      stub_request(:get, %r{cloud-api\.yandex\.net/v1/disk/resources\?})
        .to_return(status: 200, body: { name: 'file' }.to_json)

      expect(client.exists?('/geneus/x')).to be true
    end

    it 'returns false on 404' do
      stub_request(:get, %r{cloud-api\.yandex\.net/v1/disk/resources\?})
        .to_return(status: 404, body: { error: 'NotFound' }.to_json)

      expect(client.exists?('/geneus/missing')).to be false
    end
  end

  describe '#download' do
    it 'follows redirect from temporary download href' do
      download_href = 'https://downloader.example/file'
      file_href = 'https://storage.example/actual-file'
      stub_request(:get, %r{cloud-api\.yandex\.net/v1/disk/resources/download})
        .to_return(
          status: 200,
          body: { href: download_href, method: 'GET', templated: false }.to_json
        )
      stub_request(:get, download_href).to_return(status: 302, headers: { 'Location' => file_href })
      stub_request(:get, file_href).to_return(status: 200, body: 'image-bytes')

      chunks = []
      client.download('/geneus/test-key') { |chunk| chunks << chunk }

      expect(chunks.join).to eq('image-bytes')
      expect(WebMock).to have_requested(:get, file_href).once
    end
  end

  describe '#download_url' do
    it 'caches download href' do
      href = 'https://downloader.example/file'
      stub_request(:get, %r{cloud-api\.yandex\.net/v1/disk/resources/download})
        .to_return(
          status: 200,
          body: { href: href, method: 'GET', templated: false }.to_json
        )

      Rails.cache.clear
      expect(client.download_url('/geneus/a')).to eq(href)
      expect(client.download_url('/geneus/a')).to eq(href)
      expect(WebMock).to have_requested(:get, %r{resources/download}).once
    end
  end
end
