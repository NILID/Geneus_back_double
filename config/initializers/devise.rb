# frozen_string_literal: true

Devise.setup do |config|
  config.mailer_sender = ENV.fetch('MAILER_SENDER', Rails.application.credentials.mail_email)

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  config.skip_session_storage = [:jwt_auth]

  config.stretches = Rails.env.test? ? 1 : 12

  config.reconfirmable = false

  config.expire_all_remember_me_on_sign_out = true

  config.password_length = 8..128

  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  config.reset_password_within = 6.hours

  config.sign_in_after_reset_password = true

  # ==> Configuration for :invitable
  # Срок действия ссылки приглашения (devise_invitable). 0 = без срока (не рекомендуется).
  invitation_ttl_hours = ENV.fetch('INVITATION_INVITE_FOR_HOURS', '24').to_i
  config.invite_for = invitation_ttl_hours.positive? ? invitation_ttl_hours.hours : 0

  config.navigational_formats = []

  config.jwt do |jwt|
    jwt.secret = if Rails.env.production?
                   Rails.application.credentials.prod[:devise][:jwt_secret_key]
                 else
                   ENV.fetch('DEVISE_JWT_SECRET_KEY') { Rails.application.secret_key_base }
                 end
    jwt.dispatch_requests = [
      ['POST', %r{^/api/v1/auth/login$}i],
      ['PATCH', %r{^/api/v1/auth/invitations$}i]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/api/v1/auth/logout$}i]
    ]
    jwt.expiration_time = 1.week.to_i
  end
end
