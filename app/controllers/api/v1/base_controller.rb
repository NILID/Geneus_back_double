# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include Devise::Controllers::Helpers

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      private

      def render_not_found
        render json: { error: 'Not found' }, status: :not_found
      end
    end
  end
end
