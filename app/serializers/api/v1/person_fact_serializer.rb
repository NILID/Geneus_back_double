# frozen_string_literal: true

module Api
  module V1
    class PersonFactSerializer
      def initialize(person_fact)
        @person_fact = person_fact
      end

      def as_json
        {
          id: @person_fact.id,
          user_id: @person_fact.user_id,
          author_email: @person_fact.user&.email,
          body: @person_fact.body,
          created_at: @person_fact.created_at.iso8601
        }
      end
    end
  end
end
