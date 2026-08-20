# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminDigest::Sender do
  include ActiveSupport::Testing::TimeHelpers

  it 'sends the digest to every registered user' do
    admin = create(:user, :admin, email: "a-#{SecureRandom.hex(4)}@example.com")
    moderator = create(:user, :moderator, email: "m-#{SecureRandom.hex(4)}@example.com")
    member = create(:user, email: "u-#{SecureRandom.hex(4)}@example.com")
    pending = create(:user, email: "pending-#{SecureRandom.hex(4)}@example.com")
    pending.update_columns(
      invitation_token: SecureRandom.hex(16),
      invitation_sent_at: Time.current,
      invitation_accepted_at: nil
    )

    travel_to Time.zone.parse('2026-08-20 12:00:00') do
      expect { described_class.call }.to change { ActionMailer::Base.deliveries.size }.by(3)
    end

    recipients = ActionMailer::Base.deliveries.flat_map(&:to)
    expect(recipients).to contain_exactly(admin.email, moderator.email, member.email)
    expect(recipients).not_to include(pending.email)
    expect(ActionMailer::Base.deliveries.last.subject).to include('Семейная хроника: дайджест')
  end

  it 'sends only to the given recipients when provided' do
    admin = create(:user, :admin, email: "only-#{SecureRandom.hex(4)}@example.com")
    create(:user, :admin, email: "other-#{SecureRandom.hex(4)}@example.com")

    expect { described_class.call(recipients: [admin]) }
      .to change { ActionMailer::Base.deliveries.size }.by(1)

    expect(ActionMailer::Base.deliveries.last.to).to eq([admin.email])
  end
end
