# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DigestMailer, type: :mailer do
  it 'renders html and text parts with digest sections' do
    admin = create(:user, :admin, email: "digest-#{SecureRandom.hex(4)}@example.com")
    payload = AdminDigest::Builder.call
    mail = described_class.monthly(admin, payload)

    expect(mail.to).to eq([admin.email])
    expect(mail.subject).to include('Семейная хроника: дайджест')
    expect(mail.html_part.body.decoded).to include('Дайджест обновлений')
    expect(mail.html_part.body.decoded).to include('Дни рождения')
    expect(mail.html_part.body.decoded).not_to include('на ближайший месяц')
    expect(mail.html_part.body.decoded).not_to include('добавлены за месяц')
    expect(mail.text_part.body.decoded).to include('Семейная хроника — дайджест')
    expect(mail.text_part.body.decoded).not_to include('== Дни рождения ==')
  end
end
