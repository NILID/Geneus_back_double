# frozen_string_literal: true

module Geneus
  module AppUrls
    module_function

    def frontend_base
      ENV.fetch('FRONTEND_URL', 'http://localhost:3000').chomp('/')
    end

    def backend_base
      explicit = ENV['BACKEND_PUBLIC_URL'].to_s.strip
      return explicit.chomp('/') if explicit.present?

      opts = Rails.application.config.action_mailer.default_url_options || {}
      host = opts[:host].presence || ENV['BACKEND_HOST'].presence
      return frontend_base if host.blank?

      protocol = opts[:protocol].presence || (Rails.env.production? ? 'https' : 'http')
      port = opts[:port]
      base = "#{protocol}://#{host}"
      if port.present? && ![80, 443].include?(port.to_i)
        base += ":#{port}"
      end
      base
    end

    def person_url(person)
      return nil if person.blank?

      key = person.chart_id.presence || person.id
      "#{frontend_base}/person/#{key}"
    end

    def person_facts_url(person)
      return nil if person.blank?

      "#{person_url(person)}/facts"
    end

    def media_url(photo = nil)
      return "#{frontend_base}/media" if photo.blank?

      "#{frontend_base}/media/#{photo.id}"
    end
  end
end
