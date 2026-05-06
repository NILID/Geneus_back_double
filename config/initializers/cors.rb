# Разрешённые Origin для браузерных запросов к API.
# FRONTEND_URL — основной SPA; CORS_ORIGINS — дополнительные через запятую (стейджинг, второй порт).
frontend_base = ENV['FRONTEND_URL'].to_s.chomp('/')
extra_origins = ENV['CORS_ORIGINS'].to_s.split(',').map { |s| s.strip.chomp('/') }.reject(&:blank?)
cors_origins = ([frontend_base] + extra_origins).reject(&:blank?).uniq
cors_origins = ['http://localhost:3000'] if cors_origins.empty?

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins cors_origins
    resource '*',
             headers: :any,
             methods: %i[get post patch put delete options],
             expose: %w[Authorization]
  end
end
