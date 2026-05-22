# frozen_string_literal: true

module Api
  module V1
    class PersonBirthdaySerializer
      def initialize(row, request: nil)
        @row = row
        @person = row.person
        @request = request
      end

      def as_json
        {
          id: @person.id,
          chart_external_id: @person.chart_external_id,
          first_name: @person.first_name,
          last_name: @person.last_name,
          avatar_url: avatar_url,
          days_offset: @row.days_offset,
          age: @row.age,
          deceased: @row.deceased
        }
      end

      private

      def avatar_url
        Geneus::BlobPublicPath.url(@person.avatar, request: @request)
      end
    end
  end
end
