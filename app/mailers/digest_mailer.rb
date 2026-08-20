# frozen_string_literal: true

class DigestMailer < ApplicationMailer
  layout false

  def monthly(user, payload)
    @payload = payload
    @recipient = user
    mail(
      to: user.email,
      subject: subject_line
    )
  end

  private

  def subject_line
    from = AdminDigest::Format.date(@payload.period.from)
    to = AdminDigest::Format.date(@payload.period.to)
    "Семейная хроника: дайджест #{from} — #{to}"
  end
end
