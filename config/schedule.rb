# frozen_string_literal: true

# Use: bundle exec whenever --update-crontab
# Preview: bundle exec whenever

set :output, 'log/cron.log'
set :environment, ENV.fetch('RAILS_ENV', 'production')
set :chronic_options, hours24: true

# 1-е число каждого месяца, 09:00 по часовому поясу сервера.
every '0 9 1 * *' do
  rake 'geneus:send_monthly_digest'
end
