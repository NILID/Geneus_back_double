# frozen_string_literal: true

module YandexDisk
  # Сборка путей для API Диска.
  # app_folder: только app:/… (OAuth cloud_api:disk.app_folder).
  # full_disk: абсолютные пути /folder/… (legacy, полный доступ к Диску).
  module Path
    APP_PREFIX = 'app:/'

    module_function

    def build(app_folder:, folder:, key:)
      key = key.to_s.delete_prefix('/')
      raise ArgumentError, 'key is required' if key.empty?

      if app_folder
        app_path(folder, key)
      else
        disk_path(folder, key)
      end
    end

    def app_folder(folder = '')
      segment = folder.to_s.strip.delete_prefix('/').delete_suffix('/')
      path = segment.empty? ? 'app:/' : "#{APP_PREFIX}#{segment}"
      validate_app_path!(path)
      path
    end

    def app_path(folder, key)
      segment = folder.to_s.strip.delete_prefix('/').delete_suffix('/')
      path = segment.empty? ? "#{APP_PREFIX}#{key}" : "#{APP_PREFIX}#{segment}/#{key}"
      validate_app_path!(path)
      path
    end

    def disk_path(folder, key)
      base = folder.to_s.strip
      base = "/#{base}" unless base.start_with?('/')
      base = base.delete_suffix('/')
      "#{base}/#{key}"
    end

    def validate_app_path!(path)
      return if path.start_with?(APP_PREFIX) && !path.include?('..')

      raise ArgumentError, "invalid app folder path: #{path.inspect}"
    end
  end
end
