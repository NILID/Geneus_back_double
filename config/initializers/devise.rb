# frozen_string_literal: true

Devise.setup do |config|
  config.mailer_sender = ENV.fetch('MAILER_SENDER', 'please-change-me@example.com')

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  config.skip_session_storage = [:jwt_auth]

  config.stretches = Rails.env.test? ? 1 : 12

  config.reconfirmable = false

  config.expire_all_remember_me_on_sign_out = true

  config.password_length = 6..128

  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  config.reset_password_within = 6.hours

  config.sign_in_after_reset_password = true

  config.navigational_formats = []

  config.jwt do |jwt|
    jwt.secret = ENV.fetch('DEVISE_JWT_SECRET_KEY') { Rails.application.secret_key_base }
    jwt.dispatch_requests = [
      ['POST', %r{^/api/v1/auth/login$}i],
      ['POST', %r{^/api/v1/auth/register$}i]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/api/v1/auth/logout$}i]
    ]
    jwt.expiration_time = 1.week.to_i
  end
end
