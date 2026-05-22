class NotificationMailer < ApplicationMailer
  def test_email(email)
    mail(
      to: email,
      subject: 'test',
      template_name: 'test_email',
    )
  end
end
