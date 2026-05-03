# frozen_string_literal: true

module Api
  module V1
    class IdeaSerializer
      def initialize(idea)
        @idea = idea
      end

      def as_json
        {
          id: @idea.id,
          user_id: @idea.user_id,
          author_email: @idea.user&.email,
          body: @idea.body,
          created_at: @idea.created_at.iso8601
        }
      end
    end
  end
end
