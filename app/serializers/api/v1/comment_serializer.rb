# frozen_string_literal: true

module Api
  module V1
    class CommentSerializer
      def initialize(comment)
        @comment = comment
      end

      def as_json
        {
          id: @comment.id,
          user_id: @comment.user_id,
          author_email: @comment.user&.email,
          body: @comment.body,
          created_at: @comment.created_at.iso8601
        }
      end
    end
  end
end
