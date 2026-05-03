# frozen_string_literal: true

module Api
  module V1
    class PersonMapLocationSerializer
      def self.collection(people)
        people.map { |p| new(p).as_json }
      end

      def initialize(person)
        @person = person
      end

      def as_json
        {
          id: @person.id,
          chart_external_id: @person.chart_external_id,
          first_name: @person.first_name,
          last_name: @person.last_name,
          location_of_birth: @person.location_of_birth,
          location_of_death: @person.location_of_death,
          birth_latitude: decimal_to_json(@person.birth_latitude),
          birth_longitude: decimal_to_json(@person.birth_longitude),
          death_latitude: decimal_to_json(@person.death_latitude),
          death_longitude: decimal_to_json(@person.death_longitude)
        }
      end

      private

      def decimal_to_json(value)
        return nil if value.nil?

        value.to_f
      end
    end
  end
end
