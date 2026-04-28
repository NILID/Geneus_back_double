# frozen_string_literal: true

module Api
  module V1
    class PersonSerializer
      def initialize(person)
        @person = person
      end

      def as_json
        {
          id: @person.id,
          chart_id: @person.chart_id,
          chart_external_id: @person.chart_external_id,
          name: @person.name,
          first_name: @person.first_name,
          last_name: @person.last_name,
          gender: @person.gender,
          bio: @person.bio,
          date_of_birth: @person.date_of_birth&.iso8601,
          date_of_death: @person.date_of_death&.iso8601,
          location_of_birth: @person.location_of_birth,
          location_of_death: @person.location_of_death,
          parents: @person.parents.map { |p| summary(p) },
          partners: @person.partners.distinct.map { |p| summary(p) },
          children: @person.children.map { |p| summary(p) }
        }
      end

      private

      def summary(person)
        {
          id: person.id,
          chart_external_id: person.chart_external_id,
          name: person.name
        }
      end
    end
  end
end
