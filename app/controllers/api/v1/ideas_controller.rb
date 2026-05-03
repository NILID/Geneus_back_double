# frozen_string_literal: true

module Api
  module V1
    class IdeasController < BaseController
      before_action :authenticate_user!

      def index
        ideas = Idea.order(created_at: :desc).includes(:user)
        render json: {
          ideas: ideas.map { |i| Api::V1::IdeaSerializer.new(i).as_json }
        }
      end

      def create
        permitted = params.require(:idea).permit(:body)
        idea = current_user.ideas.build(body: normalize_field(permitted[:body]))

        unless idea.save
          render json: { errors: idea.errors.full_messages }, status: :unprocessable_entity
          return
        end

        render json: {
          idea: Api::V1::IdeaSerializer.new(idea).as_json
        }, status: :created
      end

      private

      def normalize_field(value)
        value.to_s.strip
      end
    end
  end
end
