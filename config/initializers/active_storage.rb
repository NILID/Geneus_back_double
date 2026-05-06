# frozen_string_literal: true

# Disk/signed blob URLs embed an expiry in the params (see logs: `"exp":"..."`).
# Defaults are short enough that Safari can show broken <img> after JSON is reused from cache
# or the UI stays open longer than the signature lifetime.
Rails.application.config.active_storage.service_urls_expire_in = 7.days
