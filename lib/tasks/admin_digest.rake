# frozen_string_literal: true

namespace :geneus do
  desc 'Send the monthly family digest email to all admins'
  task send_admin_digest: :environment do
    result = AdminDigest::Sender.call
    puts "Admin digest sent to #{result.sent} recipient(s): #{result.recipients.join(', ')}"
  end
end
