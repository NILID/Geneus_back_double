# frozen_string_literal: true

module Geneus
  # Публичный URL вложения для SPA (<img src=...>).
  #
  # `rails_blob_path` в Rails всегда указывает на /blobs/redirect/… (302 на хранилище),
  # даже при `config.active_storage.resolve_model_to_route = :rails_storage_proxy`.
  # Proxy нужен, чтобы браузер не ходил на downloader.disk.yandex.ru (SameSite, CORP).
  module BlobPublicPath
    module_function

    def path(attached, only_path: true)
      return nil unless attached.attached?

      Rails.application.routes.url_helpers.rails_storage_proxy_path(
        attached.blob,
        only_path: only_path
      )
    end

    def url(attached, request:)
      return nil if request.blank?

      path = path(attached)
      return nil if path.blank?

      request.base_url + path
    end
  end
end
