# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

require_relative 'path'

module YandexDisk
  class ApiError < StandardError
    attr_reader :status, :body

    def initialize(message, status: nil, body: nil)
      super(message)
      @status = status
      @body = body
    end
  end

  # HTTP-клиент REST API Яндекс.Диска (cloud-api.yandex.net).
  # Документация: https://yandex.com/dev/disk-api/doc/en/
  class ApiClient
    API_BASE = 'https://cloud-api.yandex.net/v1/disk'

    def initialize(access_token:, app_folder: false)
      @access_token = access_token.to_s
      @app_folder = app_folder
      raise ArgumentError, 'access_token is required' if @access_token.empty?
    end

    def upload(io, disk_path, overwrite: true)
      assert_allowed_path!(disk_path)
      upload_href = fetch_upload_href(disk_path, overwrite: overwrite)
      put_io(upload_href, io)
    end

    def download(disk_path, &block)
      assert_allowed_path!(disk_path)
      href = fetch_download_href(disk_path)
      get_stream(href, &block)
    end

    def download_url(disk_path)
      assert_allowed_path!(disk_path)
      Rails.cache.fetch(cache_key(disk_path), expires_in: 25.minutes) do
        fetch_download_href(disk_path)
      end
    end

    def delete(disk_path, permanently: true)
      assert_allowed_path!(disk_path)
      uri = api_uri('/resources', path: disk_path, permanently: permanently)
      request(:delete, uri)
      nil
    end

    def exists?(disk_path)
      assert_allowed_path!(disk_path)
      uri = api_uri('/resources', path: disk_path, fields: 'name')
      request(:get, uri)
      true
    rescue ApiError => e
      return false if e.status == 404

      raise
    end

    def mkdir(disk_path)
      assert_allowed_path!(disk_path)
      uri = api_uri('/resources', path: disk_path)
      request(:put, uri)
      true
    rescue ApiError => e
      return true if e.status == 409

      raise
    end

    def ensure_folder!(disk_path)
      assert_allowed_path!(disk_path)
      return if exists?(disk_path)

      parent = nested_parent_path(disk_path)
      ensure_folder!(parent) if parent

      mkdir(disk_path)
    end

    private

    def nested_parent_path(disk_path)
      path = disk_path.to_s
      return nil unless path.include?('/')

      parent = path.sub(%r{/[^/]+\z}, '')
      return nil if parent.blank?

      if path.start_with?(Path::APP_PREFIX)
        rest = path.delete_prefix(Path::APP_PREFIX)
        return nil unless rest.include?('/')
      end

      parent
    end

    def assert_allowed_path!(disk_path)
      path = disk_path.to_s
      if @app_folder
        Path.validate_app_path!(path)
      elsif path.start_with?(Path::APP_PREFIX)
        raise ArgumentError, 'app:/ paths require app_folder mode (YANDEX_DISK_APP_FOLDER=true)'
      end
    end

    def cache_key(disk_path)
      "yandex_disk/download/#{Digest::SHA256.hexdigest(disk_path)}"
    end

    def fetch_upload_href(disk_path, overwrite:)
      uri = api_uri('/resources/upload', path: disk_path, overwrite: overwrite)
      body = request(:get, uri)
      body.fetch('href')
    end

    def fetch_download_href(disk_path)
      uri = api_uri('/resources/download', path: disk_path)
      body = request(:get, uri)
      body.fetch('href')
    end

    def put_io(href, io)
      uri = URI(href)
      io.rewind if io.respond_to?(:rewind)

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Put.new(uri)
        request.body = io.read
        response = http.request(request)
        unless response.is_a?(Net::HTTPSuccess)
          raise ApiError, "Yandex Disk upload failed (#{response.code})"
        end
      end
    end

    def get_stream(href, &block)
      uri = URI(href)
      max_redirects = 10

      max_redirects.times do
        redirected = false

        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          request = Net::HTTP::Get.new(uri)
          http.request(request) do |response|
            if response.is_a?(Net::HTTPRedirection)
              location = response['location']
              if location.blank?
                raise ApiError, "Yandex Disk download redirect without Location (#{response.code})"
              end

              uri = URI(location)
              redirected = true
              next
            end

            unless response.is_a?(Net::HTTPSuccess)
              raise ApiError, "Yandex Disk download failed (#{response.code})"
            end

            return response.read_body unless block

            response.read_body(&block)
          end
        end

        return if block_given? && !redirected

        raise ApiError, 'Yandex Disk download failed: too many redirects' unless redirected
      end

      raise ApiError, 'Yandex Disk download failed: too many redirects'
    end

    def api_uri(path, params = {})
      query = params.map { |key, value| "#{key}=#{encode_param(value)}" }.join('&')
      URI("#{API_BASE}#{path}?#{query}")
    end

    def encode_param(value)
      ERB::Util.url_encode(value.to_s)
    end

    def request(method, uri)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        req = case method
              when :get then Net::HTTP::Get.new(uri)
              when :put then Net::HTTP::Put.new(uri)
              when :delete then Net::HTTP::Delete.new(uri)
              else raise ArgumentError, "unsupported method: #{method}"
              end
        req['Authorization'] = "OAuth #{@access_token}"
        req['Accept'] = 'application/json'

        response = http.request(req)
        parse_response(response)
      end
    end

    def parse_response(response)
      if response.is_a?(Net::HTTPSuccess)
        return {} if response.body.nil? || response.body.empty?

        JSON.parse(response.body)
      else
        raise ApiError.new(
          "Yandex Disk API error (#{response.code})",
          status: response.code.to_i,
          body: response.body
        )
      end
    end
  end
end
