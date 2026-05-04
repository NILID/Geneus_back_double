# frozen_string_literal: true

module Api
  module V1
    class PersonHomeRowSerializer
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
          updated_at: @person.updated_at.iso8601
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
    end
  end
end
