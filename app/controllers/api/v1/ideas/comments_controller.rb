# frozen_string_literal: true

module Api
  module V1
    module Ideas
      class CommentsController < BaseController
        before_action :authenticate_user!
        before_action :set_idea

        def index
          comments = @idea.comments.includes(:user).order(created_at: :asc)
          render json: {
            comments: comments.map { |c| Api::V1::CommentSerializer.new(c).as_json }
          }
        end

        def create
          permitted = params.require(:comment).permit(:body)
          comment = @idea.comments.build(user: current_user, body: normalize_field(permitted[:body]))

          unless comment.save
            render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
            return
          end

          render json: {
            comment: Api::V1::CommentSerializer.new(comment).as_json,
            comments_count: @idea.reload.comments_count
          }, status: :created
        end

        private

        def set_idea
          @idea = Idea.find(params[:idea_id])
        end

        def normalize_field(value)
          value.to_s.strip
        end
      end
    end
  end
end
