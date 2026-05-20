# frozen_string_literal: true

module Api
  module V1
    class PersonMapLocationSerializer
      def self.collection(people, request: nil)
        people.map { |p| new(p, request: request).as_json }
      end

      def initialize(person, request: nil)
        @person = person
        @request = request
      end

      def as_json
        {
          id: @person.id,
          chart_external_id: @person.chart_external_id,
          first_name: @person.first_name,
          last_name: @person.last_name,
          avatar_url: avatar_url,
          location_of_birth: @person.location_of_birth,
          location_of_death: @person.location_of_death,
          birth_latitude: decimal_to_json(@person.birth_latitude),
          birth_longitude: decimal_to_json(@person.birth_longitude),
          death_latitude: decimal_to_json(@person.death_latitude),
          death_longitude: decimal_to_json(@person.death_longitude)
        }
      end

      private

      def avatar_url
        return nil if @request.blank? || !@person.avatar.attached?

        @request.base_url + Rails.application.routes.url_helpers.rails_blob_path(
          @person.avatar,
          only_path: true
        )
      end

      def decimal_to_json(value)
        return nil if value.nil?

        value.to_f
      end
    end
  end
end
