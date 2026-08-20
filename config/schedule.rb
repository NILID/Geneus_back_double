# frozen_string_literal: true

# Use: bundle exec whenever --update-crontab
# Preview: bundle exec whenever

set :output, 'log/cron.log'
set :environment, ENV.fetch('RAILS_ENV', 'production')
set :chronic_options, hours24: true

# Hourly while testing delivery. Switch to `every 1.month` (or `:monthly`) later.
every 1.hour do
  rake 'geneus:send_admin_digest'
end
