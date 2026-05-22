class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.mail_from
  layout 'mailer'
end
