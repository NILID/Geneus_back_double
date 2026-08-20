# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminDigest::Sender do
  include ActiveSupport::Testing::TimeHelpers

  it 'sends the digest to every admin and not to other roles' do
    admin_a = create(:user, :admin, email: "a-#{SecureRandom.hex(4)}@example.com")
    admin_b = create(:user, :admin, email: "b-#{SecureRandom.hex(4)}@example.com")
    create(:user, :moderator, email: "m-#{SecureRandom.hex(4)}@example.com")
    create(:user, email: "u-#{SecureRandom.hex(4)}@example.com")

    travel_to Time.zone.parse('2026-08-20 12:00:00') do
      expect { described_class.call }.to change { ActionMailer::Base.deliveries.size }.by(2)
    end

    recipients = ActionMailer::Base.deliveries.flat_map(&:to)
    expect(recipients).to contain_exactly(admin_a.email, admin_b.email)
    expect(ActionMailer::Base.deliveries.last.subject).to include('Семейная хроника: дайджест')
  end
end
