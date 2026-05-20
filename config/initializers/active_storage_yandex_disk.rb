# frozen_string_literal: true

# Подгрузка кастомного сервиса до первого обращения к ActiveStorage::Blob.
Rails.application.config.to_prepare do
  require_dependency 'active_storage/service/yandex_disk_service'
end
