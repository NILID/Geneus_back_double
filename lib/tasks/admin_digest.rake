# frozen_string_literal: true

namespace :geneus do
  desc 'Send the monthly family digest email to all registered users'
  task send_monthly_digest: :environment do
    result = AdminDigest::Sender.call
    puts "Monthly digest sent to #{result.sent} recipient(s): #{result.recipients.join(', ')}"
  end

  task send_admin_digest: :send_monthly_digest
end
