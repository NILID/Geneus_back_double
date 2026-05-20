# frozen_string_literal: true

module Geneus
  # Сервисы Active Storage по типу вложения (аватар / галерея).
  module ActiveStorageServices
    module_function

    def avatar
      resolve(:yandex_disk_avatars, :local_avatars)
    end

    def gallery
      resolve(:yandex_disk_photos, :local_photos)
    end

    def yandex_enabled?
      Rails.application.credentials.yandex_disk_token.present?
    end

    def resolve(yandex_service, local_service)
      return :test if Rails.env.test?

      yandex_enabled? ? yandex_service : local_service
    end
  end
end
