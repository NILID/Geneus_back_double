# frozen_string_literal: true

require 'yandex_disk/api_client'

module ActiveStorage
  class Service::YandexDiskService < Service
    def initialize(access_token:, folder: 'geneus', app_folder: true, **)
      @app_folder = ActiveModel::Type::Boolean.new.cast(app_folder)
      @folder = normalize_folder(folder, app_folder: @app_folder)
      @client = YandexDisk::ApiClient.new(access_token: access_token, app_folder: @app_folder)
      @client.ensure_folder!(storage_root_path) if folder_setup_required?
    end

    def upload(key, io, checksum: nil, **)
      @client.upload(io, disk_path(key))
    end

    def download(key, &block)
      @client.download(disk_path(key), &block)
    end

    def download_chunk(key, range)
      buffer = +''
      download(key) { |chunk| buffer << chunk }
      buffer.byteslice(range)
    end

    def delete(key)
      @client.delete(disk_path(key))
    rescue YandexDisk::ApiError => e
      raise unless e.status == 404
    end

    def delete_prefixed(prefix)
      # В приложении нет variant-обработки; префиксное удаление не требуется.
    end

    def exist?(key)
      @client.exists?(disk_path(key))
    end

    def url(key, expires_in:, filename:, content_type:, disposition:)
      @client.download_url(disk_path(key))
    end

    private

    def disk_path(key)
      YandexDisk::Path.build(app_folder: @app_folder, folder: @folder, key: key)
    end

    def storage_root_path
      @app_folder ? YandexDisk::Path.app_folder(@folder) : @folder
    end

    def folder_setup_required?
      return false if @app_folder && @folder.to_s.strip.empty?

      true
    end

    def normalize_folder(folder, app_folder:)
      path = folder.to_s.strip
      return '' if app_folder && path.empty?

      if app_folder
        path.delete_prefix('/').delete_suffix('/')
      else
        path = "/#{path}" unless path.start_with?('/')
        path.delete_suffix('/')
      end
    end
  end
end
